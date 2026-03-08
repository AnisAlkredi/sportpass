-- ==============================================================================
-- SportPass Patch: Pricing Model Shift (Gym Pays Commission)
-- Date: 2026-03-04
--
-- New model:
-- - Gym enters final entry price once.
-- - Athlete pays exactly this price.
-- - Platform fee (20%) is deducted from gym side.
--
-- This patch converts existing partner_locations.base_price from old semantics
-- (gym net share) to new semantics (final athlete entry price), then redefines
-- perform_checkin accordingly.
--
-- IMPORTANT:
-- Run this ONCE only for projects that used the old model.
-- ==============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.system_migrations (
    migration_key TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

DO $$
DECLARE
    v_key TEXT := 'pricing_model_gym_pays_fee_2026_03_04';
    v_exists BOOLEAN := false;
    v_rows BIGINT := 0;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.system_migrations WHERE migration_key = v_key
    ) INTO v_exists;

    IF v_exists THEN
        RAISE NOTICE 'Pricing model shift skipped: marker already exists';
        RETURN;
    END IF;

    -- Old model: base_price stored gym net share (80%).
    -- New model: base_price stores athlete final entry price (100%).
    -- Preserve previous athlete payable amount pattern using old formula.
    UPDATE public.partner_locations
    SET base_price = CEIL((base_price / 0.80) / 5.0) * 5.0,
        updated_at = NOW()
    WHERE base_price > 0;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    INSERT INTO public.system_migrations (migration_key, metadata)
    VALUES (
        v_key,
        jsonb_build_object(
            'converted_locations', v_rows,
            'model', 'gym_pays_commission',
            'commission_rate', 0.20
        )
    );

    RAISE NOTICE 'Pricing model shift applied: converted partner_locations rows=%', v_rows;
END $$;

