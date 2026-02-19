import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/partners/presentation/pages/partners_list_page.dart';
import '../../features/partners/presentation/pages/partner_details_page.dart';
import '../../features/checkin/presentation/pages/qr_scanner_page.dart';
import '../../features/checkin/presentation/pages/checkin_result_page.dart';
import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/topup_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard.dart';
import '../../features/admin/presentation/pages/user_detail_page.dart';
import '../../features/admin/presentation/pages/checkin_monitor_page.dart';
import '../../features/map/presentation/pages/map_discovery_page.dart';
import '../../features/provider/presentation/pages/gym_setup_page.dart';
import '../../features/provider/presentation/pages/add_location_page.dart';
import '../../features/provider/presentation/pages/qr_generator_page.dart';
import '../../features/provider/presentation/pages/provider_dashboard_page.dart';
import '../../features/provider/presentation/pages/provider_analytics_page.dart';
import '../../features/provider/presentation/pages/my_gym_page.dart';
import '../../features/provider/presentation/pages/settlement_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/main_shell.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/';
  static const String partners = '/partners';
  static const String partnerDetails = '/partners/:id';
  static const String scanner = '/scanner';
  static const String checkinResult = '/checkin-result';
  static const String activity = '/activity';
  static const String wallet = '/wallet';
  static const String topup = '/topup';
  static const String admin = '/admin';
  // Sprint 1 routes
  static const String map = '/map';
  static const String gymSetup = '/gym-setup';
  static const String addLocation = '/add-location';
  static const String qrGenerator = '/qr-generator';
  static const String myGym = '/my-gym';
  static const String providerDashboard = '/provider-dashboard';
  static const String providerAnalytics = '/provider-analytics';
  // Sprint 2 routes
  static const String onboarding = '/onboarding';
  static const String userDetail = '/admin/user/:id';
  static const String checkinMonitor = '/admin/checkin-monitor';
  static const String settlement = '/settlement';
  static const String profile = '/profile';

  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: home,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentUser != null;
      final onAuth = state.matchedLocation == login ||
          state.matchedLocation == otp ||
          state.matchedLocation == onboarding;
      if (!loggedIn && !onAuth) return login;
      if (loggedIn && state.matchedLocation == login) return home;
      return null;
    },
    routes: [
      GoRoute(
          path: login, name: 'login', builder: (_, __) => const LoginPage()),
      GoRoute(
          path: onboarding,
          name: 'onboarding',
          builder: (_, __) => const OnboardingPage()),
      GoRoute(
          path: otp,
          name: 'otp',
          builder: (_, state) =>
              OtpPage(phoneNumber: state.extra as String? ?? '')),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: home,
              name: 'home',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HomePage())),
          GoRoute(
              path: partners,
              name: 'partners',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: PartnersListPage())),
          GoRoute(
              path: wallet,
              name: 'wallet',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: WalletPage())),
          GoRoute(
              path: activity,
              name: 'activity',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ActivityPage())),
          GoRoute(
              path: map,
              name: 'map',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: MapDiscoveryPage())),
          GoRoute(
              path: myGym,
              name: 'myGym',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: MyGymPage())),
          GoRoute(
              path: admin,
              name: 'admin',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: AdminDashboardPage())),
          GoRoute(
              path: providerAnalytics,
              name: 'providerAnalytics',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ProviderAnalyticsPage())),
        ],
      ),
      GoRoute(
          path: partnerDetails,
          name: 'partnerDetails',
          builder: (_, state) =>
              PartnerDetailsPage(partnerId: state.pathParameters['id']!)),
      GoRoute(
          path: scanner,
          name: 'scanner',
          builder: (_, __) => const QrScannerPage()),
      GoRoute(
        path: topup,
        name: 'topup',
        builder: (_, state) {
          final extra = state.extra;
          double? amount;
          if (extra is num) {
            amount = extra.toDouble();
          } else if (extra is Map<String, dynamic>) {
            amount = (extra['amount'] as num?)?.toDouble();
          }
          return TopupPage(amount: amount);
        },
      ),
      GoRoute(
          path: checkinResult,
          name: 'checkinResult',
          builder: (_, state) => CheckinResultPage(
              result: state.extra as Map<String, dynamic>? ?? {})),
      GoRoute(
          path: gymSetup,
          name: 'gymSetup',
          builder: (_, __) => const GymSetupPage()),
      GoRoute(
          path: addLocation,
          name: 'addLocation',
          builder: (_, state) =>
              AddLocationPage(partnerId: state.extra as String? ?? '')),
      GoRoute(
          path: qrGenerator,
          name: 'qrGenerator',
          builder: (_, state) =>
              QrGeneratorPage(partnerId: state.extra as String? ?? '')),
      GoRoute(
          path: providerDashboard,
          name: 'providerDashboard',
          builder: (_, __) => const ProviderDashboardPage()),
      // Sprint 2 routes
      GoRoute(
          path: userDetail,
          name: 'userDetail',
          builder: (_, state) =>
              UserDetailPage(userId: state.pathParameters['id']!)),
      GoRoute(
          path: checkinMonitor,
          name: 'checkinMonitor',
          builder: (_, __) => const CheckinMonitorPage()),
      GoRoute(
          path: settlement,
          name: 'settlement',
          builder: (_, __) => const SettlementPage()),
      GoRoute(
          path: profile,
          name: 'profile',
          builder: (_, __) => const ProfilePage()),
    ],
  );
}
