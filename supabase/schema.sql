-- ==============================================================================
-- SPORTPASS V1 — PRODUCTION SCHEMA (GREENFIELD)
-- ==============================================================================
-- Generated from: SPORTPASS_ARCHITECTURE_FREEZE_V1
-- Date: 2026-02-16
-- Target: Fresh Supabase PostgreSQL database
-- Rules: Wallet-only model, 3-wallet system, immutable ledger, idempotent check-ins
-- ==============================================================================

-- ==============================================================================
-- SECTION A: EXTENSIONS & ENUMS
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search optimization

-- Role definitions per Freeze V1 Section 2
CREATE TYPE public.user_role AS ENUM ('athlete', 'gym_owner', 'admin');

-- Ledger entry types per Freeze V1 Section 4.2
CREATE TYPE public.ledger_entry_type AS ENUM (
  'topup',                    -- User wallet credit (admin approved)
  'checkin_debit',            -- User wallet debit (gym visit)
  'checkin_credit_gym',       -- Gym wallet credit (80% share)
  'checkin_credit_platform',  -- Platform wallet credit (20% share)
  'refund',                   -- User wallet credit (reversal)
  'refund_debit_gym',         -- Gym wallet debit (reversal)
  'refund_debit_platform',    -- Platform wallet debit (reversal)
  'adjustment',               -- Admin manual correction
  'settlement',               -- Gym wallet debit (payout)
  'bonus'                     -- Promotional credit
);

-- Wallet type discriminator per Freeze V1 Section 4.3
CREATE TYPE public.wallet_type AS ENUM ('user', 'gym', 'platform');

-- Check-in status
CREATE TYPE public.checkin_status AS ENUM ('approved', 'rejected');

-- Top-up request status
CREATE TYPE public.topup_status AS ENUM ('pending', 'approved', 'rejected');

-- Settlement status
CREATE TYPE public.settlement_status AS ENUM ('pending', 'paid');

-- QR token type
CREATE TYPE public.qr_type AS ENUM ('static', 'rotating');

-- Account status
CREATE TYPE public.account_status AS ENUM ('active', 'frozen');

-- ==============================================================================
-- SECTION B: TABLES
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- B1. PROFILES (Extended user info linked to auth.users)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT,
    name TEXT NOT NULL DEFAULT 'مستخدم جديد',
    role public.user_role NOT NULL DEFAULT 'athlete',
    status public.account_status NOT NULL DEFAULT 'active',
    avatar_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'User profiles linked to Supabase Auth';
COMMENT ON COLUMN public.profiles.role IS 'athlete | gym_owner | admin';
COMMENT ON COLUMN public.profiles.status IS 'active | frozen (frozen users cannot check in or top up)';

-- -----------------------------------------------------------------------------
-- B2. WALLETS (User wallets — 1:1 with user)
-- -----------------------------------------------------------------------------
CREATE TABLE public.wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_topup DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_spent DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'SYP',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.wallets IS 'User wallets holding real money (cash deposited)';
COMMENT ON COLUMN public.wallets.balance IS 'Current spendable balance';
COMMENT ON COLUMN public.wallets.total_topup IS 'Lifetime top-up amount (audit field)';
COMMENT ON COLUMN public.wallets.total_spent IS 'Lifetime spend amount (audit field)';

-- -----------------------------------------------------------------------------
-- B3. GYM_WALLETS (Gym wallets — 1:1 with partner)
-- -----------------------------------------------------------------------------
CREATE TABLE public.gym_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID NOT NULL UNIQUE, -- FK added after partners table
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_earned DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_settled DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'SYP',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.gym_wallets IS 'Gym wallets holding ledger credits (80% share accumulator)';
COMMENT ON COLUMN public.gym_wallets.balance IS 'Unsettled earnings awaiting admin payout';
COMMENT ON COLUMN public.gym_wallets.total_earned IS 'Lifetime earnings from check-ins';
COMMENT ON COLUMN public.gym_wallets.total_settled IS 'Lifetime settled amount paid out';

-- -----------------------------------------------------------------------------
-- B4. PLATFORM_WALLET (Singleton wallet for platform commission)
-- -----------------------------------------------------------------------------
CREATE TABLE public.platform_wallet (
    id UUID PRIMARY KEY DEFAULT '00000000-0000-0000-0000-000000000001', -- Fixed singleton ID
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_earned DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'SYP',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT only_one_platform_wallet CHECK (id = '00000000-0000-0000-0000-000000000001')
);

COMMENT ON TABLE public.platform_wallet IS 'Singleton wallet holding platform commission (20% share)';

-- Insert the singleton platform wallet
INSERT INTO public.platform_wallet (id) VALUES ('00000000-0000-0000-0000-000000000001');

