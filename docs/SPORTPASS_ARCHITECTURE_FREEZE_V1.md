# SPORTPASS_ARCHITECTURE_FREEZE_V1

> **Status:** FROZEN  
> **Date:** 2026-02-16  
> **Version:** 1.0  
> **Author:** System Architecture Team  
> **Purpose:** Single source of truth for all implementation. No code deviates from this document without a version bump.

---

## Table of Contents

1. [Business Model](#1-business-model)
2. [Roles & Permissions](#2-roles--permissions)
3. [Wallet System](#3-wallet-system)
4. [Ledger Model](#4-ledger-model)
5. [Gym Model](#5-gym-model)
6. [Check-in Flow](#6-check-in-flow)
7. [Map System](#7-map-system)
8. [UI/UX Principles](#8-uiux-principles)
9. [Security Model](#9-security-model)
10. [Admin Control Panel](#10-admin-control-panel)
11. [Scalability Model](#11-scalability-model)
12. [Appendix: Entity Relationship Summary](#12-appendix-entity-relationship-summary)

---

## 1. Business Model

### 1.1 Revenue Flow

```
User pays cash (ShamCash, etc.) → Admin verifies → User wallet credited
User scans QR at gym → Wallet deducted → 80% to Gym Wallet, 20% to Platform Wallet
Admin settles Gym Wallet to real cash manually (outside the system)
```

### 1.2 Core Rules

| Rule | Value |
|---|---|
| Monetization model | Pay-per-check-in (wallet deduction) |
| Commission split | Platform 20%, Gym 80% |
| Subscription periods | **None** |
| Monthly limits | **None** |
| Pricing authority | Admin sets `base_price` per gym location |
| Final price to user | `base_price × 1.25` (base_price is 80%; user pays 100%) |
| Currency | SYP (default), multi-currency ready |
| Cash-in method | Offline cash → proof upload → admin approval |
| Cash-out method | Manual settlement by admin outside the platform |

### 1.3 Price Calculation Logic

The gym sets a **base_price** which represents the gym's 80% share. The user pays the full amount which includes the 20% platform commission on top:

```
user_price = base_price / 0.80   (i.e., base_price is 80% of what the user pays)
platform_fee = user_price - base_price
```

**Example:**  
- Gym sets base_price = 10,000 SYP  
- user_price = 10,000 / 0.80 = 12,500 SYP  
- platform_fee = 12,500 - 10,000 = 2,500 SYP  
- Gym receives 10,000. Platform receives 2,500. User pays 12,500.

### 1.4 Rounding Rule

All user-facing prices are rounded **up** to the nearest 500 SYP.

```
user_price = CEIL((base_price / 0.80) / 500) × 500
platform_fee = user_price - base_price
```

---

## 2. Roles & Permissions

### 2.1 Role Definitions

#### **Athlete (User)**

| Attribute | Value |
|---|---|
| Role enum value | `athlete` |
| Created via | Phone OTP sign-up (auto-provisioned) |
| Wallet | Auto-created on sign-up, balance = 0 |
| Financial authority | Can request top-ups, can spend from own wallet |

**Permissions:**
- View own profile, wallet, ledger, check-in history
- Browse gyms on map
- Scan QR to check in
- Submit top-up requests with proof image
- Cannot modify wallet balance directly
- Cannot view other users' data

**Dashboard visibility:**
- Wallet balance (prominent)
- Recent transactions (last 10)
- Nearby gyms (map view)
- Check-in history
- Top-up request status

#### **Gym Owner (Service Provider)**

| Attribute | Value |
|---|---|
| Role enum value | `gym_owner` |
| Created via | Admin assigns role to existing user, or registration + admin approval |
| Wallet | Gym Wallet is per-partner entity, not per-user |
| Financial authority | View-only on gym wallet; cannot withdraw or adjust |

**Permissions:**
- Everything an Athlete can do (they are also users)
- View own partner entity and its locations
- View check-ins at own locations
- View gym wallet balance and transaction history (read-only)
- Generate/regenerate QR codes for own locations
- View analytics for own locations (earnings, visits)
- Update location details (name, address) — subject to admin approval if enabled
- Cannot create new partner entities (admin does this)
- Cannot modify pricing (admin does this)
- Cannot settle or withdraw funds

**Dashboard visibility:**
- Gym wallet balance (accumulated, unsettled)
- Today's check-ins count + revenue
- Total earnings (all-time / period)
- Per-location breakdown
- Settlement history (past payouts)
- QR management panel

#### **Admin**

| Attribute | Value |
|---|---|
| Role enum value | `admin` |
| Created via | Direct database assignment (no self-registration) |
| Wallet | Has personal wallet if also a user; has access to Platform Wallet |
| Financial authority | Full. Can credit/debit any wallet. Can settle gym wallets. |

**Permissions:**
- Full read access to all tables
- Create/edit/deactivate partners and locations
- Set pricing per location
- Approve/reject top-up requests
- Adjust any user wallet (credit/debit with reason)
- Freeze/unfreeze any user account
- Settle gym wallets (mark as paid)
- View platform wallet (commission accumulator)
- Export reports (CSV/PDF)
- View live statistics (DAU, revenue, check-ins)
- Assign/revoke roles
- Cannot delete ledger entries (immutable)
- Cannot backdate transactions

**Dashboard visibility:**
- Platform revenue (real-time)
- Pending top-up requests queue
- Active users count
- Today's check-ins system-wide
- Gym wallet balances pending settlement
- Fraud alerts / anomaly flags
- User management table
- Partner management table

### 2.2 Role Hierarchy

```
Admin > Gym Owner > Athlete
```

- A Gym Owner inherits all Athlete capabilities.
- An Admin inherits all Gym Owner capabilities.
- Role is stored in `profiles.role` as an enum.
- Role is checked server-side via `SECURITY DEFINER` functions to avoid RLS recursion.

---

## 3. Wallet System

### 3.1 Three-Wallet Architecture

| Wallet | Owner | Type | Purpose |
|---|---|---|---|
| **User Wallet** | Each athlete/user | Real balance | Holds topped-up SYP. Deducted on check-in. |
| **Gym Wallet** | Each partner (gym brand) | Ledger credit | Accumulates 80% of each check-in. Not withdrawable in-app. |
| **Platform Wallet** | System (singleton) | Ledger credit | Accumulates 20% commission. Not withdrawable in-app. |

### 3.2 Where Money Exists

| Wallet | Real Money? | Explanation |
|---|---|---|
| User Wallet | **Yes** — represents confirmed cash deposit | User gave real cash, admin verified, balance reflects real value owed to user. |
| Gym Wallet | **No** — ledger credit only | Represents money the platform owes the gym. No real funds held. Settlement happens outside the system. |
| Platform Wallet | **No** — ledger credit only | Represents platform's earned commission. Accounting entry only. |

### 3.3 Data Model

**User Wallet** (one per user, `wallets` table):
- `id` — UUID primary key
- `user_id` — FK to profiles, UNIQUE
- `balance` — current spendable balance (DECIMAL 15,2)
- `total_topup` — lifetime top-up amount (audit field)
- `total_spent` — lifetime spend amount (audit field)
- `currency` — default 'SYP'
- `updated_at` — last modification timestamp

**Gym Wallet** (`gym_wallets` table — NEW):
- `id` — UUID primary key
- `partner_id` — FK to partners, UNIQUE
- `balance` — accumulated unsettled earnings (DECIMAL 15,2)
- `total_earned` — lifetime earnings (audit field)
- `total_settled` — lifetime settled amount (audit field)
- `currency` — default 'SYP'
- `updated_at` — last modification timestamp

**Platform Wallet** (`platform_wallet` table — singleton row):
- `id` — UUID primary key (one row, hard-coded ID)
- `balance` — accumulated commission (DECIMAL 15,2)
- `total_earned` — lifetime platform commission (audit field)
- `currency` — default 'SYP'
- `updated_at` — last modification timestamp

### 3.4 Money Flow: Check-in Transaction

```
1. User scans QR → perform_checkin() called
2. user_price = CEIL((base_price / 0.80) / 500) × 500
3. platform_fee = user_price - base_price
4. Lock User Wallet (SELECT ... FOR UPDATE)
5. Verify balance >= user_price → else REJECT
6. Deduct user_price from User Wallet
7. Credit base_price to Gym Wallet
8. Credit platform_fee to Platform Wallet
9. Create checkin record with price snapshot
10. Create 3 ledger entries (user debit, gym credit, platform credit)
11. Return success + new balance
```

All steps 4–11 execute in a **single database transaction**. If any step fails, the entire transaction rolls back.

### 3.5 Money Flow: Top-Up

```
1. User submits top-up request (amount + proof image URL)
2. Request stored with status = 'pending'
3. Admin reviews in dashboard
4. Admin approves:
   a. Lock User Wallet
   b. Credit amount to User Wallet
   c. Create ledger entry (type = 'topup')
   d. Mark request as 'approved'
5. If Admin rejects:
   a. Mark request as 'rejected' with admin_notes
   b. No wallet change
```

### 3.6 Settlement Process

```
1. Admin views Gym Wallet balances in admin panel
2. Admin initiates settlement for a partner:
   a. Record settlement (partner_id, amount, period_start, period_end)
   b. Deduct amount from Gym Wallet balance
   c. Create ledger entry on gym ledger (type = 'settlement')
   d. Mark settlement as 'pending'
3. Admin pays gym owner via external channel (cash, bank transfer)
4. Admin marks settlement as 'paid' with transaction_ref
```

Settlements are **always initiated by Admin**. The gym owner has no withdraw button. They can only view settlement history.

### 3.7 Fraud Safety — Wallet Level

| Vector | Mitigation |
|---|---|
| Double-spend | `SELECT ... FOR UPDATE` row lock before any balance mutation |
| Negative balance | Check balance >= amount BEFORE deduction, within locked transaction |
| Race condition (concurrent check-ins) | Row-level lock ensures serial execution per user |
| Phantom top-up | Top-ups require admin approval; no self-service balance increase |
| Admin abuse | All admin wallet adjustments logged with `admin_id` in metadata |
| Overflow | DECIMAL(15,2) supports up to 9,999,999,999,999.99 |

---

## 4. Ledger Model

### 4.1 Design Philosophy

The ledger is the **immutable audit trail**. No row in the ledger is ever updated or deleted. Every financial event produces one or more ledger entries. The wallet balance is a **derived value** that can be reconstructed by summing all ledger entries for a given entity.

### 4.2 Ledger Entry Types

| Type | Direction | Description |
|---|---|---|
| `topup` | + (credit) | Admin-approved top-up to user wallet |
| `checkin_debit` | − (debit) | User wallet deducted for gym visit |
| `checkin_credit_gym` | + (credit) | Gym wallet credited (80% share) |
| `checkin_credit_platform` | + (credit) | Platform wallet credited (20% share) |
| `refund` | + (credit) | Reversal of a check-in charge to user |
| `refund_debit_gym` | − (debit) | Reversal of gym credit on refund |
| `refund_debit_platform` | − (debit) | Reversal of platform credit on refund |
| `adjustment` | +/− | Admin manual correction |
| `settlement` | − (debit) | Gym wallet reduced on payout |
| `bonus` | + (credit) | Promotional credit |

### 4.3 Ledger Table Structure

**Unified Ledger** (`wallet_ledger` table):
- `id` — UUID, PK
- `wallet_type` — ENUM: `user`, `gym`, `platform`
- `wallet_owner_id` — UUID (user_id for user wallets, partner_id for gym wallets, NULL for platform)
- `amount` — DECIMAL(15,2), positive or negative
- `type` — ledger entry type enum (from 4.2)
- `description` — human-readable Arabic description
- `reference_id` — UUID pointing to the source (checkin_id, topup_request_id, settlement_id)
- `reference_type` — TEXT: `checkin`, `topup`, `settlement`, `adjustment`, `refund`
- `balance_before` — DECIMAL(15,2) snapshot
- `balance_after` — DECIMAL(15,2) snapshot
- `metadata` — JSONB (admin_id, device_hash, IP, extra context)
- `idempotency_key` — TEXT, UNIQUE (prevents duplicate processing)
- `created_at` — TIMESTAMPTZ, immutable

### 4.4 Idempotency Strategy

Every financial operation generates an `idempotency_key` before execution:

| Operation | Key Format |
|---|---|
| Check-in | `checkin:{user_id}:{location_id}:{date}:{nonce}` |
| Top-up approval | `topup:{request_id}` |
| Settlement | `settlement:{partner_id}:{date}:{amount}` |
| Adjustment | `adjustment:{admin_id}:{user_id}:{timestamp_ms}` |

- The `idempotency_key` column has a UNIQUE constraint.
- If a duplicate key is inserted, the transaction is rejected.
- Client retries are safe: same key = same result (no double-spend).

### 4.5 Audit Logging

Every ledger entry automatically captures:
- `created_at` — server timestamp (not client-provided)
- `metadata.admin_id` — if action was admin-initiated
- `metadata.device_hash` — client device fingerprint
- `metadata.ip` — request origin (captured at Edge Function level)
- `metadata.app_version` — client app version

Ledger entries are **never deleted**. Corrections are made by adding a new compensating entry (e.g., `refund` to reverse a `checkin_debit`).

### 4.6 Anti Double-Spend

**Layer 1 — Row Lock:** `SELECT ... FOR UPDATE` on wallet row before any balance change.  
**Layer 2 — Idempotency Key:** UNIQUE constraint on `idempotency_key` prevents duplicate processing.  
**Layer 3 — Balance Snapshot:** `balance_before` and `balance_after` recorded on every entry; enables reconciliation.  
**Layer 4 — Atomic Transaction:** All mutations (wallet update + ledger insert + record creation) in a single PostgreSQL transaction.

---

## 5. Gym Model

### 5.1 Entity Hierarchy

```
Partner (Brand)
  └── Partner Location (Branch)
        └── QR Token (Entry Point)
```

- **Partner** = the gym brand (e.g., "Olympia Gym")
- **Partner Location** = a physical branch (e.g., "Olympia - Mazzeh")
- **QR Token** = the scannable code at the branch entrance

### 5.2 Gym Registration Flow

```
1. Admin creates Partner entity (name, description, logo)
2. Admin assigns an existing user as owner_id (changes their role to gym_owner)
3. Admin creates Partner Location(s) under the partner:
   - Name, address, GPS coordinates (lat/lng)
   - base_price (gym's share per check-in)
   - radius_m (geo-fence radius in meters, default 150m)
4. Admin or Gym Owner generates QR token for the location
5. Partner Location starts as is_active = true
6. Gym is now live and visible on user map
```

**Approval is always required.** No self-service gym registration. The admin vets every gym before it goes live.

### 5.3 Partner Table

- `id` — UUID, PK
- `owner_id` — FK to profiles (the gym owner user)
- `name` — TEXT, required
- `description` — TEXT
- `logo_url` — TEXT (storage bucket URL)
- `category` — TEXT (e.g., 'gym', 'pool', 'studio') — future-ready
- `is_active` — BOOLEAN (admin can deactivate)
- `created_at` — TIMESTAMPTZ

### 5.4 Partner Location Table

- `id` — UUID, PK
- `partner_id` — FK to partners
- `name` — TEXT (branch name)
- `address_text` — TEXT (human-readable address)
- `city` — TEXT (for multi-city filtering, default 'Damascus')
- `lat` — DOUBLE PRECISION
- `lng` — DOUBLE PRECISION
- `radius_m` — DOUBLE PRECISION (geo-fence radius, default 150)
- `base_price` — DECIMAL(12,2) (gym's share per check-in)
- `amenities` — TEXT[] (array: 'weights', 'cardio', 'pool', 'sauna', etc.)
- `operating_hours` — JSONB (e.g., `{"sun": {"open": "06:00", "close": "23:00"}, ...}`)
- `photos` — TEXT[] (array of storage URLs)
- `is_active` — BOOLEAN
- `created_at` — TIMESTAMPTZ

### 5.5 QR Generation Model

**Decision: Static QR with Token Rotation Capability**

| Aspect | Decision |
|---|---|
| QR Type | Static (printed, posted at entrance) |
| QR Content | Deterministic token string (e.g., `SP-A1B2C3D4E5F6`) |
| Rotation | Manual — gym owner or admin can regenerate, which invalidates the old token |
| Why not rotating? | Syria's infrastructure (intermittent internet at gym) makes server-synced rotating QR unreliable |
| Token format | `SP-` prefix + 12 uppercase hex characters |
| Storage | `qr_tokens` table, one active token per location at a time |

**QR Token Table:**
- `id` — UUID, PK
- `partner_location_id` — FK to partner_locations
- `token` — TEXT, UNIQUE
- `type` — TEXT: `static` (future: `rotating`)
- `is_active` — BOOLEAN
- `created_at` — TIMESTAMPTZ
- `expires_at` — TIMESTAMPTZ (NULL for static; used for future rotating tokens)

**Regeneration flow:**
1. Gym owner or admin calls `generate_qr_token(location_id)`
2. All existing tokens for that location are set to `is_active = false`
3. New token is generated and inserted
4. Gym owner prints new QR code from the app

### 5.6 Geo-Fence Validation

| Parameter | Value |
|---|---|
| Algorithm | Haversine distance formula |
| Default radius | 150 meters |
| Configurable | Yes, per location (`radius_m` field) |
| Minimum radius | 50 meters (enforced at application level) |
| Maximum radius | 500 meters (enforced at application level) |
| Execution | Server-side only (client GPS coordinates sent, never trusted for decision) |

**Geo-fence is a soft gate, not the sole gate.** Check-in requires BOTH valid QR token AND geo-fence pass. A user with the QR token but outside the radius is rejected. A user inside the radius but without the QR token cannot check in.

---

## 6. Check-in Flow

### 6.1 Happy Path (Step-by-Step)

```
Step 1: USER opens camera (QR scanner screen in app)
Step 2: App reads QR code → extracts token string (e.g., "SP-A1B2C3D4E5F6")
Step 3: App captures device GPS coordinates (lat, lng)
Step 4: App captures device_hash (fingerprint of device)
Step 5: App calls perform_checkin(location_id_from_token, lat, lng, qr_token, device_hash, idempotency_key)
Step 6: Server: Validate QR token → resolve to partner_location_id
Step 7: Server: Validate location is_active = true
Step 8: Server: Validate partner is_active = true
Step 9: Server: Validate geo-fence (haversine distance <= radius_m)
Step 10: Server: Calculate pricing (base_price, user_price, platform_fee)
Step 11: Server: Lock User Wallet (SELECT ... FOR UPDATE)
Step 12: Server: Verify balance >= user_price
Step 13: Server: Check idempotency_key not already used
Step 14: Server: Deduct user_price from User Wallet
Step 15: Server: Credit base_price to Gym Wallet
Step 16: Server: Credit platform_fee to Platform Wallet
Step 17: Server: Create checkin record (with price snapshot)
Step 18: Server: Create 3 ledger entries (user debit, gym credit, platform credit)
Step 19: Server: Return success JSON:
         {
           success: true,
           checkin_id: UUID,
           price_paid: user_price,
           gym_name: "Olympia - Mazzeh",
           new_balance: updated_balance
         }
Step 20: App: Show success animation + updated balance
```

### 6.2 Failure Cases

| Step | Failure | Response Code | User Message |
|---|---|---|---|
| 6 | QR token not found or inactive | `QR_INVALID` | "رمز QR غير صالح" |
| 7 | Location deactivated | `LOCATION_CLOSED` | "هذا الموقع مغلق حالياً" |
| 8 | Partner deactivated | `PARTNER_CLOSED` | "هذا النادي غير نشط" |
| 9 | Outside geo-fence | `GEO_FAIL` | "أنت بعيد عن الموقع (Xم)" |
| 12 | Insufficient balance | `LOW_BALANCE` | "رصيدك غير كافٍ. الكلفة: X ل.س" |
| 13 | Duplicate idempotency key | `DUPLICATE_REQUEST` | "تم تسجيل هذا الدخول مسبقاً" |
| — | User account frozen | `ACCOUNT_FROZEN` | "حسابك مجمد. تواصل مع الدعم" |
| — | Server error | `INTERNAL_ERROR` | "خطأ في النظام. حاول مجدداً" |

### 6.3 Race Conditions & Protections

| Scenario | Protection |
|---|---|
| Two concurrent check-ins from same user | `FOR UPDATE` lock on wallet row serializes them. Second one sees updated balance. |
| Same QR scanned twice rapidly | Idempotency key (contains user_id + location_id + date + nonce) prevents duplicate entry. |
| Network timeout → client retries | Client sends same idempotency_key → server returns existing result, no double charge. |
| GPS spoofing | Server-side geo-fence check. Future: device attestation. Current mitigation: device_hash logging for audit. |
| QR screenshot sharing | Geo-fence prevents remote use. User must be physically present. |

### 6.4 Replay Protection

- **Idempotency key**: Client generates a UUID-based nonce per scan attempt. Combined with user_id, location_id, and date to form the key.
- **Time window**: The same user cannot check in at the same location more than once per calendar day (optional business rule, configurable per location).
- **Token validation**: QR token must be active in database. Deactivated tokens are rejected.

---

## 7. Map System

### 7.1 Gym Display

All **active** partner locations appear on the map. Data source: `partner_locations` table joined with `partners`.

**Map pin data:**
- Location name
- Partner (brand) name
- GPS coordinates
- Logo URL
- base_price → displayed as user_price to user
- Distance from user (calculated client-side for sorting)

### 7.2 Filtering Logic

| Filter | Source | Type |
|---|---|---|
| City | `partner_locations.city` | Single select |
| Category | `partners.category` | Multi-select chips |
| Price range | `partner_locations.base_price` (displayed as user_price) | Slider / range |
| Name search | `partners.name`, `partner_locations.name` | Text, case-insensitive `ILIKE` |
| Amenities | `partner_locations.amenities` | Multi-select chips (array overlap) |
| Distance | Client-side calculation | Radius slider |

### 7.3 Availability & State

| State | Condition | Map Behavior |
|---|---|---|
| Active | `partner.is_active = true` AND `location.is_active = true` | Shown, full color pin |
| Partner inactive | `partner.is_active = false` | Hidden from map |
| Location inactive | `location.is_active = false` | Hidden from map |
| No active QR | No row in `qr_tokens` with `is_active = true` for location | Shown, but check-in will fail. Optional: grey pin. |
| Outside operating hours | Current time outside `operating_hours` | Shown with "Closed" badge. Check-in still allowed (gym's discretion). |

### 7.4 Data Loading Strategy

- **Initial load**: Fetch all active locations for the user's selected city. Paginate if > 100.
- **Refresh**: Pull-to-refresh or on city filter change.
- **Caching**: Cache locations locally for 15 minutes. Stale data is acceptable for map display.
- **Detail fetch**: On tap, fetch full partner + location details including photos, amenities, operating hours.

---

## 8. UI/UX Principles

### 8.1 Visual Identity

| Aspect | Direction |
|---|---|
| Primary palette | Deep navy (#0A1628) background, electric teal (#00E5A0) accents, white text |
| Secondary accents | Warm gold (#FFB800) for financial elements, soft gradients |
| Theme mode | Auto-detect system dark/light preference. Default: dark. |
| Typography | Arabic-first: Tajawal or Cairo for Arabic. Inter for Latin characters. |
| Shape language | Rounded corners (16px), card-based layouts, glassmorphism on overlays |
| Motion | Subtle micro-animations: balance counter rolls, check-in success pulse, card transitions |

### 8.2 Branding Direction

- **Middle Eastern athletic energy**: Clean, powerful, premium feel.
- **Not generic fintech**: Avoid banking UI patterns. This is a lifestyle app.
- **Trust signals**: Show balance prominently. Show ledger transparently. Every deduction explained.
- **Syrian market sensitivity**: RTL-first layout. Arabic as primary language. English as toggle.

### 8.3 Financial Transparency UI

| Element | Implementation |
|---|---|
| Balance display | Large, centered, always visible on home screen |
| Price at gym | Show user_price clearly BEFORE QR scan, on gym detail page |
| Post-check-in | Full receipt: gym name, base_price, platform_fee, user_price, new balance |
| Ledger view | Scrollable timeline of all transactions with type icons, amounts, timestamps |
| Top-up status | Color-coded: pending (yellow), approved (green), rejected (red) |

### 8.4 Key Screen Inventory

1. **Splash / Onboarding** — brand intro, language selection
2. **Auth** — phone number entry, OTP verification
3. **Home** — wallet balance, recent activity, quick actions
4. **Map** — full-screen gym map with filters
5. **Gym Detail** — photos, amenities, price, check-in button
6. **QR Scanner** — camera overlay, scan animation
7. **Check-in Result** — success/failure with details
8. **Wallet** — balance, top-up request form, transaction history
9. **Profile** — user info, settings, language toggle
10. **Gym Owner Dashboard** — earnings, check-ins, QR management
11. **Admin Dashboard** — full control panel (web or in-app)

---

## 9. Security Model

### 9.1 RLS Philosophy

Every table has Row Level Security enabled. No table is publicly readable without explicit policy.

| Principle | Implementation |
|---|---|
| Default deny | RLS enabled on all tables. No policy = no access. |
| Role check bypass | `has_role()` function is `SECURITY DEFINER` to avoid RLS recursion when checking profiles.role |
| User isolation | Users can only SELECT their own rows (wallets, ledger, checkins, topup_requests) |
| Public data | Partners and partner_locations are publicly readable (SELECT) for map display |
| Admin override | Admin policies use `has_role('admin')` and grant ALL operations |
| Gym owner scoping | Gym owners access only resources linked to their owned partners |
| Write restrictions | Ledger: no UPDATE, no DELETE policies for any role. INSERT only via SECURITY DEFINER functions. |

### 9.2 Admin Authority Limits

| Can Do | Cannot Do |
|---|---|
| Adjust any wallet balance (with reason) | Delete ledger entries |
| Freeze/unfreeze accounts | Backdate transactions |
| Approve/reject top-ups | Modify existing ledger entries |
| Create/edit partners and locations | Self-assign admin role (requires DB access) |
| Settle gym wallets | Access without authentication |
| Export reports | Bypass idempotency checks |

### 9.3 Fraud Vectors & Mitigations

| Vector | Risk Level | Mitigation |
|---|---|---|
| GPS spoofing | Medium | Geo-fence is server-side. Device hash logged for pattern detection. Future: device attestation API. |
| QR sharing (screenshot) | Medium | Geo-fence prevents remote use. Only works at physical location. |
| QR token brute force | Low | Token is 12 hex chars = 16^12 ≈ 281 trillion combinations. Rate limiting on check-in endpoint. |
| Replay attack | High | Idempotency key + per-user-per-location-per-day constraint. |
| Man-in-the-middle | Medium | All traffic over HTTPS. Supabase enforces TLS. |
| Admin collusion | Medium | All admin actions logged with admin_id. Secondary admin can audit. |
| Multi-device abuse | Low | Device hash tracked per check-in. Anomaly detection: same user, different devices, high frequency. |
| Fake top-up proofs | Medium | Admin manually verifies proof images. Future: integration with payment providers for auto-verification. |

### 9.4 Device Hash

- Generated client-side from device model, OS version, and a persistent random seed.
- Stored per-check-in in `checkins.metadata.device_hash`.
- Not used for blocking (unreliable), only for forensic audit.
- If a user checks in from 5+ different device hashes in a day → flag for admin review.

### 9.5 Request Idempotency

| Layer | Mechanism |
|---|---|
| Database | `idempotency_key` UNIQUE constraint on `wallet_ledger` |
| Application | Client generates idempotency key per user action (not per network request) |
| Edge Function | Checks for existing key before processing; returns cached result if found |
| Retry behavior | Client retries with same key → no side effects, same response returned |

### 9.6 Replay Attack Protection

```
Protection layers:
1. Idempotency key (prevents re-processing)
2. One check-in per user per location per day (optional business rule)
3. QR token validation (invalidated tokens rejected)
4. JWT expiration (short-lived auth tokens)
5. Server-side timestamp (no client timestamps trusted)
```

---

## 10. Admin Control Panel

### 10.1 Capabilities Matrix

| Category | Action | Details |
|---|---|---|
| **View** | User list | Paginated, searchable by name/phone. Shows role, status, wallet balance. |
| **View** | Gym list | All partners + locations. Shows owner, pricing, active status, wallet balance. |
| **View** | Check-in log | Global timeline of all check-ins. Filterable by date, user, gym, status. |
| **View** | Ledger entries | Full financial audit trail. Filterable by wallet type, entry type, date range. |
| **View** | Platform revenue | Total commission, daily/weekly/monthly breakdown. |
| **View** | Live statistics | DAU, check-ins today, revenue today, pending top-ups count. |
| **Modify** | User profile | Change name, phone, role, status. |
| **Modify** | Partner details | Name, description, logo, category, is_active. |
| **Modify** | Location details | Name, address, coordinates, pricing, radius, amenities, is_active. |
| **Approve** | Top-up requests | View proof, approve (credits wallet), reject (with reason). |
| **Approve** | Gym registration | Manually create partner + location + assign owner. |
| **Freeze** | User account | Set `profiles.status = 'frozen'`. User cannot check in or top up. |
| **Freeze** | Gym location | Set `partner_locations.is_active = false`. Removed from map, check-in fails. |
| **Freeze** | Entire partner | Set `partners.is_active = false`. All locations hidden. |
| **Adjust** | User wallet | Credit or debit with mandatory reason. Logged in ledger. |
| **Settle** | Gym wallet | Record payout. Deduct from gym wallet. Mark payment status. |
| **Export** | Reports | CSV export of: users, check-ins, ledger, settlements. Date range selectable. |

### 10.2 Admin Dashboard Widgets

1. **Revenue card** — today, this week, this month (platform commission)
2. **Pending queue** — number of pending top-up requests (clickable)
3. **Active users** — DAU counter
4. **Check-in feed** — real-time scrolling list of latest check-ins
5. **Gym balances** — sorted by highest unsettled balance (settlement priority)
6. **Alert panel** — flagged anomalies (high-frequency check-ins, device mismatches)

---

## 11. Scalability Model

### 11.1 Phase 1: Syria First

| Aspect | Decision |
|---|---|
| Region | Syria (Damascus primarily, expandable to other cities) |
| Currency | SYP |
| Language | Arabic (primary), English (secondary) |
| Payment | Cash via ShamCash or similar (manual verification) |
| Infrastructure | Supabase (managed PostgreSQL + Edge Functions + Auth) |
| App | Flutter mobile (Android priority, iOS secondary) |
| Admin panel | In-app for v1. Web dashboard for v2. |

### 11.2 Multi-Country Readiness

**Architecture decisions that enable multi-country expansion:**

| Component | How It Scales |
|---|---|
| Currency | `wallets.currency` field. Pricing stored per-location in local currency. |
| City | `partner_locations.city` field. Map filters by city. |
| Country | Add `partner_locations.country` field. Filter chain: country → city → location. |
| Language | Flutter l10n infrastructure already in place. Add locale files per language. |
| Commission rate | Add `commission_rate` to partner or location level (currently hardcoded 20%). |
| Payment methods | `topup_requests` model is payment-method-agnostic. Add `payment_method` field. |
| Time zone | All timestamps stored as UTC. Display converted client-side. |

### 11.3 Multi-Currency Readiness

| Rule | Implementation |
|---|---|
| Wallet is single-currency | Each wallet has one `currency` field. No cross-currency wallets. |
| Location price in local currency | `base_price` is always in the location's local currency. |
| No real-time conversion | Currency is country-bound. Users in Syria see SYP. Users in Lebanon see LBP. |
| Future: conversion layer | If cross-country check-in is needed, add a conversion service between wallet and location currency. Not in v1. |

### 11.4 Modular Financial Layer

The financial system is isolated behind well-defined function boundaries:

| Function | Responsibility | Touches |
|---|---|---|
| `perform_checkin()` | Full check-in transaction | User wallet, gym wallet, platform wallet, ledger, checkins |
| `approve_topup()` | Top-up approval flow | User wallet, ledger, topup_requests |
| `admin_adjust_wallet()` | Manual wallet correction | User wallet, ledger |
| `settle_gym_wallet()` | Gym payout recording | Gym wallet, ledger, settlements |
| `generate_qr_token()` | QR management | qr_tokens |

All financial mutations go through these SECURITY DEFINER functions. No direct table writes for financial data. This creates a clean API boundary that can be:
- Moved to a separate microservice
- Wrapped in an API gateway
- Replaced with a different database engine
- Audited at a single chokepoint

### 11.5 Performance Considerations

| Concern | Strategy |
|---|---|
| Hot wallet rows (high-frequency users) | Row-level locking is per-user. No global bottleneck. |
| Ledger growth | Partition by `created_at` (monthly). Index on `wallet_owner_id + created_at`. |
| Map query performance | Index on `partner_locations (city, is_active)`. Spatial index future option. |
| Check-in throughput | Each check-in is one DB transaction (~5ms). Supabase handles 1000+ concurrent connections. |
| Admin dashboard | Aggregate queries use materialized views or cached counters, not real-time full-table scans. |

---

## 12. Appendix: Entity Relationship Summary

### 12.1 Core Entities

```
auth.users (Supabase managed)
  │
  ├── profiles (1:1, user_id PK+FK)
  │     ├── role: athlete | gym_owner | admin
  │     └── status: active | frozen
  │
  ├── wallets (1:1, user_id UNIQUE FK)
  │     └── balance, currency
  │
  └── topup_requests (1:N, user_id FK)
        └── amount, proof_url, status

partners (gym brands)
  │
  ├── owner_id → profiles.user_id
  │
  ├── partner_locations (1:N)
  │     ├── GPS, pricing, geo-fence
  │     └── qr_tokens (1:N per location, 1 active)
  │
  └── gym_wallets (1:1, partner_id UNIQUE FK)
        └── balance, total_earned, total_settled

platform_wallet (singleton)
  └── balance, total_earned

checkins (N:1 to user, N:1 to location)
  └── price snapshot, status, geo data

wallet_ledger (unified, immutable)
  └── wallet_type, wallet_owner_id, amount, type, reference_id, idempotency_key

settlements (N:1 to partner)
  └── amount, period, status, transaction_ref
```

### 12.2 Index Strategy

| Table | Index | Purpose |
|---|---|---|
| `profiles` | PK on `user_id` | Auth lookup |
| `wallets` | UNIQUE on `user_id` | Fast wallet access |
| `wallet_ledger` | `(wallet_owner_id, created_at DESC)` | User transaction history |
| `wallet_ledger` | UNIQUE on `idempotency_key` | Double-spend prevention |
| `partner_locations` | `(city, is_active)` | Map filtering |
| `partner_locations` | `(partner_id)` | Partner detail page |
| `qr_tokens` | UNIQUE on `token` | QR scan lookup |
| `qr_tokens` | `(partner_location_id, is_active)` | Active token lookup |
| `checkins` | `(user_id, ts DESC)` | User check-in history |
| `checkins` | `(partner_location_id, ts DESC)` | Gym check-in history |
| `topup_requests` | `(status, created_at)` | Admin pending queue |
| `settlements` | `(partner_id, created_at DESC)` | Gym settlement history |

---

> **END OF ARCHITECTURE FREEZE V1**
>
> This document is the binding contract between product, architecture, and engineering.  
> All SQL schemas, Edge Functions, Flutter code, and admin panels must conform to this specification.  
> Any deviation requires a formal amendment and version bump to V1.1+.
