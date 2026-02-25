import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key});
  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  bool _loading = true;
  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _checkins = [];
  double _totalEarned = 0;
  double _todayEarned = 0;
  int _todayCount = 0;
  String _tr(String ar, String en) => context.trd(ar, en);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // Get partner
      final partners = await sb
          .from('partners')
          .select('*, partner_locations(*)')
          .eq('owner_id', uid)
          .limit(1);
      if (partners.isEmpty) {
        setState(() {
          _loading = false;
          _partner = null;
        });
        return;
      }
      _partner = partners.first;

      // Get checkins for this partner's locations
      final locIds = (_partner!['partner_locations'] as List)
          .map((l) => l['id'] as String)
          .toList();
      if (locIds.isNotEmpty) {
        _checkins = await sb
            .from('checkins')
            .select('*, partner_locations(name)')
            .inFilter('partner_location_id', locIds)
            .order('created_at', ascending: false)
            .limit(50);

        _totalEarned = _checkins.fold(0.0,
            (sum, c) => sum + ((c['base_price'] as num?)?.toDouble() ?? 0));

        final today = DateTime.now();
        final todayCheckins = _checkins.where((c) {
          final ts = DateTime.tryParse(c['created_at'] ?? '');
          return ts != null &&
              ts.year == today.year &&
              ts.month == today.month &&
              ts.day == today.day;
        }).toList();
        _todayCount = todayCheckins.length;
        _todayEarned = todayCheckins.fold(0.0,
            (sum, c) => sum + ((c['base_price'] as num?)?.toDouble() ?? 0));
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(_tr('لوحة تحكم النادي', 'Gym dashboard'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: C.red),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(AppRouter.login);
            },
            tooltip: _tr('تسجيل الخروج', 'Logout'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : _partner == null
              ? _buildNoGym()
              : RefreshIndicator(
                  color: C.cyan,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildWelcomeCard().animate().fadeIn(),
                      const SizedBox(height: 16),
                      _buildStatsRow().animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),
                      _buildEarningsChart().animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 20),
                      _buildRecentCheckins().animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoGym() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory, size: 80, color: C.gold),
            const SizedBox(height: 20),
            Text(_tr('لم تُنشئ ملف نادي بعد', 'No gym profile created yet'),
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: C.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _tr(
                'أنشئ ملف النادي ثم أضف الفروع ليتم اعتمادها من الإدارة.',
                'Create your gym profile, then add branches for admin approval.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: C.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRouter.gymSetup),
              icon: const Icon(Icons.storefront),
              label: Text(
                _tr('إنشاء نادي', 'Create gym'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(_tr('تحديث', 'Refresh'),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: C.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: C.gold.withValues(alpha: 0.2), blurRadius: 20)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_partner?['name'] ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                    _tr('عمولة المنصة: 80/20 (ثابتة)',
                        'Platform split: 80/20 (fixed)'),
                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                Text(
                    '${(_partner?['partner_locations'] as List?)?.length ?? 0} ${_tr('فروع', 'branches')}',
                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.store, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(_tr('اليوم', 'Today'), '$_todayCount', _tr('زيارة', 'visits'),
            C.cyan),
        const SizedBox(width: 12),
        _statCard(_tr('أرباح اليوم', 'Today earnings'),
            formatCurrency(context, _todayEarned), '', C.green),
        const SizedBox(width: 12),
        _statCard(_tr('الإجمالي', 'Total'),
            formatCurrency(context, _totalEarned), '', C.gold),
      ],
    );
  }

  Widget _statCard(String label, String value, String suffix, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (suffix.isNotEmpty)
              Text(suffix,
                  style: GoogleFonts.cairo(
                      color: color.withValues(alpha: 0.7), fontSize: 11)),
            Text(label,
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart() {
    // Group checkins by date for last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dailyEarnings = days.map((d) {
      final earned = _checkins.where((c) {
        final ts = DateTime.tryParse(c['created_at'] ?? '');
        return ts != null &&
            ts.year == d.year &&
            ts.month == d.month &&
            ts.day == d.day;
      }).fold<double>(
          0, (sum, c) => sum + ((c['base_price'] as num?)?.toDouble() ?? 0));
      return earned;
    }).toList();

    final maxY = dailyEarnings.reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tr('أرباح آخر 7 أيام', 'Earnings in last 7 days'),
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary,
                  fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY > 0 ? maxY * 1.2 : 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat(
                            'E',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(days[idx]),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: dailyEarnings[i],
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            gradient: C.greenGradient,
                          ),
                        ])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckins() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('آخر الزيارات', 'Recent check-ins'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: C.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 12),
        if (_checkins.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_tr('لا توجد زيارات بعد', 'No visits yet'),
                style: GoogleFonts.cairo(color: C.textMuted)),
          )),
        ..._checkins.take(10).map((c) {
          final locName = (c['partner_locations'] as Map?)?['name'] ?? '';
          final ts = DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now();
          final earned = (c['base_price'] as num?)?.toDouble() ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check, color: C.green, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locName,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: C.textPrimary,
                              fontSize: 13)),
                      Text(
                          DateFormat(
                            'yyyy/MM/dd HH:mm',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(ts),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text('+${formatCurrency(context, earned)}',
                    style: GoogleFonts.cairo(
                        color: C.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
