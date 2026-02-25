import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key});
  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  bool _loading = true;
  String? _partnerId;
  double _gross = 0, _commission = 0, _net = 0;
  int _checkinCount = 0;
  List<Map<String, dynamic>> _weeklyBreakdown = [];
  DateTimeRange? _dateRange;
  String _tr(String ar, String en) => context.trd(ar, en);

  @override
  void initState() {
    super.initState();
    // Default last 30 days
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final partners = await sb
          .from('partners')
          .select('id, partner_locations(id)')
          .eq('owner_id', uid)
          .limit(1);
      if (partners.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      _partnerId = partners.first['id'];
      final locIds = (partners.first['partner_locations'] as List)
          .map((l) => l['id'] as String)
          .toList();
      if (locIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final checkins = await sb
          .from('checkins')
          .select()
          .inFilter('partner_location_id', locIds)
          .gte('created_at', _dateRange!.start.toIso8601String())
          .lte('created_at',
              _dateRange!.end.add(const Duration(days: 1)).toIso8601String())
          .order('created_at', ascending: false);

      _gross = 0;
      _commission = 0;
      _net = 0;
      _checkinCount = checkins.length;
      final weekMap = <String, Map<String, double>>{};

      for (final c in checkins) {
        final amount = (c['final_price'] as num?)?.toDouble() ?? 0;
        final comm = (c['platform_fee'] as num?)?.toDouble() ?? 0;
        final earned = (c['base_price'] as num?)?.toDouble() ?? 0;
        _gross += amount;
        _commission += comm;
        _net += earned;

        final ts = DateTime.tryParse(c['created_at'] ?? '');
        if (ts != null) {
          final weekStart = ts.subtract(Duration(days: ts.weekday % 7));
          final key = DateFormat('MM/dd').format(weekStart);
          weekMap.putIfAbsent(
              key, () => {'gross': 0, 'commission': 0, 'net': 0, 'count': 0});
          weekMap[key]!['gross'] = (weekMap[key]!['gross'] ?? 0) + amount;
          weekMap[key]!['commission'] =
              (weekMap[key]!['commission'] ?? 0) + comm;
          weekMap[key]!['net'] = (weekMap[key]!['net'] ?? 0) + earned;
          weekMap[key]!['count'] = (weekMap[key]!['count'] ?? 0) + 1;
        }
      }

      _weeklyBreakdown = weekMap.entries
          .map((e) => {
                'week': e.key,
                ...e.value,
              })
          .toList()
        ..sort((a, b) => (b['week'] as String).compareTo(a['week'] as String));

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: C.cyan,
            onPrimary: Colors.white,
            surface: C.surface,
            onSurface: C.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateRange = picked;
      _loadData();
    }
  }

  Future<void> _requestSettlement() async {
    if (_net <= 0 || _partnerId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_tr('طلب تسوية', 'Request settlement'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, color: C.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _tr('هل أنت متأكد من طلب تسوية المبلغ التالي؟',
                    'Are you sure you want to request settlement for this amount?'),
                style: GoogleFonts.cairo(color: C.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_tr('المبلغ الصافي:', 'Net amount:'),
                    style: GoogleFonts.cairo(color: C.textMuted)),
                Text(formatCurrency(context, _net),
                    style: GoogleFonts.cairo(
                        color: C.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ],
            ),
            const Divider(color: C.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_tr('عدد الزيارات:', 'Visit count:'),
                    style: GoogleFonts.cairo(color: C.textMuted)),
                Text('$_checkinCount',
                    style: GoogleFonts.cairo(
                        color: C.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('إلغاء', 'Cancel'), style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: C.green),
            child: Text(_tr('طلب التسوية', 'Request settlement'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('settlements').insert({
        'partner_id': _partnerId,
        'period_start': _dateRange!.start.toIso8601String().split('T').first,
        'period_end': _dateRange!.end.toIso8601String().split('T').first,
        'amount': _net,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _tr('تم إرسال طلب التسوية بنجاح',
                      'Settlement request submitted successfully'),
                  style: GoogleFonts.cairo()),
              backgroundColor: C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_tr('خطأ: $e', 'Error: $e'), style: GoogleFonts.cairo()),
              backgroundColor: C.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(_tr('التسوية المالية', 'Settlement'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: C.cyan),
            onPressed: _pickDateRange,
            tooltip: _tr('تحديد الفترة', 'Select period'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Date range display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.date_range, size: 16, color: C.cyan),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('yyyy/MM/dd', AppLocalizations.of(context).isEnglish ? 'en' : 'ar').format(_dateRange!.start)} → ${DateFormat('yyyy/MM/dd', AppLocalizations.of(context).isEnglish ? 'en' : 'ar').format(_dateRange!.end)}',
                        style: GoogleFonts.cairo(
                            color: C.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 16),

                // Summary card
                GlassCard(
                  gradient: C.walletGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr('ملخص التسوية', 'Settlement summary'),
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      _summaryRow(_tr('إجمالي المدخول', 'Total revenue'),
                          formatCurrency(context, _gross), Colors.white),
                      const Divider(color: Colors.white24, height: 20),
                      _summaryRow(
                          _tr('عمولة المنصة (20%)', 'Platform fee (20%)'),
                          '- ${formatCurrency(context, _commission)}',
                          C.red),
                      const Divider(color: Colors.white24, height: 20),
                      _summaryRow(_tr('صافي المستحقات', 'Net payable'),
                          formatCurrency(context, _net), C.green),
                      const Divider(color: Colors.white24, height: 20),
                      _summaryRow(_tr('عدد الزيارات', 'Visit count'),
                          '$_checkinCount', C.cyan),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // Request settlement button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _net > 0 ? _requestSettlement : null,
                    icon: const Icon(Icons.send),
                    label: Text(_tr('طلب تسوية', 'Request settlement'),
                        style: GoogleFonts.cairo(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.green,
                      disabledBackgroundColor: C.surfaceAlt,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Weekly breakdown
                Text(_tr('تفصيل أسبوعي', 'Weekly breakdown'),
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: C.textPrimary,
                        fontSize: 16)),
                const SizedBox(height: 12),

                if (_weeklyBreakdown.isEmpty)
                  Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        _tr('لا توجد بيانات في هذه الفترة',
                            'No data in this period'),
                        style: GoogleFonts.cairo(color: C.textMuted)),
                  )),

                ..._weeklyBreakdown.asMap().entries.map((entry) {
                  final w = entry.value;
                  final i = entry.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: C.border.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_tr('أسبوع', 'Week')} ${w['week']}',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                    color: C.textPrimary)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: C.cyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                  '${(w['count'] as double).toInt()} ${_tr('زيارة', 'visits')}',
                                  style: GoogleFonts.cairo(
                                      color: C.cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _miniInfo(
                                    _tr('إجمالي', 'Total'),
                                    formatCurrency(
                                        context, w['gross'] as double),
                                    C.textSecondary)),
                            Expanded(
                                child: _miniInfo(
                                    _tr('عمولة', 'Fee'),
                                    formatCurrency(
                                        context, w['commission'] as double),
                                    C.red)),
                            Expanded(
                                child: _miniInfo(
                                    _tr('صافي', 'Net'),
                                    formatCurrency(context, w['net'] as double),
                                    C.green)),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 300 + i * 80));
                }),
              ],
            ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.cairo(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label, style: GoogleFonts.cairo(color: C.textMuted, fontSize: 10)),
      ],
    );
  }
}
