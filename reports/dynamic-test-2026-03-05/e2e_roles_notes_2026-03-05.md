# SportPass E2E Roles Test (Emulator)
Date: 2026-03-05
Device: emulator-5554 (Android 16)

## Summary
- `athlete_e2e_user` (athlete.e2e.1772617386.646@sportpass.app): login=PASS, navigation=1/5 taps
- `gym_owner_admin_sportpass` (Admin@sportpass.app): login=PASS, navigation=4/5 taps
- `admin_anis_sport` (anis@sport.com): login=PASS, navigation=4/5 taps

## Detailed Results
### athlete_e2e_user
- Email: `athlete.e2e.1772617386.646@sportpass.app`
- Login: PASS (ok)
- First visible labels after login:
  - Welcome to SportPass
  - The first smart fitness network in Syria
Enter any gym — scan QR — train
  - Scan QR
  - Digital wallet
  - Multiple gyms
  - Continue
- Navigation actions:
  - MISS: `Home` not found in current UI tree
  - MISS: `Map` not found in current UI tree
  - PASS: `Wallet` tapped at (531,1595)
  - MISS: `Activity` not found in current UI tree
  - MISS: `Scan QR to check in` not found in current UI tree
- Video: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/athlete_e2e_user.mp4`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/athlete_e2e_user_01_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/athlete_e2e_user_02_after_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/athlete_e2e_user_03_after_nav.png`

### gym_owner_admin_sportpass
- Email: `Admin@sportpass.app`
- Login: PASS (ok)
- First visible labels after login:
  - Hi admin
Your smart fitness pass
  - Wallet
View
0
New SYP
  - Scan QR to check in
  - Gyms ready to check in
  - View all
  - 🏋️
النادي العالمي
فرع 1
10,000 SYP (new)
  - Check-in
  - 🏋️
النادي العالمي
المهاجرين
10,000 SYP (new)
  - Quick actions
  - My gym
  - QR Codes
  - Analytics
- Navigation actions:
  - PASS: `Home` tapped at (135,2237)
  - PASS: `My gym` tapped at (405,2237)
  - PASS: `Revenue` tapped at (675,2237)
  - PASS: `Analytics` tapped at (945,2237)
  - MISS: `QR Codes` not found in current UI tree
- Video: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/gym_owner_admin_sportpass.mp4`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/gym_owner_admin_sportpass_01_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/gym_owner_admin_sportpass_02_after_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/gym_owner_admin_sportpass_03_after_nav.png`

### admin_anis_sport
- Email: `anis@sport.com`
- Login: PASS (ok)
- First visible labels after login:
  - Admin dashboard
  - Visit monitor
  - Logout
  - Payments
Tab 1 of 3
  - Gyms
Tab 2 of 3
  - Users
Tab 3 of 3
  - Control
Tab 1 of 4
  - Gyms
Tab 2 of 4
  - Wallet
Tab 3 of 4
  - Users
Tab 4 of 4
- Navigation actions:
  - PASS: `Control` tapped at (135,2237)
  - PASS: `Gyms` tapped at (405,2237)
  - PASS: `Wallet` tapped at (675,2237)
  - PASS: `Users` tapped at (945,2237)
  - MISS: `Payments` not found in current UI tree
- Video: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/admin_anis_sport.mp4`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/admin_anis_sport_01_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/admin_anis_sport_02_after_login.png`
- Screenshot: `/home/programming/Downloads/SportPass_v2/reports/dynamic-test-2026-03-05/admin_anis_sport_03_after_nav.png`

## Stability / Logs
- No `FATAL EXCEPTION` detected for `com.sportpass.app`.
- No `ANR in com.sportpass.app` detected.
- No Flutter assertion/stack overflow in this run.
- Observed warnings are emulator/runtime-level only (x86 variant, `max_map_count` SELinux read, `userfaultfd`).

## Notes
- Athlete scenario lands on onboarding/intro state ("Welcome to SportPass") after login, so bottom nav targets are not yet present unless pressing `Continue`.
- Admin and Gym Owner bottom navigation is discoverable and tappable reliably.
- Header tabs like `Payments`/`QR Codes` were context-dependent and not always exposed as separate tappable nodes in the captured state.