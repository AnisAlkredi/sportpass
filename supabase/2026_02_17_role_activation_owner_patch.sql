-- ==============================================================================
-- SportPass Patch: Admin Activation + Gym Owner Linking + RLS Consistency
-- Date: 2026-02-17
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1) Admin-safe activation RPCs (avoid client-side toggle inconsistencies)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_partner_active(
    p_partner_id UUID,
    p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    UPDATE public.partners
    SET is_active = p_is_active,
        updated_at = NOW()
    WHERE id = p_partner_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Partner not found'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'partner_id', p_partner_id,
        'is_active', p_is_active
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.set_location_active(
    p_location_id UUID,
    p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    UPDATE public.partner_locations
    SET is_active = p_is_active,
        updated_at = NOW()
    WHERE id = p_location_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Location not found'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'location_id', p_location_id,
        'is_active', p_is_active
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 2) Admin helper: assign gym owner by phone and ensure wallet row exists
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_gym_owner_by_phone(
    p_phone TEXT,
    p_partner_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    SELECT user_id
    INTO v_user_id
    FROM public.profiles
    WHERE phone = TRIM(p_phone)
    LIMIT 1;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User not found for provided phone'
        );
    END IF;

    UPDATE public.profiles
    SET role = 'gym_owner'
    WHERE user_id = v_user_id;

    UPDATE public.partners
    SET owner_id = v_user_id,
        updated_at = NOW()
    WHERE id = p_partner_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Partner not found'
        );
    END IF;

    INSERT INTO public.gym_wallets (partner_id, balance)
    VALUES (p_partner_id, 0)
    ON CONFLICT (partner_id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'partner_id', p_partner_id
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3) RLS consistency: explicit WITH CHECK for owner/admin write policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "partners_owner_manage" ON public.partners;
CREATE POLICY "partners_owner_manage" ON public.partners
    FOR ALL USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "partners_admin_all" ON public.partners;
CREATE POLICY "partners_admin_all" ON public.partners
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "locations_owner_manage" ON public.partner_locations;
CREATE POLICY "locations_owner_manage" ON public.partner_locations
    FOR ALL USING (
        EXISTS (
            SELECT 1
            FROM public.partners p
            WHERE p.id = partner_id
              AND p.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.partners p
            WHERE p.id = partner_id
              AND p.owner_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "locations_admin_all" ON public.partner_locations;
CREATE POLICY "locations_admin_all" ON public.partner_locations
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "qr_tokens_owner_manage" ON public.qr_tokens;
CREATE POLICY "qr_tokens_owner_manage" ON public.qr_tokens
    FOR ALL USING (
        EXISTS (
            SELECT 1
            FROM public.partner_locations pl
            JOIN public.partners p ON p.id = pl.partner_id
            WHERE pl.id = partner_location_id
              AND p.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.partner_locations pl
            JOIN public.partners p ON p.id = pl.partner_id
            WHERE pl.id = partner_location_id
              AND p.owner_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "qr_tokens_admin_all" ON public.qr_tokens;
CREATE POLICY "qr_tokens_admin_all" ON public.qr_tokens
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ------------------------------------------------------------------------------
-- 4) Execute grants for authenticated clients
-- ------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.set_partner_active(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_location_active(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_gym_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_gym_owner_by_phone(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_qr_token(UUID) TO authenticated;

DO $$
BEGIN
  RAISE NOTICE 'SportPass patch applied: activation + owner linking + RLS consistency';
END $$;