-- -----------------------------------------------------------------------------
-- B5. WALLET_LEDGER (Unified immutable transaction log)
-- -----------------------------------------------------------------------------
CREATE TABLE public.wallet_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_type public.wallet_type NOT NULL,
    wallet_owner_id UUID, -- user_id for user wallets, partner_id for gym, NULL for platform
    amount DECIMAL(15, 2) NOT NULL, -- Positive or negative
    type public.ledger_entry_type NOT NULL,
    description TEXT NOT NULL,
    reference_id UUID, -- checkin_id, topup_request_id, settlement_id, etc.
    reference_type TEXT, -- 'checkin', 'topup', 'settlement', 'adjustment', 'refund'
    balance_before DECIMAL(15, 2) NOT NULL,
    balance_after DECIMAL(15, 2) NOT NULL,
    metadata JSONB DEFAULT '{}',
    idempotency_key TEXT UNIQUE, -- Critical: prevents double-spend
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.wallet_ledger IS 'Immutable append-only ledger for all financial transactions';
COMMENT ON COLUMN public.wallet_ledger.wallet_type IS 'user | gym | platform';
COMMENT ON COLUMN public.wallet_ledger.idempotency_key IS 'UNIQUE key preventing duplicate transactions';
COMMENT ON COLUMN public.wallet_ledger.amount IS 'Positive = credit, Negative = debit';

