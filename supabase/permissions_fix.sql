-- ==============================================================================
-- SPORTPASS PERMISSIONS SYNC
-- ==============================================================================
-- Run this if you see "permission denied" or 403 Forbidden errors.
-- This ensures the standard Supabase roles have access to the public schema.
-- ==============================================================================

-- 1. Grant USAGE on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Grant ALL on all tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 3. Grant ALL on all functions
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 4. Grant ALL on all sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 5. Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;

DO $$
BEGIN
  RAISE NOTICE 'Permissions synchronized successfully!';
END $$;
