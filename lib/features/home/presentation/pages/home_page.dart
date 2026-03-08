import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../partners/presentation/cubit/partners_cubit.dart';
import '../../../partners/domain/models/partner.dart';
import '../cubit/home_cubit.dart';

import '../../../admin/presentation/pages/admin_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _redirectingToOnboarding = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().refreshProfile();
    context.read<HomeCubit>().loadHomeData();
    context.read<WalletCubit>().loadWallet();
    context.read<PartnersCubit>().loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, authState) {
        if (authState is AuthRoleSelectionRequired) {
          if (!_redirectingToOnboarding) {
            _redirectingToOnboarding = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(AppRouter.onboarding);
              }
            });
          }
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: C.cyan),
            ),
          );
        }
        _redirectingToOnboarding = false;

        // Redirection based on Role
        if (authState is AuthAuthenticated) {
          if (authState.user.role == 'admin') {
            return const AdminDashboardPage();
          }
        }

        // Default Athlete View
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocBuilder<HomeCubit, HomeState>(
            builder: (ctx, homeState) {
              if (homeState is HomeLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: C.cyan));
              }
              if (homeState is HomeError) {
                final errorColor =
                    Theme.of(context).textTheme.bodyMedium?.color ??
                        const Color(0xFF4E6580);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(homeState.message,
                          style: GoogleFonts.cairo(color: errorColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<HomeCubit>().loadHomeData(),
                        child: Text(context.trd('إعادة المحاولة', 'Retry')),
                      ),
                    ],
                  ),
                );
              }
              if (homeState is HomeLoaded) {
                return RefreshIndicator(
                  color: C.cyan,
                  onRefresh: () async {
                    context.read<HomeCubit>().loadHomeData();
                    context.read<WalletCubit>().loadWallet();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildAppBar(context),
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildWalletCard(context)
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: 0.05),
                            const SizedBox(height: 16),
                            if (authState is AuthAuthenticated &&
                                authState.user.isGymOwnerPending)
                              _buildOwnerPendingBanner().animate().fadeIn(),
                            // Admin card removed as they have their own dashboard now
                            if (authState is AuthAuthenticated &&
                                authState.user.isAdmin)
                              _buildAdminCard(context)
                                  .animate()
                                  .fadeIn(delay: 200.ms),

                            const SizedBox(height: 8),
                            _buildCheckinButton(context)
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .scale(begin: const Offset(0.95, 0.95)),
                            const SizedBox(height: 18),
                            _buildEntryGymsSection(context)
                                .animate()
                                .fadeIn(delay: 360.ms),
                            const SizedBox(height: 32),
                            // Quick Actions for Athlete
                            _buildQuickActions(context)
                                .animate()
                                .fadeIn(delay: 400.ms),
                            const SizedBox(height: 24),
                            if (homeState.hasCheckedInToday)
                              _buildTodayStatus(context)
                                  .animate()
                                  .fadeIn(delay: 500.ms),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: BlocBuilder<AuthCubit, AuthState>(
        builder: (ctx, state) {
          String greeting = context.trd('مرحباً', 'Hello');
          if (state is AuthAuthenticated) {
            final name = state.user.name ?? context.trd('رياضي', 'Athlete');
            greeting = context.trd('أهلاً $name', 'Hi $name');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text(
                  context.trd(
                      'بطاقتك الرياضية الذكية', 'Your smart fitness pass'),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.8) ??
                        C.textMuted,
                  )),
            ],
          );
        },
      ),
      actions: [
        BlocBuilder<AuthCubit, AuthState>(
          builder: (ctx, state) {
            if (state is AuthAuthenticated && state.user.isAdmin) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.cyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: C.cyan, size: 20),
                ),
                onPressed: () => context.push(AppRouter.admin),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.75) ??
                C.textMuted,
          ),
          onPressed: () => _showLogout(context),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (ctx, state) {
        double balance = 0;
        if (state is WalletLoaded) balance = state.wallet.balance;
        final authState = context.read<AuthCubit>().state;
        final canTopup =
            authState is AuthAuthenticated && authState.user.role == 'athlete';

        return GlassCard(
          gradient: C.walletGradient,
          borderColor: C.cyan.withValues(alpha: 0.3),
          boxShadow: [
            BoxShadow(
                color: C.cyan.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
          onTap: () => context.go(AppRouter.wallet),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.trd('المحفظة', 'Wallet'),
                      style: GoogleFonts.cairo(
                          color: Colors.white70, fontSize: 14)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                            canTopup
                                ? context.trd('شحن', 'Top up')
                                : context.trd('عرض', 'View'),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBalance(
                  balance: balance,
                  includeCurrency: false,
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              const SizedBox(height: 4),
              Text(context.trd('ل.س جديدة', 'New SYP'),
                  style:
                      GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, state) {
        if (state is AuthAuthenticated && state.user.isAdmin) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              borderColor: C.purple.withValues(alpha: 0.4),
              gradient: C.purpleGradient,
              onTap: () => context.push(AppRouter.admin),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.trd('لوحة التحكم', 'Admin Dashboard'),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(
                            context.trd('إدارة النظام والمستخدمين',
                                'Manage users and system'),
                            style: GoogleFonts.cairo(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white60, size: 16),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOwnerPendingBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: C.gold.withValues(alpha: 0.5),
        gradient: LinearGradient(
          colors: [
            C.gold.withValues(alpha: 0.24),
            C.surface,
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: C.gold, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trd(
                      'طلب صاحب النادي قيد المراجعة',
                      'Gym owner request is under review',
                    ),
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.trd(
                      'سيتم تفعيل صلاحيات الإدارة بعد موافقة مدير النظام.',
                      'Owner permissions will be activated after admin approval.',
                    ),
                    style: GoogleFonts.cairo(
                      color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.86) ??
                          const Color(0xFF4E6580),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinButton(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(builder: (context, state) {
      return Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: C.cyanGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: C.cyan.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRouter.scanner),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 28, color: C.navy),
                  const SizedBox(width: 12),
                  Text(
                    context.trd('امسح QR للدخول', 'Scan QR to check in'),
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: C.navy),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? C.textSecondary;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, authState) {
        final role =
            authState is AuthAuthenticated ? authState.user.role : 'athlete';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.trd('إجراءات سريعة', 'Quick actions'),
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface)),
            const SizedBox(height: 12),
            if (role == 'gym_owner')
              Column(
                children: [
                  Row(
                    children: [
                      _quickAction(Icons.store, context.trd('ناديي', 'My gym'),
                          C.gold, () => context.go(AppRouter.myGym)),
                      const SizedBox(width: 12),
                      _quickAction(
                          Icons.qr_code_2,
                          context.trd('رموز QR', 'QR Codes'),
                          C.cyan,
                          () => context.push(AppRouter.qrGenerator)),
                      const SizedBox(width: 12),
                      _quickAction(
                          Icons.analytics,
                          context.trd('التحليلات', 'Analytics'),
                          C.green,
                          () => context.go(AppRouter.providerAnalytics)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _quickAction(
                          Icons.receipt_long,
                          context.trd('التسوية', 'Settlement'),
                          C.purple,
                          () => context.push(AppRouter.settlement)),
                      const SizedBox(width: 12),
                      _quickAction(
                          Icons.person_outline,
                          context.trd('حسابي', 'My account'),
                          secondary,
                          () => context.push(AppRouter.profile)),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      _quickAction(
                          Icons.account_balance_wallet,
                          context.trd('شحن رصيد', 'Top up'),
                          C.green,
                          () => context.go(AppRouter.wallet)),
                      const SizedBox(width: 12),
                      _quickAction(
                          Icons.map_outlined,
                          context.trd('الخريطة', 'Map'),
                          C.cyan,
                          () => context.go(AppRouter.map)),
                      const SizedBox(width: 12),
                      _quickAction(
                          Icons.person_outline,
                          context.trd('حسابي', 'My account'),
                          secondary,
                          () => context.push(AppRouter.profile)),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    final secondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? C.textSecondary;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderColor: color.withValues(alpha: 0.2),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.cairo(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryGymsSection(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? C.textSecondary;

    return BlocBuilder<PartnersCubit, PartnersState>(
      builder: (context, state) {
        if (state is! PartnersLoaded) {
          return const SizedBox.shrink();
        }

        final entries = _entryLocations(state.partners);
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.trd('نوادٍ جاهزة للدخول', 'Gyms ready to check in'),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRouter.map),
                  child: Text(
                    context.trd('عرض الكل', 'View all'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final point = entries[index];
                  final image = point.location.photos.isNotEmpty
                      ? point.location.photos.first
                      : null;
                  return SizedBox(
                    width: 250,
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () =>
                          context.push('/partners/${point.partner.id}'),
                      borderColor: C.cyan.withValues(alpha: 0.22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: image == null
                                ? Container(
                                    height: 88,
                                    color: C.surfaceAlt.withValues(alpha: 0.6),
                                    child: Center(
                                      child: Text(
                                        point.partner.categoryIcon,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    image,
                                    height: 88,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 88,
                                      color:
                                          C.surfaceAlt.withValues(alpha: 0.6),
                                      child: Center(
                                        child: Text(
                                          point.partner.categoryIcon,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            point.partner.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: onSurface,
                            ),
                          ),
                          Text(
                            point.location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              color: secondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatCurrency(
                                    context, point.location.userPrice),
                                style: GoogleFonts.cairo(
                                  color: C.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: () =>
                                    context.push(AppRouter.scanner),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: Text(
                                  context.trd('شيك إن', 'Check-in'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<_EntryLocation> _entryLocations(List<Partner> partners) {
    final output = <_EntryLocation>[];
    for (final partner in partners) {
      if (!partner.isActive) {
        continue;
      }
      for (final location in partner.locations) {
        if (!location.isActive) {
          continue;
        }
        output.add(_EntryLocation(partner: partner, location: location));
      }
    }
    return output.take(8).toList();
  }

  Widget _buildTodayStatus(BuildContext context) {
    return GlassCard(
      borderColor: C.green.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: C.green.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: C.green, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.trd('إنجاز اليوم! ✓', 'Today done! ✓'),
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: C.green)),
                Text(
                    context.trd('تم تسجيل دخولك. استمتع بتمرينك!',
                        'Check-in complete. Enjoy your workout!'),
                    style: GoogleFonts.cairo(
                        color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.8) ??
                            const Color(0xFF6D8199),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.trd('تسجيل الخروج', 'Logout'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text(context.trd('هل أنت متأكد؟', 'Are you sure?'),
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.trd('إلغاء', 'Cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              context.go(AppRouter.login);
            },
            child: Text(context.trd('تأكيد', 'Confirm')),
          ),
        ],
      ),
    );
  }
}

class _EntryLocation {
  final Partner partner;
  final PartnerLocation location;

  const _EntryLocation({
    required this.partner,
    required this.location,
  });
}
