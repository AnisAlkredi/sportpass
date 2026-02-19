import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class ProviderAnalyticsPage extends StatefulWidget {
  const ProviderAnalyticsPage({super.key});
  @override
  State<ProviderAnalyticsPage> createState() => _ProviderAnalyticsPageState();
}

class _ProviderAnalyticsPageState extends State<ProviderAnalyticsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _checkins = [];
  double _gross = 0, _commission = 0, _net = 0;

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
      final partners = await sb
          .from('partners')
          .select('*, partner_locations(id)')
          .eq('owner_id', uid);
      if (partners.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final locIds = (partners.first['partner_locations'] as List)
          .map((l) => l['id'] as String)
          .toList();
      if (locIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      _checkins = await sb
          .from('checkins')
          .select()
          .inFilter('partner_location_id', locIds)
          .order('created_at', ascending: false);
      _gross = _checkins.fold(
          0.0, (s, c) => s + ((c['final_price'] as num?)?.toDouble() ?? 0));
      _commission = _checkins.fold(
          0.0, (s, c) => s + ((c['platform_fee'] as num?)?.toDouble() ?? 0));
      _net = _checkins.fold(
          0.0, (s, c) => s + ((c['base_price'] as num?)?.toDouble() ?? 0));
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
          title: Text('التحليلات والتسوية',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: C.bg),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                    gradient: C.walletGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقرير التسوية',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _row('إجمالي المدفوعات', formatSYP(_gross),
                            Colors.white),
                        const Divider(color: Colors.white30),
                        _row('عمولة المنصة (20%)',
                            '- ${formatSYP(_commission)}', C.red),
                        const Divider(color: Colors.white30),
                        _row('صافي أرباحك', formatSYP(_net), C.green),
                        const SizedBox(height: 8),
                        _row('عدد الزيارات', '${_checkins.length}', C.cyan),
                      ],
                    )).animate().fadeIn(),
                const SizedBox(height: 20),
                GlassCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ساعات الذروة',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            color: C.textPrimary,
                            fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                        height: 150,
                        child: BarChart(BarChartData(
                          maxY: _maxH() * 1.2,
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
                                    getTitlesWidget: (v, _) => Text(
                                        '${v.toInt()}',
                                        style: GoogleFonts.cairo(
                                            color: C.textMuted, fontSize: 9)))),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(24, (h) {
                            final c = _hc()[h]?.toDouble() ?? 0;
                            return BarChartGroupData(x: h, barRods: [
                              BarChartRodData(
                                  toY: c,
                                  width: 8,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                  gradient: c > 0 ? C.cyanGradient : null,
                                  color: c > 0 ? null : C.surfaceAlt)
                            ]);
                          }),
                        ))),
                  ],
                )).animate().fadeIn(delay: 200.ms),
              ],
            ),
    );
  }

  Widget _row(String l, String v, Color c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
        Text(v,
            style: GoogleFonts.cairo(
                color: c, fontSize: 14, fontWeight: FontWeight.w700))
      ]));
  Map<int, int> _hc() {
    final m = <int, int>{};
    for (final c in _checkins) {
      final ts = DateTime.tryParse(c['created_at'] ?? '');
      if (ts != null) m[ts.hour] = (m[ts.hour] ?? 0) + 1;
    }
    return m;
  }

  double _maxH() {
    final m = _hc();
    return m.isEmpty ? 1 : m.values.reduce((a, b) => a > b ? a : b).toDouble();
  }
}
