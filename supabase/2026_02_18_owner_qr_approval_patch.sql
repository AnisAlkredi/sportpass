-- ==============================================================================
-- SportPass Patch: Owner QR Approval Flow + Topup Robustness
-- Date: 2026-02-18
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1) Fix approve_topup() for users missing wallet rows
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_topup(
    p_request_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_request RECORD;
    v_wallet RECORD;
    v_new_balance DECIMAL(15, 2);
    v_idem_key TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    SELECT * INTO v_request
    FROM public.topup_requests
    WHERE id = p_request_id AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'الطلب غير موجود أو تمت معالجته'
        );
    END IF;

    -- Ensure wallet exists even for legacy users.
    INSERT INTO public.wallets (user_id, balance)
    VALUES (v_request.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE user_id = v_request.user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet row not found for user %', v_request.user_id;
    END IF;

    v_idem_key := 'topup:' || p_request_id;

    IF EXISTS (SELECT 1 FROM public.wallet_ledger WHERE idempotency_key = v_idem_key) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'تم معالجة هذا الطلب مسبقاً'
        );
    END IF;

    UPDATE public.topup_requests
    SET status = 'approved',
        reviewed_by = v_admin_id,
        updated_at = NOW()
    WHERE id = p_request_id;

    UPDATE public.wallets
    SET balance = balance + v_request.amount,
        total_topup = total_topup + v_request.amount,
        updated_at = NOW()
    WHERE user_id = v_request.user_id
    RETURNING balance INTO v_new_balance;

    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        idempotency_key, metadata
    ) VALUES (
        'user', v_request.user_id, v_request.amount, 'topup',
        'شحن رصيد (موافقة إدارية)',
        p_request_id, 'topup', v_wallet.balance, v_new_balance,
        v_idem_key,
        jsonb_build_object('admin_id', v_admin_id, 'notes', v_request.notes)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم الموافقة على الشحن',
        'amount', v_request.amount,
        'new_balance', v_new_balance
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 2) Restrict topup requests to athlete role only
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "topup_user_insert" ON public.topup_requests;
CREATE POLICY "topup_user_insert" ON public.topup_requests
    FOR INSERT
    WITH CHECK (auth.uid() = user_id AND public.has_role('athlete'));

-- ------------------------------------------------------------------------------
-- 3) QR regeneration requests table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.qr_token_regeneration_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_location_id UUID NOT NULL REFERENCES public.partner_locations(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    reviewed_by UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.qr_token_regeneration_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "qr_req_owner_read" ON public.qr_token_regeneration_requests;
CREATE POLICY "qr_req_owner_read" ON public.qr_token_regeneration_requests
    FOR SELECT USING (
        requested_by = auth.uid()
        OR EXISTS (
            SELECT 1
            FROM public.partner_locations pl
            JOIN public.partners p ON p.id = pl.partner_id
            WHERE pl.id = partner_location_id
              AND p.owner_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "qr_req_owner_insert" ON public.qr_token_regeneration_requests;
CREATE POLICY "qr_req_owner_insert" ON public.qr_token_regeneration_requests
    FOR INSERT WITH CHECK (
        requested_by = auth.uid()
        AND EXISTS (
            SELECT 1
            FROM public.partner_locations pl
            JOIN public.partners p ON p.id = pl.partner_id
            WHERE pl.id = partner_location_id
              AND p.owner_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "qr_req_admin_all" ON public.qr_token_regeneration_requests;
CREATE POLICY "qr_req_admin_all" ON public.qr_token_regeneration_requests
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ------------------------------------------------------------------------------
-- 4) Make generate_qr_token() admin-only
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_qr_token(
    p_location_id UUID
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    v_token := 'SP-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 12));

    UPDATE public.qr_tokens
    SET is_active = false
    WHERE partner_location_id = p_location_id;

    INSERT INTO public.qr_tokens (partner_location_id, token, type)
    VALUES (p_location_id, v_token, 'static');

    RETURN v_token;
END;
$$;

-- ------------------------------------------------------------------------------
-- 5) Owner request + admin review RPCs
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.request_qr_token_regeneration(
    p_location_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_requester UUID := auth.uid();
    v_location_owner UUID;
    v_pending_id UUID;
BEGIN
    SELECT p.owner_id
    INTO v_location_owner
    FROM public.partner_locations pl
    JOIN public.partners p ON p.id = pl.partner_id
    WHERE pl.id = p_location_id;

    IF v_location_owner IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Location not found');
    END IF;

    IF v_location_owner != v_requester THEN
        RAISE EXCEPTION 'Unauthorized: location owner required';
    END IF;

    SELECT id INTO v_pending_id
    FROM public.qr_token_regeneration_requests
    WHERE partner_location_id = p_location_id
      AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_pending_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'يوجد طلب تجديد معلق بالفعل'
        );
    END IF;

    INSERT INTO public.qr_token_regeneration_requests (
        partner_location_id,
        requested_by,
        status
    ) VALUES (
        p_location_id,
        v_requester,
        'pending'
    ) RETURNING id INTO v_pending_id;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', v_pending_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.review_qr_token_regeneration(
    p_request_id UUID,
    p_approve BOOLEAN,
    p_admin_notes TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_req RECORD;
    v_token TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    SELECT *
    INTO v_req
    FROM public.qr_token_regeneration_requests
    WHERE id = p_request_id
      AND status = 'pending'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'الطلب غير موجود أو تمت مراجعته'
        );
    END IF;

    UPDATE public.qr_token_regeneration_requests
    SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
        admin_notes = p_admin_notes,
        reviewed_by = v_admin_id,
        updated_at = NOW()
    WHERE id = p_request_id;

    IF p_approve THEN
        v_token := public.generate_qr_token(v_req.partner_location_id);
        RETURN jsonb_build_object(
            'success', true,
            'message', 'تمت الموافقة وتوليد QR جديد',
            'token', v_token,
            'location_id', v_req.partner_location_id
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم رفض طلب التجديد'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 6) Ensure location activation auto-creates first QR token
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_location_active(
    p_location_id UUID,
    p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
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

    IF p_is_active THEN
        -- Ensure at least one active token after activation.
        IF NOT EXISTS (
            SELECT 1
            FROM public.qr_tokens
            WHERE partner_location_id = p_location_id
              AND is_active = true
        ) THEN
            v_token := public.generate_qr_token(p_location_id);
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'location_id', p_location_id,
        'is_active', p_is_active,
        'generated_token', COALESCE(v_token, '')
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 7) Grants
-- ------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.approve_topup(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_qr_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_qr_token_regeneration(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_qr_token_regeneration(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_location_active(UUID, BOOLEAN) TO authenticated;

DO $$
BEGIN
  RAISE NOTICE 'Patch applied: owner QR approval flow + topup robustness';
END $$;
