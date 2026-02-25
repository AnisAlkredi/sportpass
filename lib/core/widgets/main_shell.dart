import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../theme/colors.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// Role-aware navigation shell — different tabs for athlete, gym_owner, admin
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, state) {
        final role = state is AuthAuthenticated ? state.user.role : 'athlete';
        final destinations = _buildDestinations(context, role);
        final routes = _buildRoutes(role);

        return Scaffold(
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: C.surface,
              border: Border(
                  top: BorderSide(color: C.border.withValues(alpha: 0.5))),
            ),
            child: NavigationBar(
              selectedIndex: _index(context, routes),
              onDestinationSelected: (i) {
                final route = routes[i];
                if (route == AppRouter.scanner) {
                  context.push(route);
                  return;
                }
                context.go(route);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 72,
              indicatorColor: C.cyan.withValues(alpha: 0.15),
              destinations: destinations,
            ),
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildDestinations(
      BuildContext context, String role) {
    switch (role) {
      case 'gym_owner':
        return [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: context.trd('الرئيسية', 'Home')),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: context.trd('ناديي', 'My gym')),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: context.trd('الإيرادات', 'Revenue')),
          NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: context.trd('التحليلات', 'Analytics')),
        ];
      case 'admin':
        return [
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: context.trd('التحكم', 'Control')),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: context.trd('المراكز', 'Gyms')),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: context.trd('المحفظة', 'Wallet')),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: context.trd('المستخدمين', 'Users')),
        ];
      case 'athlete':
      case 'gym_owner_pending':
      default:
        return [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: context.trd('الرئيسية', 'Home')),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: context.trd('الخريطة', 'Map')),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
              label: ''),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: context.trd('المحفظة', 'Wallet')),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: context.trd('السجل', 'Activity')),
        ];
    }
  }

  List<String> _buildRoutes(String role) {
    switch (role) {
      case 'gym_owner':
        return [
          AppRouter.home,
          AppRouter.myGym,
          AppRouter.wallet,
          AppRouter.providerAnalytics
        ];
      case 'admin':
        return [
          AppRouter.home,
          AppRouter.partners,
          AppRouter.wallet,
          AppRouter.checkinMonitor
        ]; // Changed last to checkin monitor
      case 'athlete':
      case 'gym_owner_pending':
      default:
        return [
          AppRouter.home,
          AppRouter.map,
          AppRouter.scanner,
          AppRouter.wallet,
          AppRouter.activity
        ];
    }
  }

  int _index(BuildContext context, List<String> routes) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = routes.indexOf(loc);
    return idx >= 0 ? idx : 0;
  }
}
