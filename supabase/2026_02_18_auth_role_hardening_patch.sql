-- ==============================================================================
-- SportPass Patch: Auth Role Hardening + Gym Owner Pending Approval
-- Date: 2026-02-18
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1) Add pending owner role to enum
-- ------------------------------------------------------------------------------
ALTER TYPE public.user_role
ADD VALUE IF NOT EXISTS 'gym_owner_pending';

-- ------------------------------------------------------------------------------
-- 2) Gym owner requests queue
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.gym_owner_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
    notes TEXT,
    admin_notes TEXT,
    reviewed_by UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.gym_owner_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "gym_owner_requests_owner_read" ON public.gym_owner_requests;
CREATE POLICY "gym_owner_requests_owner_read" ON public.gym_owner_requests
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "gym_owner_requests_owner_insert" ON public.gym_owner_requests;
CREATE POLICY "gym_owner_requests_owner_insert" ON public.gym_owner_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "gym_owner_requests_admin_all" ON public.gym_owner_requests;
CREATE POLICY "gym_owner_requests_admin_all" ON public.gym_owner_requests
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP TRIGGER IF EXISTS update_gym_owner_requests_updated_at ON public.gym_owner_requests;
CREATE TRIGGER update_gym_owner_requests_updated_at
    BEFORE UPDATE ON public.gym_owner_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ------------------------------------------------------------------------------
-- 3) Keep profile role/status immutable from direct user updates
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "profiles_user_update" ON public.profiles;
CREATE POLICY "profiles_user_update" ON public.profiles
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Trusted internal role updates (RPC flow).
    IF current_setting('sportpass.allow_role_update', true) = '1' THEN
        RETURN NEW;
    END IF;

    -- Service/admin writes remain allowed.
    IF auth.role() = 'service_role' OR public.is_admin() THEN
        RETURN NEW;
    END IF;

    -- Block direct role/status escalation by regular users.
    IF auth.uid() = OLD.user_id THEN
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'Unauthorized: role change is not allowed';
        END IF;
        IF NEW.status IS DISTINCT FROM OLD.status THEN
            RAISE EXCEPTION 'Unauthorized: status change is not allowed';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_profiles_sensitive_fields ON public.profiles;
CREATE TRIGGER protect_profiles_sensitive_fields
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.protect_profile_sensitive_fields();

-- ------------------------------------------------------------------------------
-- 4) Prevent role injection on signup metadata
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, phone, name, role, metadata)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'phone', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'name', 'مستخدم جديد'),
        'athlete',
        jsonb_build_object('role_selected', false)
    )
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.wallets (user_id, balance)
    VALUES (NEW.id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 5) Role selection (first login) RPC
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_role_selection(
    p_name TEXT,
    p_selected_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_clean_name TEXT := NULLIF(TRIM(p_name), '');
    v_target_role public.user_role;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_selected_role NOT IN ('athlete', 'gym_owner') THEN
        RAISE EXCEPTION 'Invalid role selection';
    END IF;

    -- Admin role is never selected from client.
    IF public.is_admin() THEN
        RETURN jsonb_build_object('success', true, 'role', 'admin');
    END IF;

    v_target_role := CASE
        WHEN p_selected_role = 'gym_owner' THEN 'gym_owner_pending'::public.user_role
        ELSE 'athlete'::public.user_role
    END;

    PERFORM set_config('sportpass.allow_role_update', '1', true);

    UPDATE public.profiles
    SET name = COALESCE(v_clean_name, name),
        role = v_target_role,
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('role_selected', true),
        updated_at = NOW()
    WHERE user_id = v_user_id;

    IF v_target_role = 'gym_owner_pending' THEN
        INSERT INTO public.gym_owner_requests (user_id, status)
        VALUES (v_user_id, 'pending')
        ON CONFLICT (user_id) DO UPDATE
        SET status = 'pending',
            admin_notes = NULL,
            reviewed_by = NULL,
            updated_at = NOW();
    ELSE
        UPDATE public.gym_owner_requests
        SET status = 'rejected',
            admin_notes = 'Switched to athlete by user',
            reviewed_by = NULL,
            updated_at = NOW()
        WHERE user_id = v_user_id
          AND status = 'pending';
    END IF;

    PERFORM set_config('sportpass.allow_role_update', '0', true);

    RETURN jsonb_build_object(
        'success', true,
        'role', v_target_role::text
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 6) Admin review for pending gym owners
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.review_gym_owner_request(
    p_request_id UUID,
    p_approve BOOLEAN,
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_request RECORD;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    SELECT *
    INTO v_request
    FROM public.gym_owner_requests
    WHERE id = p_request_id
      AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'الطلب غير موجود أو تمت مراجعته'
        );
    END IF;

    UPDATE public.gym_owner_requests
    SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
        admin_notes = p_admin_notes,
        reviewed_by = v_admin_id,
        updated_at = NOW()
    WHERE id = p_request_id;

    PERFORM set_config('sportpass.allow_role_update', '1', true);

    UPDATE public.profiles
    SET role = CASE
            WHEN p_approve THEN 'gym_owner'::public.user_role
            ELSE 'athlete'::public.user_role
        END,
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('role_selected', true),
        updated_at = NOW()
    WHERE user_id = v_request.user_id;

    PERFORM set_config('sportpass.allow_role_update', '0', true);

    RETURN jsonb_build_object(
        'success', true,
        'message', CASE
            WHEN p_approve THEN 'تمت الموافقة على طلب صاحب النادي'
            ELSE 'تم رفض طلب صاحب النادي'
        END
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 7) Keep top-up write path athlete-only
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "topup_user_insert" ON public.topup_requests;
CREATE POLICY "topup_user_insert" ON public.topup_requests
    FOR INSERT
    WITH CHECK (auth.uid() = user_id AND public.has_role('athlete'));

-- ------------------------------------------------------------------------------
-- 8) Grants
-- ------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.submit_role_selection(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_gym_owner_request(UUID, BOOLEAN, TEXT) TO authenticated;

-- ------------------------------------------------------------------------------
-- 9) Read-policy hardening (map + QR exposure)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "partners_public_read" ON public.partners;
CREATE POLICY "partners_public_read" ON public.partners
    FOR SELECT USING (
        is_active = true
        OR owner_id = auth.uid()
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "partners_owner_manage" ON public.partners;
DROP POLICY IF EXISTS "partners_owner_read" ON public.partners;
CREATE POLICY "partners_owner_read" ON public.partners
    FOR SELECT USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "partners_owner_update" ON public.partners;
CREATE POLICY "partners_owner_update" ON public.partners
    FOR UPDATE USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "locations_public_read" ON public.partner_locations;
CREATE POLICY "locations_public_read" ON public.partner_locations
    FOR SELECT USING (
        (is_active = true AND EXISTS (
            SELECT 1
            FROM public.partners p
            WHERE p.id = partner_id
              AND p.is_active = true
        ))
        OR EXISTS (
            SELECT 1
            FROM public.partners p
            WHERE p.id = partner_id
              AND p.owner_id = auth.uid()
        )
        OR public.is_admin()
    );

DROP POLICY IF EXISTS "qr_tokens_public_read" ON public.qr_tokens;

DO $$
BEGIN
  RAISE NOTICE 'Patch applied: auth role hardening + gym owner pending approval';
END $$;