CREATE OR REPLACE FUNCTION public.perform_checkin(
    p_qr_token TEXT,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_device_hash TEXT DEFAULT NULL,
    p_idempotency_key TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_location RECORD;
    v_partner RECORD;
    v_wallet RECORD;
    v_gym_wallet RECORD;
    v_platform_wallet RECORD;
    v_distance DOUBLE PRECISION;
    v_base_price DECIMAL(12, 2);
    v_user_price DECIMAL(12, 2);
    v_platform_fee DECIMAL(12, 2);
    v_checkin_id UUID;
    v_idem_key TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT pl.* INTO v_location
    FROM public.qr_tokens qt
    JOIN public.partner_locations pl ON qt.partner_location_id = pl.id
    WHERE qt.token = p_qr_token
      AND qt.is_active = true
      AND (qt.expires_at IS NULL OR qt.expires_at > NOW())
      AND pl.is_active = true
    ORDER BY qt.created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'QR_INVALID',
            'message', 'رمز QR غير صالح أو منتهي الصلاحية'
        );
    END IF;

    SELECT * INTO v_partner
    FROM public.partners
    WHERE id = v_location.partner_id;

    IF NOT v_partner.is_active THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'PARTNER_CLOSED',
            'message', 'هذا النادي غير نشط'
        );
    END IF;

    v_distance := public.haversine_distance(p_lat, p_lng, v_location.lat, v_location.lng);

    IF v_distance > v_location.radius_m THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'GEO_FAIL',
            'message', 'أنت بعيد عن الموقع (' || ROUND(v_distance::numeric, 0) || 'م)',
            'distance', ROUND(v_distance::numeric, 2),
            'required', v_location.radius_m
        );
    END IF;

    -- Gym enters final price once; athlete pays this exact value.
    -- Platform fee is deducted from gym side.
    v_user_price := v_location.base_price;
    v_platform_fee := ROUND(v_user_price * 0.20, 0);
    v_base_price := v_user_price - v_platform_fee;

    INSERT INTO public.wallets (user_id, balance)
    VALUES (v_user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.gym_wallets (partner_id, balance)
    VALUES (v_partner.id, 0)
    ON CONFLICT (partner_id) DO NOTHING;

    INSERT INTO public.platform_wallet (id, balance, total_earned)
    VALUES ('00000000-0000-0000-0000-000000000001', 0, 0)
    ON CONFLICT (id) DO NOTHING;

    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet row not found for user %', v_user_id;
    END IF;

    IF v_wallet.balance < v_user_price THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'LOW_BALANCE',
            'message', 'رصيدك غير كافٍ. الكلفة: ' || v_user_price || ' ل.س جديدة',
            'required', v_user_price,
            'balance', v_wallet.balance
        );
    END IF;

    SELECT * INTO v_gym_wallet
    FROM public.gym_wallets
    WHERE partner_id = v_partner.id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gym wallet row not found for partner %', v_partner.id;
    END IF;

    SELECT * INTO v_platform_wallet
    FROM public.platform_wallet
    WHERE id = '00000000-0000-0000-0000-000000000001'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Platform wallet singleton row not found';
    END IF;

    INSERT INTO public.checkins (
        user_id, partner_location_id, base_price, platform_fee, final_price,
        status, geo_lat, geo_lng, device_hash, metadata
    ) VALUES (
        v_user_id, v_location.id, v_base_price, v_platform_fee, v_user_price,
        'approved', p_lat, p_lng, p_device_hash,
        jsonb_build_object('qr_token', p_qr_token, 'distance_m', ROUND(v_distance::numeric, 2))
    )
    RETURNING id INTO v_checkin_id;

    UPDATE public.wallets
    SET balance = balance - v_user_price,
        total_spent = total_spent + v_user_price,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    UPDATE public.gym_wallets
    SET balance = balance + v_base_price,
        total_earned = total_earned + v_base_price,
        updated_at = NOW()
    WHERE partner_id = v_partner.id;

    UPDATE public.platform_wallet
    SET balance = balance + v_platform_fee,
        total_earned = total_earned + v_platform_fee,
        updated_at = NOW()
    WHERE id = '00000000-0000-0000-0000-000000000001';

    v_idem_key := COALESCE(NULLIF(TRIM(p_idempotency_key), ''),
        'checkin:' || v_user_id || ':' || v_location.id || ':' || date_trunc('minute', NOW()));

    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        idempotency_key, metadata
    ) VALUES (
        'user', v_user_id, -v_user_price, 'checkin_debit',
        'دخول نادي: ' || v_location.name,
        v_checkin_id, 'checkin', v_wallet.balance, v_wallet.balance - v_user_price,
        v_idem_key,
        jsonb_build_object('partner_name', v_partner.name, 'location_name', v_location.name)
    );

    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        metadata
    ) VALUES (
        'gym', v_partner.id, v_base_price, 'checkin_credit_gym',
        'زيارة: ' || v_location.name,
        v_checkin_id, 'checkin', v_gym_wallet.balance, v_gym_wallet.balance + v_base_price,
        jsonb_build_object('user_id', v_user_id, 'location_id', v_location.id)
    );

    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        metadata
    ) VALUES (
        'platform', NULL, v_platform_fee, 'checkin_credit_platform',
        'عمولة: ' || v_partner.name,
        v_checkin_id, 'checkin', v_platform_wallet.balance, v_platform_wallet.balance + v_platform_fee,
        jsonb_build_object('partner_id', v_partner.id, 'location_id', v_location.id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تسجيل الدخول بنجاح!',
        'checkin_id', v_checkin_id,
        'gym_name', v_partner.name,
        'location_name', v_location.name,
        'price_paid', v_user_price,
        'base_price', v_base_price,
        'platform_fee', v_platform_fee,
        'new_balance', v_wallet.balance - v_user_price
    );
END;
$$;

COMMIT;

DO $$
BEGIN
  RAISE NOTICE 'Patch applied: pricing model shifted to gym-pays-commission';
END $$;
