-- ==============================================================================
-- SPORTPASS PERMISSIONS FIX (DEPRECATED / BLOCKED)
-- ==============================================================================
-- IMPORTANT:
-- This file is intentionally blocked because the old version granted ALL
-- privileges on all tables/functions/sequences to anon/authenticated roles.
-- That pattern is unsafe and can bypass least-privilege expectations.
--
-- Use explicit, migration-driven grants only (schema.sql + patch files),
-- and never apply blanket GRANT ALL to anon/authenticated in production.
-- ==============================================================================

DO $$
BEGIN
  RAISE EXCEPTION
    'Blocked script: permissions_fix.sql is deprecated. Apply least-privilege grants via reviewed migrations only.';
END $$;
