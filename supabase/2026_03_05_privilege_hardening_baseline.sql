-- ==============================================================================
-- SportPass Patch: Privilege Hardening Baseline (anon/authenticated)
-- Date: 2026-03-05
--
-- Goal:
-- - Remove excessive table grants (DELETE/TRUNCATE/TRIGGER/REFERENCES ...).
-- - Keep only minimal grants required by the current app + RLS model.
-- - Lock down system_migrations and profile read exposure.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1) Revoke broad table/sequence grants
-- ------------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;

-- Prevent future tables/sequences from inheriting broad access.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;

GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2) Minimal table grants for anon (public market browsing only)
-- ------------------------------------------------------------------------------
GRANT SELECT ON TABLE public.partners TO anon;
GRANT SELECT ON TABLE public.partner_locations TO anon;

-- ------------------------------------------------------------------------------
-- 3) Minimal table grants for authenticated
-- ------------------------------------------------------------------------------
-- Read paths
GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.partners TO authenticated;
GRANT SELECT ON TABLE public.partner_locations TO authenticated;
GRANT SELECT ON TABLE public.qr_tokens TO authenticated;
GRANT SELECT ON TABLE public.checkins TO authenticated;
GRANT SELECT ON TABLE public.wallets TO authenticated;
GRANT SELECT ON TABLE public.wallet_ledger TO authenticated;
GRANT SELECT ON TABLE public.topup_requests TO authenticated;
GRANT SELECT ON TABLE public.gym_owner_requests TO authenticated;
GRANT SELECT ON TABLE public.qr_token_regeneration_requests TO authenticated;
GRANT SELECT ON TABLE public.gym_wallets TO authenticated;
GRANT SELECT ON TABLE public.platform_wallet TO authenticated;
GRANT SELECT ON TABLE public.settlements TO authenticated;
GRANT SELECT ON TABLE public.system_migrations TO authenticated;

-- Insert paths used directly by the app
GRANT INSERT ON TABLE public.profiles TO authenticated;
GRANT INSERT ON TABLE public.topup_requests TO authenticated;
GRANT INSERT ON TABLE public.gym_owner_requests TO authenticated;
GRANT INSERT ON TABLE public.qr_token_regeneration_requests TO authenticated;
GRANT INSERT ON TABLE public.partners TO authenticated;
GRANT INSERT ON TABLE public.partner_locations TO authenticated;
GRANT INSERT ON TABLE public.settlements TO authenticated;

-- Update paths used directly by the app
GRANT UPDATE ON TABLE public.profiles TO authenticated;
GRANT UPDATE ON TABLE public.partners TO authenticated;
GRANT UPDATE ON TABLE public.partner_locations TO authenticated;

-- ------------------------------------------------------------------------------
-- 4) Tighten RLS policies
-- ------------------------------------------------------------------------------
-- Do not expose all profiles to all authenticated users.
DROP POLICY IF EXISTS "profiles_public_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_user_read" ON public.profiles;
CREATE POLICY "profiles_user_read" ON public.profiles
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- Ensure QR tokens are never publicly enumerable.
DROP POLICY IF EXISTS "qr_tokens_public_read" ON public.qr_tokens;

-- Lock migration metadata to admins only.
ALTER TABLE IF EXISTS public.system_migrations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "system_migrations_admin_read" ON public.system_migrations;
DROP POLICY IF EXISTS "system_migrations_admin_all" ON public.system_migrations;
CREATE POLICY "system_migrations_admin_read" ON public.system_migrations
    FOR SELECT USING (public.is_admin());
CREATE POLICY "system_migrations_admin_all" ON public.system_migrations
    FOR ALL USING (public.is_admin())
    WITH CHECK (public.is_admin());

COMMIT;

DO $$
BEGIN
  RAISE NOTICE 'Patch applied: privilege hardening baseline (anon/authenticated)';
END $$;

