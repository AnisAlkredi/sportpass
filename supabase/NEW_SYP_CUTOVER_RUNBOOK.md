# New SYP Cutover Runbook (Production)

## Goal
Move existing production data from legacy SYP scale to new Syrian Pound scale
without double conversion.

## Prerequisites
- Supabase project owner/admin access.
- SQL Editor access.
- Backup/snapshot before migration (recommended).

## 1) Pre-check (Read-only)
Run these queries first:

```sql
select max(base_price) as max_base_price from public.partner_locations;
select max(final_price) as max_final_price from public.checkins;
select max(amount) as max_topup_amount from public.topup_requests;
```

Interpretation:
- If `max_base_price` or `max_final_price` is in thousands (e.g. 8000, 10000, 12000),
  you are still on legacy scale and must run cutover.
- If values are in tens/hundreds (e.g. 80, 100, 120), likely already converted.

## 2) Apply Migrations (in order)

In Supabase SQL Editor, run:

1. `supabase/2026_03_04_syp_new_currency_cutover.sql`  
2. `supabase/2026_03_04_pricing_model_gym_pays_fee_patch.sql`

What they do:
- migration 1:
- creates `public.system_migrations` marker table if missing,
- converts financial values by `/100` only once,
- updates `public.perform_checkin()` to new-SYP compatible model.

- migration 2:
- converts `partner_locations.base_price` from old semantics
  (gym net share) to new semantics (final entry price paid by athlete),
- keeps a dedicated marker (`pricing_model_gym_pays_fee_2026_03_04`),
- re-applies `perform_checkin()` with "gym pays commission" logic.

## 3) Post-check
Run:

```sql
select * from public.system_migrations
where migration_key = 'syp_redenomination_2026_03_04';

select max(base_price) as max_base_price from public.partner_locations;
select max(final_price) as max_final_price from public.checkins;

select token, partner_location_id, is_active
from public.qr_tokens
where is_active = true
order by created_at desc
limit 5;
```

Expected:
- one marker row exists.
- prices are now in new scale.
- active QR tokens still available.

## 4) Functional Smoke Check
Use these scripts from project root:

```bash
python3 tools/verify_new_syp_scale.py \
  --admin-email anis@sport.com \
  --admin-password password

python3 tools/e2e_wallet_checkin_flow.py \
  --admin-email anis@sport.com \
  --admin-password password \
  --topup-amount 2000
```

## 5) Rollback Strategy
No direct rollback script is provided because this migration changes financial
history scale. Use DB snapshot restore if rollback is required.