-- -----------------------------------------------------------------------------
-- B6. TOPUP_REQUESTS (User top-up requests requiring admin approval)
-- -----------------------------------------------------------------------------
CREATE TABLE public.topup_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    proof_url TEXT, -- Image URL from Supabase Storage
    notes TEXT,
    status public.topup_status NOT NULL DEFAULT 'pending',
    admin_notes TEXT,
    reviewed_by UUID REFERENCES public.profiles(user_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.topup_requests IS 'User cash top-up requests pending admin verification';

-- -----------------------------------------------------------------------------
-- B7. PARTNERS (Gym brands)
-- -----------------------------------------------------------------------------
CREATE TABLE public.partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    category TEXT DEFAULT 'gym', -- gym, pool, studio, etc.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.partners IS 'Gym brands (e.g., Olympia Gym)';
COMMENT ON COLUMN public.partners.owner_id IS 'User with gym_owner role who manages this partner';

-- Now add the FK constraint to gym_wallets
ALTER TABLE public.gym_wallets 
    ADD CONSTRAINT gym_wallets_partner_id_fkey 
    FOREIGN KEY (partner_id) REFERENCES public.partners(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- B8. PARTNER_LOCATIONS (Gym branches)
-- -----------------------------------------------------------------------------
CREATE TABLE public.partner_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g., "Olympia - Mazzeh"
    address_text TEXT,
    city TEXT NOT NULL DEFAULT 'Damascus',
    country TEXT NOT NULL DEFAULT 'Syria',
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    radius_m DOUBLE PRECISION NOT NULL DEFAULT 150 CHECK (radius_m >= 50 AND radius_m <= 500),
    
    -- Pricing (base_price is the gym's 80% share)
    base_price DECIMAL(12, 2) NOT NULL CHECK (base_price > 0),
    
    -- Metadata
    amenities TEXT[] DEFAULT '{}', -- Array: 'weights', 'cardio', 'pool', 'sauna'
    operating_hours JSONB DEFAULT '{}', -- {"mon": {"open": "06:00", "close": "23:00"}, ...}
    photos TEXT[] DEFAULT '{}', -- Array of storage URLs
    
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.partner_locations IS 'Physical gym branches with pricing and geo-fencing';
COMMENT ON COLUMN public.partner_locations.base_price IS 'Gym share (80% of final user price)';
COMMENT ON COLUMN public.partner_locations.radius_m IS 'Geo-fence radius in meters (50-500)';

-- -----------------------------------------------------------------------------
-- B9. QR_TOKENS (Static QR codes for location check-in)
-- -----------------------------------------------------------------------------
CREATE TABLE public.qr_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_location_id UUID NOT NULL REFERENCES public.partner_locations(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    type public.qr_type NOT NULL DEFAULT 'static',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMPTZ, -- NULL for static, used for rotating tokens
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.qr_tokens IS 'QR codes for gym check-in (static printed codes)';
COMMENT ON COLUMN public.qr_tokens.token IS 'Unique token string (e.g., SP-A1B2C3D4E5F6)';

-- -----------------------------------------------------------------------------
-- B10. CHECKINS (Gym visit records)
-- -----------------------------------------------------------------------------
CREATE TABLE public.checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    partner_location_id UUID NOT NULL REFERENCES public.partner_locations(id) ON DELETE CASCADE,
    
    -- Financial snapshot (immutable)
    base_price DECIMAL(12, 2) NOT NULL,      -- Gym's 80% share
    platform_fee DECIMAL(12, 2) NOT NULL,    -- Platform's 20% share
    final_price DECIMAL(12, 2) NOT NULL,     -- What user paid (100%)
    
    status public.checkin_status NOT NULL DEFAULT 'approved',
    rejection_reason TEXT,
    
    -- Metadata
    geo_lat DOUBLE PRECISION,
    geo_lng DOUBLE PRECISION,
    device_hash TEXT,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.checkins IS 'User gym check-in records with price snapshots';
COMMENT ON COLUMN public.checkins.final_price IS 'Total amount user paid';
COMMENT ON COLUMN public.checkins.base_price IS 'Amount credited to gym (80%)';
COMMENT ON COLUMN public.checkins.platform_fee IS 'Amount credited to platform (20%)';

-- -----------------------------------------------------------------------------
-- B11. SETTLEMENTS (Gym wallet payouts)
-- -----------------------------------------------------------------------------
CREATE TABLE public.settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    status public.settlement_status NOT NULL DEFAULT 'pending',
    period_start DATE,
    period_end DATE,
    transaction_ref TEXT, -- External payment reference
    admin_notes TEXT,
    created_by UUID REFERENCES public.profiles(user_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.settlements IS 'Gym wallet settlement records (admin payouts)';

-- ==============================================================================
-- SECTION C: INDEXES & CONSTRAINTS
-- ==============================================================================

-- Profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_status ON public.profiles(status);

-- Wallets
CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);

-- Gym Wallets
CREATE INDEX idx_gym_wallets_partner_id ON public.gym_wallets(partner_id);

-- Wallet Ledger (critical for performance)
CREATE INDEX idx_ledger_wallet_owner_created ON public.wallet_ledger(wallet_owner_id, created_at DESC);
CREATE INDEX idx_ledger_type ON public.wallet_ledger(type);
CREATE INDEX idx_ledger_reference ON public.wallet_ledger(reference_type, reference_id);
CREATE INDEX idx_ledger_wallet_type ON public.wallet_ledger(wallet_type, wallet_owner_id);

-- Top-up Requests
CREATE INDEX idx_topup_user_id ON public.topup_requests(user_id, created_at DESC);
CREATE INDEX idx_topup_status ON public.topup_requests(status, created_at DESC);

-- Partners
CREATE INDEX idx_partners_owner_id ON public.partners(owner_id);
CREATE INDEX idx_partners_active ON public.partners(is_active);

-- Partner Locations
CREATE INDEX idx_locations_partner_id ON public.partner_locations(partner_id);
CREATE INDEX idx_locations_city_active ON public.partner_locations(city, is_active);
CREATE INDEX idx_locations_active ON public.partner_locations(is_active);

-- QR Tokens
CREATE INDEX idx_qr_location_id ON public.qr_tokens(partner_location_id, is_active);

-- Checkins
CREATE INDEX idx_checkins_user_id ON public.checkins(user_id, created_at DESC);
CREATE INDEX idx_checkins_location_id ON public.checkins(partner_location_id, created_at DESC);
CREATE INDEX idx_checkins_created_at ON public.checkins(created_at DESC);

-- Settlements
CREATE INDEX idx_settlements_partner_id ON public.settlements(partner_id, created_at DESC);
CREATE INDEX idx_settlements_status ON public.settlements(status);

-- ==============================================================================
-- SECTION D: UTILITY FUNCTIONS
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- D1. Haversine Distance (GPS geo-fencing)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.haversine_distance(
    lat1 DOUBLE PRECISION, 
    lng1 DOUBLE PRECISION, 
    lat2 DOUBLE PRECISION, 
    lng2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    R CONSTANT DOUBLE PRECISION := 6371000; -- Earth radius in meters
    phi1 DOUBLE PRECISION := RADIANS(lat1);
    phi2 DOUBLE PRECISION := RADIANS(lat2);
    d_phi DOUBLE PRECISION := RADIANS(lat2 - lat1);
    d_lambda DOUBLE PRECISION := RADIANS(lng2 - lng1);
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    a := SIN(d_phi / 2) * SIN(d_phi / 2) + 
         COS(phi1) * COS(phi2) * SIN(d_lambda / 2) * SIN(d_lambda / 2);
    c := 2 * ATAN2(SQRT(a), SQRT(1 - a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.haversine_distance IS 'Calculate distance in meters between two GPS coordinates';

-- -----------------------------------------------------------------------------
-- D2. Role Check (avoids RLS recursion)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.has_role(required_role text) 
RETURNS BOOLEAN AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role::text INTO user_role 
    FROM public.profiles 
    WHERE user_id = auth.uid();
    
    RETURN user_role = required_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.has_role IS 'Check user role bypassing RLS (SECURITY DEFINER)';

-- -----------------------------------------------------------------------------
-- D3. Admin Check Helper
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- SECTION E: CORE BUSINESS LOGIC FUNCTIONS (SECURITY DEFINER)
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- E1. PERFORM CHECK-IN (Atomic transaction per Freeze V1 Section 6)
-- -----------------------------------------------------------------------------
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
    v_qr RECORD;
    v_wallet RECORD;
    v_gym_wallet RECORD;
    v_platform_wallet RECORD;
    v_distance DOUBLE PRECISION;
    v_base_price DECIMAL(12, 2);
    v_user_price DECIMAL(12, 2);
    v_platform_fee DECIMAL(12, 2);
    v_checkin_id UUID;
    v_idem_key TEXT;
    v_user_status TEXT;
BEGIN
    -- Check user status
    SELECT status::text INTO v_user_status FROM public.profiles WHERE user_id = v_user_id;
    IF v_user_status = 'frozen' THEN
        RETURN jsonb_build_object(
            'success', false, 
            'code', 'ACCOUNT_FROZEN',
            'message', 'حسابك مجمد. تواصل مع الدعم'
        );
    END IF;

    -- Generate idempotency key if not provided
    v_idem_key := COALESCE(
        p_idempotency_key, 
        'checkin:' || v_user_id || ':' || p_qr_token || ':' || CURRENT_DATE || ':' || gen_random_uuid()
    );

    -- Check if already processed
    IF EXISTS (SELECT 1 FROM public.wallet_ledger WHERE idempotency_key = v_idem_key) THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'DUPLICATE_REQUEST',
            'message', 'تم تسجيل هذا الدخول مسبقاً'
        );
    END IF;

    -- Step 1: Validate QR token
    SELECT * INTO v_qr 
    FROM public.qr_tokens 
    WHERE token = p_qr_token AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'QR_INVALID',
            'message', 'رمز QR غير صالح'
        );
    END IF;

    -- Step 2: Get location and validate
    SELECT * INTO v_location 
    FROM public.partner_locations 
    WHERE id = v_qr.partner_location_id;
    
    IF NOT v_location.is_active THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'LOCATION_CLOSED',
            'message', 'هذا الموقع مغلق حالياً'
        );
    END IF;

    -- Step 3: Get partner and validate
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

    -- Step 4: Geo-fence validation
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

    -- Step 5: Calculate pricing per Freeze V1 formula
    -- base_price is 80% share (what gym gets)
    -- user_price = CEIL((base_price / 0.80) / 500) * 500
    v_base_price := v_location.base_price;
    v_user_price := CEIL((v_base_price / 0.80) / 500.0) * 500.0;
    v_platform_fee := v_user_price - v_base_price;

    -- Step 6: Lock user wallet and check balance
    SELECT * INTO v_wallet 
    FROM public.wallets 
    WHERE user_id = v_user_id 
    FOR UPDATE;
    
    IF v_wallet.balance < v_user_price THEN
        RETURN jsonb_build_object(
            'success', false,
            'code', 'LOW_BALANCE',
            'message', 'رصيدك غير كافٍ. الكلفة: ' || v_user_price || ' ل.س',
            'required', v_user_price,
            'balance', v_wallet.balance
        );
    END IF;

    -- Step 7: Lock gym wallet
    SELECT * INTO v_gym_wallet 
    FROM public.gym_wallets 
    WHERE partner_id = v_partner.id 
    FOR UPDATE;

    -- Step 8: Lock platform wallet
    SELECT * INTO v_platform_wallet 
    FROM public.platform_wallet 
    FOR UPDATE;

    -- Step 9: Create checkin record
    INSERT INTO public.checkins (
        user_id, partner_location_id, base_price, platform_fee, final_price,
        status, geo_lat, geo_lng, device_hash, metadata
    ) VALUES (
        v_user_id, v_location.id, v_base_price, v_platform_fee, v_user_price,
        'approved', p_lat, p_lng, p_device_hash, 
        jsonb_build_object('qr_token', p_qr_token, 'distance_m', ROUND(v_distance::numeric, 2))
    )
    RETURNING id INTO v_checkin_id;

    -- Step 10: Deduct from user wallet
    UPDATE public.wallets
    SET balance = balance - v_user_price,
        total_spent = total_spent + v_user_price,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    -- Step 11: Credit gym wallet
    UPDATE public.gym_wallets
    SET balance = balance + v_base_price,
        total_earned = total_earned + v_base_price,
        updated_at = NOW()
    WHERE partner_id = v_partner.id;

    -- Step 12: Credit platform wallet
    UPDATE public.platform_wallet
    SET balance = balance + v_platform_fee,
        total_earned = total_earned + v_platform_fee,
        updated_at = NOW()
    WHERE id = '00000000-0000-0000-0000-000000000001';

    -- Step 13: Create ledger entries (3 entries)
    -- 13a. User debit
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

    -- 13b. Gym credit
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

    -- 13c. Platform credit
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

    -- Step 14: Return success
    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تسجيل الدخول بنجاح!',
        'checkin_id', v_checkin_id,
        'gym_name', v_partner.name,
        'location_name', v_location.name,
        'price_paid', v_user_price,
        'new_balance', v_wallet.balance - v_user_price
    );
END;
$$;

COMMENT ON FUNCTION public.perform_checkin IS 'Atomic check-in with wallet deduction and commission split';

-- -----------------------------------------------------------------------------
-- E2. APPROVE TOP-UP (Admin only)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_topup(
    p_request_id UUID
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_request RECORD;
    v_wallet RECORD;
    v_idem_key TEXT;
BEGIN
    -- Verify admin role
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    -- Get and lock the request
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

    -- Lock user wallet
    SELECT * INTO v_wallet 
    FROM public.wallets 
    WHERE user_id = v_request.user_id 
    FOR UPDATE;

    -- Idempotency key
    v_idem_key := 'topup:' || p_request_id;

    -- Check if already processed
    IF EXISTS (SELECT 1 FROM public.wallet_ledger WHERE idempotency_key = v_idem_key) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'تم معالجة هذا الطلب مسبقاً'
        );
    END IF;

    -- Update request status
    UPDATE public.topup_requests
    SET status = 'approved',
        reviewed_by = v_admin_id,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Credit user wallet
    UPDATE public.wallets
    SET balance = balance + v_request.amount,
        total_topup = total_topup + v_request.amount,
        updated_at = NOW()
    WHERE user_id = v_request.user_id;

    -- Create ledger entry
    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        idempotency_key, metadata
    ) VALUES (
        'user', v_request.user_id, v_request.amount, 'topup',
        'شحن رصيد (موافقة إدارية)',
        p_request_id, 'topup', v_wallet.balance, v_wallet.balance + v_request.amount,
        v_idem_key,
        jsonb_build_object('admin_id', v_admin_id, 'notes', v_request.notes)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم الموافقة على الشحن',
        'amount', v_request.amount,
        'new_balance', v_wallet.balance + v_request.amount
    );
END;
$$;

COMMENT ON FUNCTION public.approve_topup IS 'Admin approves top-up request and credits user wallet';

-- -----------------------------------------------------------------------------
-- E3. REJECT TOP-UP (Admin only)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_topup(
    p_request_id UUID,
    p_admin_notes TEXT
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
BEGIN
    -- Verify admin role
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    -- Update request status
    UPDATE public.topup_requests
    SET status = 'rejected',
        admin_notes = p_admin_notes,
        reviewed_by = v_admin_id,
        updated_at = NOW()
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'الطلب غير موجود أو تمت معالجته'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم رفض الطلب'
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- E4. ADMIN ADJUST WALLET (Manual correction)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_adjust_wallet(
    p_user_id UUID,
    p_amount DECIMAL,
    p_reason TEXT
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_wallet RECORD;
    v_new_balance DECIMAL;
    v_idem_key TEXT;
BEGIN
    -- Verify admin role
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    -- Lock wallet
    SELECT * INTO v_wallet 
    FROM public.wallets 
    WHERE user_id = p_user_id 
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'المستخدم غير موجود'
        );
    END IF;

    v_new_balance := v_wallet.balance + p_amount;
    
    IF v_new_balance < 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'الرصيد لا يكفي للخصم'
        );
    END IF;

    -- Idempotency key
    v_idem_key := 'adjustment:' || v_admin_id || ':' || p_user_id || ':' || extract(epoch from now())::bigint;

    -- Update wallet
    UPDATE public.wallets
    SET balance = v_new_balance,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Create ledger entry
    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_type, balance_before, balance_after,
        idempotency_key, metadata
    ) VALUES (
        'user', p_user_id, p_amount, 'adjustment',
        p_reason,
        'adjustment', v_wallet.balance, v_new_balance,
        v_idem_key,
        jsonb_build_object('admin_id', v_admin_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تعديل الرصيد',
        'new_balance', v_new_balance
    );
END;
$$;

COMMENT ON FUNCTION public.admin_adjust_wallet IS 'Admin manual wallet adjustment with audit trail';

-- -----------------------------------------------------------------------------
-- E5. SETTLE GYM WALLET (Admin payout to gym)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_gym_wallet(
    p_partner_id UUID,
    p_amount DECIMAL,
    p_period_start DATE,
    p_period_end DATE,
    p_transaction_ref TEXT DEFAULT NULL,
    p_admin_notes TEXT DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_gym_wallet RECORD;
    v_settlement_id UUID;
    v_idem_key TEXT;
BEGIN
    -- Verify admin role
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    -- Lock gym wallet
    SELECT * INTO v_gym_wallet 
    FROM public.gym_wallets 
    WHERE partner_id = p_partner_id 
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'محفظة النادي غير موجودة'
        );
    END IF;

    IF v_gym_wallet.balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'رصيد النادي غير كافٍ',
            'available', v_gym_wallet.balance,
            'requested', p_amount
        );
    END IF;

    -- Create settlement record
    INSERT INTO public.settlements (
        partner_id, amount, status, period_start, period_end,
        transaction_ref, admin_notes, created_by
    ) VALUES (
        p_partner_id, p_amount, 'pending', p_period_start, p_period_end,
        p_transaction_ref, p_admin_notes, v_admin_id
    )
    RETURNING id INTO v_settlement_id;

    -- Idempotency key
    v_idem_key := 'settlement:' || v_settlement_id;

    -- Deduct from gym wallet
    UPDATE public.gym_wallets
    SET balance = balance - p_amount,
        total_settled = total_settled + p_amount,
        updated_at = NOW()
    WHERE partner_id = p_partner_id;

    -- Create ledger entry
    INSERT INTO public.wallet_ledger (
        wallet_type, wallet_owner_id, amount, type, description,
        reference_id, reference_type, balance_before, balance_after,
        idempotency_key, metadata
    ) VALUES (
        'gym', p_partner_id, -p_amount, 'settlement',
        'تسوية مالية للفترة ' || p_period_start || ' إلى ' || p_period_end,
        v_settlement_id, 'settlement', v_gym_wallet.balance, v_gym_wallet.balance - p_amount,
        v_idem_key,
        jsonb_build_object('admin_id', v_admin_id, 'transaction_ref', p_transaction_ref)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم إنشاء سجل التسوية',
        'settlement_id', v_settlement_id,
        'new_balance', v_gym_wallet.balance - p_amount
    );
END;
$$;

COMMENT ON FUNCTION public.settle_gym_wallet IS 'Admin settles gym wallet (records payout)';

-- -----------------------------------------------------------------------------
-- E6. MARK SETTLEMENT AS PAID (Admin confirms payment)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_settlement_paid(
    p_settlement_id UUID,
    p_transaction_ref TEXT
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Verify admin role
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    UPDATE public.settlements
    SET status = 'paid',
        transaction_ref = p_transaction_ref,
        updated_at = NOW()
    WHERE id = p_settlement_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'التسوية غير موجودة أو تم دفعها'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم تحديث حالة الدفع'
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- E7. GENERATE QR TOKEN (Gym owner or admin)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_qr_token(
    p_location_id UUID
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_owner_id UUID;
    v_role text;
    v_token TEXT;
BEGIN
    SELECT role::text INTO v_role FROM public.profiles WHERE user_id = v_user_id;
    
    -- Check ownership or admin
    SELECT p.owner_id INTO v_owner_id
    FROM public.partner_locations pl
    JOIN public.partners p ON pl.partner_id = p.id
    WHERE pl.id = p_location_id;

    IF v_owner_id != v_user_id AND v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: must be gym owner or admin';
    END IF;

    -- Generate token (SP- prefix + 12 uppercase hex chars)
    v_token := 'SP-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 12));

    -- Deactivate old tokens
    UPDATE public.qr_tokens 
    SET is_active = false 
    WHERE partner_location_id = p_location_id;

    -- Insert new token
    INSERT INTO public.qr_tokens (partner_location_id, token, type)
    VALUES (p_location_id, v_token, 'static');

    RETURN v_token;
END;
$$;

COMMENT ON FUNCTION public.generate_qr_token IS 'Generate new QR token for location (gym owner or admin)';

-- -----------------------------------------------------------------------------
-- E8. GYM OWNER ANALYTICS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_provider_analytics()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_total_earnings DECIMAL(15, 2);
    v_total_visits INT;
    v_today_visits INT;
    v_locations_count INT;
    v_unsettled_balance DECIMAL(15, 2);
BEGIN
    -- Get total earnings and visits
    SELECT 
        COALESCE(SUM(c.base_price), 0),
        COUNT(*)
    INTO v_total_earnings, v_total_visits
    FROM public.checkins c
    JOIN public.partner_locations pl ON c.partner_location_id = pl.id
    JOIN public.partners p ON pl.partner_id = p.id
    WHERE p.owner_id = v_user_id AND c.status = 'approved';

    -- Today's visits
    SELECT COUNT(*) INTO v_today_visits
    FROM public.checkins c
    JOIN public.partner_locations pl ON c.partner_location_id = pl.id
    JOIN public.partners p ON pl.partner_id = p.id
    WHERE p.owner_id = v_user_id 
      AND c.status = 'approved' 
      AND c.created_at >= CURRENT_DATE;

    -- Locations count
    SELECT COUNT(*) INTO v_locations_count
    FROM public.partner_locations pl
    JOIN public.partners p ON pl.partner_id = p.id
    WHERE p.owner_id = v_user_id;

    -- Unsettled balance (sum of all gym wallets owned)
    SELECT COALESCE(SUM(gw.balance), 0) INTO v_unsettled_balance
    FROM public.gym_wallets gw
    JOIN public.partners p ON gw.partner_id = p.id
    WHERE p.owner_id = v_user_id;

    RETURN jsonb_build_object(
        'total_earnings', v_total_earnings,
        'total_visits', v_total_visits,
        'today_visits', v_today_visits,
        'locations_count', v_locations_count,
        'unsettled_balance', v_unsettled_balance
    );
END;
$$;

COMMENT ON FUNCTION public.get_provider_analytics IS 'Get gym owner analytics dashboard data';

-- ==============================================================================
-- SECTION F: TRIGGERS
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- F1. Auto-create profile and user wallet on auth.users insert
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create profile
    INSERT INTO public.profiles (user_id, phone, name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'phone', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'name', 'مستخدم جديد'),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'athlete')
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- Create user wallet
    INSERT INTO public.wallets (user_id, balance)
    VALUES (NEW.id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION public.handle_new_user IS 'Auto-create profile and wallet when user signs up';

-- -----------------------------------------------------------------------------
-- F2. Updated_at trigger helper
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_topup_requests_updated_at BEFORE UPDATE ON public.topup_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partners_updated_at BEFORE UPDATE ON public.partners
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_partner_locations_updated_at BEFORE UPDATE ON public.partner_locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settlements_updated_at BEFORE UPDATE ON public.settlements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- SECTION G: ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_wallet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topup_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- G1. PROFILES
-- -----------------------------------------------------------------------------
CREATE POLICY "profiles_public_read" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "profiles_user_insert" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_user_update" ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "profiles_admin_all" ON public.profiles
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G2. WALLETS
-- -----------------------------------------------------------------------------
CREATE POLICY "wallets_user_read" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "wallets_admin_all" ON public.wallets
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G3. GYM_WALLETS
-- -----------------------------------------------------------------------------
CREATE POLICY "gym_wallets_owner_read" ON public.gym_wallets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.partners p
            WHERE p.id = partner_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "gym_wallets_admin_all" ON public.gym_wallets
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G4. PLATFORM_WALLET
-- -----------------------------------------------------------------------------
CREATE POLICY "platform_wallet_admin_read" ON public.platform_wallet
    FOR SELECT USING (public.is_admin());

CREATE POLICY "platform_wallet_admin_all" ON public.platform_wallet
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G5. WALLET_LEDGER
-- -----------------------------------------------------------------------------
-- Users can read their own ledger
CREATE POLICY "ledger_user_read" ON public.wallet_ledger
    FOR SELECT USING (
        wallet_type = 'user' AND wallet_owner_id = auth.uid()
    );

-- Gym owners can read their gym ledger
CREATE POLICY "ledger_gym_owner_read" ON public.wallet_ledger
    FOR SELECT USING (
        wallet_type = 'gym' AND EXISTS (
            SELECT 1 FROM public.partners p
            WHERE p.id = wallet_owner_id AND p.owner_id = auth.uid()
        )
    );

-- Admins can read all
CREATE POLICY "ledger_admin_read" ON public.wallet_ledger
    FOR SELECT USING (public.is_admin());

-- No direct INSERT/UPDATE/DELETE - only via SECURITY DEFINER functions

-- -----------------------------------------------------------------------------
-- G6. TOPUP_REQUESTS
-- -----------------------------------------------------------------------------
CREATE POLICY "topup_user_read" ON public.topup_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "topup_user_insert" ON public.topup_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "topup_admin_all" ON public.topup_requests
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G7. PARTNERS (public read for map)
-- -----------------------------------------------------------------------------
CREATE POLICY "partners_public_read" ON public.partners
    FOR SELECT USING (true);

CREATE POLICY "partners_owner_manage" ON public.partners
    FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "partners_admin_all" ON public.partners
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G8. PARTNER_LOCATIONS (public read for map)
-- -----------------------------------------------------------------------------
CREATE POLICY "locations_public_read" ON public.partner_locations
    FOR SELECT USING (true);

CREATE POLICY "locations_owner_manage" ON public.partner_locations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.partners p
            WHERE p.id = partner_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "locations_admin_all" ON public.partner_locations
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G9. QR_TOKENS
-- -----------------------------------------------------------------------------
CREATE POLICY "qr_tokens_public_read" ON public.qr_tokens
    FOR SELECT USING (true);

CREATE POLICY "qr_tokens_owner_manage" ON public.qr_tokens
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.partner_locations pl
            JOIN public.partners p ON pl.partner_id = p.id
            WHERE pl.id = partner_location_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "qr_tokens_admin_all" ON public.qr_tokens
    FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G10. CHECKINS
-- -----------------------------------------------------------------------------
CREATE POLICY "checkins_user_read" ON public.checkins
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "checkins_gym_owner_read" ON public.checkins
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.partner_locations pl
            JOIN public.partners p ON pl.partner_id = p.id
            WHERE pl.id = partner_location_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "checkins_admin_read" ON public.checkins
    FOR SELECT USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- G11. SETTLEMENTS
-- -----------------------------------------------------------------------------
CREATE POLICY "settlements_gym_owner_read" ON public.settlements
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.partners p
            WHERE p.id = partner_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "settlements_admin_all" ON public.settlements
    FOR ALL USING (public.is_admin());

-- ==============================================================================
-- SECTION H: SEED DATA
-- ==============================================================================

-- Note: Actual users are created via Supabase Auth (phone OTP or email/password)
-- The handle_new_user trigger will auto-create profiles and wallets

-- Sample partners (for demo purposes)
INSERT INTO public.partners (id, name, description, category, is_active) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Olympia Gym', 'نادي أوليمبيا الرياضي - الأفضل في دمشق', 'gym', true),
    ('22222222-2222-2222-2222-222222222222', 'Golden Gym', 'نادي غولدين جيم - تجهيزات حديثة', 'gym', true);

-- Create gym wallets for these partners
INSERT INTO public.gym_wallets (partner_id, balance) VALUES
    ('11111111-1111-1111-1111-111111111111', 0),
    ('22222222-2222-2222-2222-222222222222', 0);

-- Sample locations (use Damascus coordinates - adjust for testing)
INSERT INTO public.partner_locations (
    id, partner_id, name, address_text, city, country,
    lat, lng, radius_m, base_price, amenities
) VALUES
    (
        'd00d0001-1111-1111-1111-111111111111',
        '11111111-1111-1111-1111-111111111111',
        'Olympia - Mazzeh',
        'شارع مزة - قرب ساحة المحافظة',
        'Damascus', 'Syria',
        33.5042, 36.2415, 200, 8000.00,
        ARRAY['weights', 'cardio', 'sauna']
    ),
    (
        'd00d0002-2222-2222-2222-222222222222',
        '22222222-2222-2222-2222-222222222222',
        'Golden - Abu Rummaneh',
        'أبو رمانة - شارع بغداد',
        'Damascus', 'Syria',
        33.5185, 36.2820, 150, 12000.00,
        ARRAY['weights', 'cardio', 'pool', 'sauna']
    );

-- Sample QR tokens
INSERT INTO public.qr_tokens (partner_location_id, token, type) VALUES
    ('d00d0001-1111-1111-1111-111111111111', 'SP-OLYMPIA-DEMO', 'static'),
    ('d00d0002-2222-2222-2222-222222222222', 'SP-GOLDEN-DEMO', 'static');

-- ==============================================================================
-- SECTION I: POST-DEPLOYMENT HELPER FUNCTIONS
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- I1. ASSIGN ADMIN ROLE (Run manually after first user signs up)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_admin_role(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Only allow if caller is already admin or if no admins exist
    IF NOT public.is_admin() AND EXISTS (SELECT 1 FROM public.profiles WHERE role = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'message', 'Unauthorized');
    END IF;

    UPDATE public.profiles
    SET role = 'admin'
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object('success', true, 'message', 'Admin role assigned');
END;
$$;

COMMENT ON FUNCTION public.assign_admin_role IS 'Assign admin role to user (self-bootstrapping or admin-only)';

-- -----------------------------------------------------------------------------
-- I2. ASSIGN GYM OWNER ROLE AND LINK PARTNER
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_gym_owner(
    p_user_id UUID,
    p_partner_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Only admin can assign
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Unauthorized: admin role required';
    END IF;

    -- Update user role
    UPDATE public.profiles
    SET role = 'gym_owner'
    WHERE user_id = p_user_id;

    -- Link partner to owner
    UPDATE public.partners
    SET owner_id = p_user_id
    WHERE id = p_partner_id;

    RETURN jsonb_build_object('success', true, 'message', 'Gym owner assigned');
END;
$$;

COMMENT ON FUNCTION public.assign_gym_owner IS 'Admin assigns gym_owner role and links partner';

-- ==============================================================================
-- END OF SCHEMA
-- ==============================================================================

-- Verification queries (run after deployment to verify structure)
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
-- SELECT count(*) FROM public.profiles;
-- SELECT * FROM public.platform_wallet;
