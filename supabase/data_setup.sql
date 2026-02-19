-- ==============================================================================
-- SPORTPASS DATA SETUP (TESTING ROLES)
-- ==============================================================================
-- Use this to quickly assign roles and link data for testing.
-- ==============================================================================

-- 1. VIEW CURRENT USERS (Find your phone numbers here)
-- SELECT phone, role, user_id FROM public.profiles;

-- 2. SETUP ADMIN (Already working, but for reference)
-- UPDATE public.profiles SET role = 'admin' WHERE phone = 'YOUR_ADMIN_PHONE';

-- 3. SETUP GYM OWNER
-- Replace 'OWNER_PHONE' with the phone you used for the gym owner account.
-- This links the owner to the sample "Olympia Gym" (ID: 11111111-1111-1111-1111-111111111111)
UPDATE public.profiles SET role = 'gym_owner' WHERE phone = 'OWNER_PHONE';

UPDATE public.partners 
SET owner_id = (SELECT user_id FROM public.profiles WHERE phone = 'OWNER_PHONE')
WHERE id = '11111111-1111-1111-1111-111111111111';

-- 4. SETUP ATHLETE (Give some balance to test)
-- Replace 'ATHLETE_PHONE' with the athlete's phone.
UPDATE public.profiles SET role = 'athlete' WHERE phone = 'ATHLETE_PHONE';

UPDATE public.wallets 
SET balance = 50000 
WHERE user_id = (SELECT user_id FROM public.profiles WHERE phone = 'ATHLETE_PHONE');

-- 5. VERIFY LINKING
-- SELECT p.name, pr.phone as owner_phone 
-- FROM public.partners p 
-- JOIN public.profiles pr ON p.owner_id = pr.user_id;

DO $$
BEGIN
  RAISE NOTICE 'Data setup complete! Perform a Hot Restart in the app to see the changes.';
END $$;
