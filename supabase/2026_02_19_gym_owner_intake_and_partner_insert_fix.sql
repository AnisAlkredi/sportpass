-- ==============================================================================
-- SportPass Patch: Gym Owner Intake Details + Owner Partner Insert Fix
-- Date: 2026-02-19
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1) Extend gym owner request with business details
-- ------------------------------------------------------------------------------
ALTER TABLE public.gym_owner_requests
    ADD COLUMN IF NOT EXISTS gym_name TEXT,
    ADD COLUMN IF NOT EXISTS gym_city TEXT,
    ADD COLUMN IF NOT EXISTS gym_address TEXT,
    ADD COLUMN IF NOT EXISTS branches_count INT DEFAULT 1 CHECK (branches_count >= 1),
    ADD COLUMN IF NOT EXISTS gym_category TEXT,
    ADD COLUMN IF NOT EXISTS business_description TEXT;

-- ------------------------------------------------------------------------------
-- 2) RPC for owner to save request details during onboarding
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_gym_owner_request_details(
    p_gym_name TEXT,
    p_gym_city TEXT,
    p_gym_address TEXT,
    p_branches_count INT DEFAULT 1,
    p_gym_category TEXT DEFAULT 'gym',
    p_business_description TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_branch_count INT := GREATEST(COALESCE(p_branches_count, 1), 1);
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF NOT (
        public.has_role('gym_owner_pending')
        OR public.has_role('gym_owner')
        OR public.is_admin()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: gym owner role required';
    END IF;

    INSERT INTO public.gym_owner_requests (
        user_id,
        status,
        gym_name,
        gym_city,
        gym_address,
        branches_count,
        gym_category,
        business_description
    ) VALUES (
        v_user_id,
        'pending',
        NULLIF(TRIM(p_gym_name), ''),
        NULLIF(TRIM(p_gym_city), ''),
        NULLIF(TRIM(p_gym_address), ''),
        v_branch_count,
        NULLIF(TRIM(p_gym_category), ''),
        NULLIF(TRIM(p_business_description), '')
    )
    ON CONFLICT (user_id) DO UPDATE
    SET status = 'pending',
        gym_name = EXCLUDED.gym_name,
        gym_city = EXCLUDED.gym_city,
        gym_address = EXCLUDED.gym_address,
        branches_count = EXCLUDED.branches_count,
        gym_category = EXCLUDED.gym_category,
        business_description = EXCLUDED.business_description,
        admin_notes = NULL,
        reviewed_by = NULL,
        updated_at = NOW();

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم حفظ تفاصيل طلب صاحب النادي'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_gym_owner_request_details(
    TEXT, TEXT, TEXT, INT, TEXT, TEXT
) TO authenticated;

-- ------------------------------------------------------------------------------
-- 3) Review request: promote role + auto-create owner partner skeleton
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
    v_partner_id UUID;
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

    IF p_approve THEN
        SELECT id
        INTO v_partner_id
        FROM public.partners
        WHERE owner_id = v_request.user_id
        ORDER BY created_at ASC
        LIMIT 1;

        -- Create a pending partner skeleton from request details if owner has no partner yet.
        IF v_partner_id IS NULL THEN
            INSERT INTO public.partners (
                owner_id,
                name,
                description,
                category,
                is_active,
                metadata
            ) VALUES (
                v_request.user_id,
                COALESCE(NULLIF(TRIM(v_request.gym_name), ''), 'نادي جديد'),
                NULLIF(TRIM(v_request.business_description), ''),
                COALESCE(NULLIF(TRIM(v_request.gym_category), ''), 'gym'),
                false,
                jsonb_strip_nulls(jsonb_build_object(
                    'seeded_from_request', true,
                    'request_id', v_request.id,
                    'city', NULLIF(TRIM(v_request.gym_city), ''),
                    'address', NULLIF(TRIM(v_request.gym_address), ''),
                    'branches_count', COALESCE(v_request.branches_count, 1)
                ))
            )
            RETURNING id INTO v_partner_id;

            INSERT INTO public.gym_wallets (partner_id, balance)
            VALUES (v_partner_id, 0)
            ON CONFLICT (partner_id) DO NOTHING;
        END IF;

        RETURN jsonb_build_object(
            'success', true,
            'message', 'تمت الموافقة على طلب صاحب النادي',
            'partner_id', v_partner_id
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم رفض طلب صاحب النادي'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 4) RLS: owner must be able to INSERT partner row for self
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "partners_owner_insert" ON public.partners;
CREATE POLICY "partners_owner_insert" ON public.partners
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

DO $$
BEGIN
  RAISE NOTICE 'Patch applied: gym owner intake + partner owner insert fix';
END $$;

