-- ==============================================================================
-- SPORTPASS CLEANUP SCRIPT
-- ==============================================================================
-- WARNING: This will permanently delete all SportPass data, tables, and types.
-- Use this before reapplying schema.sql to get a clean state.
-- ==============================================================================

-- 1. DROP TRIGGERS/FUNCTIONS (handles old + new signatures)
DO $$
DECLARE
    fn RECORD;
BEGIN
    -- Trigger created by schema.sql on auth.users
    BEGIN
        EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users';
    EXCEPTION
        WHEN undefined_table THEN
            NULL;
    END;

    FOR fn IN
        SELECT
            n.nspname AS schema_name,
            p.proname AS function_name,
            pg_get_function_identity_arguments(p.oid) AS function_args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname = ANY (ARRAY[
              'perform_checkin',
              'approve_topup',
              'reject_topup',
              'admin_adjust_wallet',
              'settle_gym_wallet',
              'mark_settlement_paid',
              'generate_qr_token',
              'get_provider_analytics',
              'handle_new_user',
              'update_updated_at_column',
              'haversine_distance',
              'has_role',
              'is_admin',
              'assign_admin_role',
              'assign_gym_owner',
              'assign_gym_owner_by_phone',
              'submit_role_selection',
              'review_gym_owner_request',
              'protect_profile_sensitive_fields',
              'request_qr_token_regeneration',
              'review_qr_token_regeneration',
              'set_partner_active',
              'set_location_active'
          ])
    LOOP
        EXECUTE format(
            'DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE',
            fn.schema_name,
            fn.function_name,
            fn.function_args
        );
    END LOOP;
END
$$;

-- 2. DROP TABLES (Ordered by dependencies)
DROP TABLE IF EXISTS public.wallet_ledger;
DROP TABLE IF EXISTS public.checkins;
DROP TABLE IF EXISTS public.qr_tokens;
DROP TABLE IF EXISTS public.qr_token_regeneration_requests;
DROP TABLE IF EXISTS public.gym_owner_requests;
DROP TABLE IF EXISTS public.partner_locations;
DROP TABLE IF EXISTS public.settlements;
DROP TABLE IF EXISTS public.gym_wallets;
DROP TABLE IF EXISTS public.platform_wallet;
DROP TABLE IF EXISTS public.partners;
DROP TABLE IF EXISTS public.topup_requests;
DROP TABLE IF EXISTS public.wallets;
DROP TABLE IF EXISTS public.profiles;

-- 3. DROP TYPES
DROP TYPE IF EXISTS public.user_role;
DROP TYPE IF EXISTS public.ledger_entry_type;
DROP TYPE IF EXISTS public.wallet_type;
DROP TYPE IF EXISTS public.checkin_status;
DROP TYPE IF EXISTS public.topup_status;
DROP TYPE IF EXISTS public.settlement_status;
DROP TYPE IF EXISTS public.qr_type;
DROP TYPE IF EXISTS public.account_status;

-- 4. CLEANUP EXTENSIONS (Optional, usually keep them)
-- DROP EXTENSION IF EXISTS "uuid-ossp";
-- DROP EXTENSION IF EXISTS "pg_trgm";

DO $$
BEGIN
  RAISE NOTICE 'Cleanup complete! You can now run schema.sql to restore the production environment.';
END $$;
