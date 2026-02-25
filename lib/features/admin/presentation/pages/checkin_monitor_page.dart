import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class CheckinMonitorPage extends StatefulWidget {
  const CheckinMonitorPage({super.key});
  @override
  State<CheckinMonitorPage> createState() => _CheckinMonitorPageState();
}

class _CheckinMonitorPageState extends State<CheckinMonitorPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _checkins = [];
  String _filter = 'all'; // all, approved, rejected
  String _tr(String ar, String en) => context.trd(ar, en);

  @override
  void initState() {
    super.initState();
    _loadCheckins();
  }

  Future<void> _loadCheckins() async {
    setState(() => _loading = true);
    final sb = Supabase.instance.client;
    try {
      var query = sb.from('checkins').select(
          '*, partner_locations(name, partner_id), profiles!checkins_user_id_fkey(name, phone)');
      if (_filter != 'all') {
        query = query.eq('status', _filter);
      }
      _checkins = List<Map<String, dynamic>>.from(
        await query.order('created_at', ascending: false).limit(100),
      );
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _exitPage() {
    if (!mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayCheckins = _checkins.where((c) {
      final ts = DateTime.tryParse(c['created_at'] ?? '');
      final today = DateTime.now();
      return ts != null &&
          ts.year == today.year &&
          ts.month == today.month &&
          ts.day == today.day;
    }).toList();

    final totalRevenue = _checkins
        .where((c) => c['status'] == 'approved')
        .fold<double>(
            0, (s, c) => s + ((c['final_price'] as num?)?.toDouble() ?? 0));
    final totalCommission = _checkins
        .where((c) => c['status'] == 'approved')
        .fold<double>(
            0, (s, c) => s + ((c['platform_fee'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: C.textPrimary),
          onPressed: _exitPage,
          tooltip: _tr('رجوع', 'Back'),
        ),
        title: Text(_tr('مراقبة تسجيلات الدخول', 'Check-in monitor'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: C.cyan),
              onPressed: _loadCheckins),
        ],
      ),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _miniStat(
                    _tr('اليوم', 'Today'), '${todayCheckins.length}', C.cyan),
                const SizedBox(width: 8),
                _miniStat(
                    _tr('إجمالي', 'Total'), '${_checkins.length}', C.green),
                const SizedBox(width: 8),
                _miniStat(_tr('الإيرادات', 'Revenue'),
                    formatCurrency(context, totalRevenue), C.gold),
                const SizedBox(width: 8),
                _miniStat(_tr('العمولة', 'Commission'),
                    formatCurrency(context, totalCommission), C.purple),
              ],
            ),
          ).animate().fadeIn(),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip(_tr('الكل', 'All'), 'all'),
                const SizedBox(width: 8),
                _filterChip(_tr('معتمد', 'Approved'), 'approved'),
                const SizedBox(width: 8),
                _filterChip(_tr('مرفوض', 'Rejected'), 'rejected'),
              ],
            ),
          ),

          // Checkin list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: C.cyan))
                : _checkins.isEmpty
                    ? Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sensors_off,
                              size: 64, color: C.textMuted),
                          const SizedBox(height: 12),
                          Text(
                              _tr('لا توجد تسجيلات دخول', 'No check-ins found'),
                              style: GoogleFonts.cairo(color: C.textMuted)),
                        ],
                      ))
                    : RefreshIndicator(
                        color: C.cyan,
                        onRefresh: _loadCheckins,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _checkins.length,
                          itemBuilder: (ctx, i) =>
                              _buildCheckinItem(_checkins[i], i)
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(
                                          milliseconds: i.clamp(0, 20) * 30)),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    color: color, fontSize: 12, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadCheckins();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? C.cyan.withValues(alpha: 0.2) : C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? C.cyan : C.border),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                color: selected ? C.cyan : C.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _buildCheckinItem(Map<String, dynamic> c, int index) {
    final approved = c['status'] == 'approved';
    final locName = (c['partner_locations'] as Map?)?['name'] ?? '-';
    final profile = c['profiles'] as Map?;
    final userName = profile?['name'] ?? _tr('مستخدم', 'User');
    final userPhone = profile?['phone'] ?? '';
    final ts = DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now();
    final amount = (c['final_price'] as num?)?.toDouble() ?? 0;
    final commission = (c['platform_fee'] as num?)?.toDouble() ?? 0;
    final rejectCode = c['rejection_reason'] as String?;

    // Fraud detection hints
    final isToday =
        ts.day == DateTime.now().day && ts.month == DateTime.now().month;
    final timeAgo = DateTime.now().difference(ts);
    final isRecent = timeAgo.inMinutes < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecent
              ? C.cyan.withValues(alpha: 0.4)
              : C.border.withValues(alpha: 0.3),
          width: isRecent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (approved ? C.green : C.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(approved ? Icons.check : Icons.close,
                    color: approved ? C.green : C.red, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: C.textPrimary,
                            fontSize: 14)),
                    Text(userPhone,
                        style: GoogleFonts.cairo(
                            color: C.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (approved)
                    Text(formatCurrency(context, amount),
                        style: GoogleFonts.cairo(
                            color: C.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  Text(
                    isToday
                        ? DateFormat(
                            'HH:mm',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(ts)
                        : DateFormat(
                            'MM/dd HH:mm',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(ts),
                    style: GoogleFonts.cairo(color: C.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: C.textMuted),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(locName,
                      style: GoogleFonts.cairo(
                          color: C.textSecondary, fontSize: 11))),
              if (approved && commission > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: C.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                      '${_tr('عمولة', 'Commission')}: ${formatCurrency(context, commission)}',
                      style: GoogleFonts.cairo(
                          color: C.purple,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              if (rejectCode != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: C.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(rejectCode,
                      style: GoogleFonts.cairo(
                          color: C.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              if (isRecent) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: C.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fiber_new, size: 10, color: C.cyan),
                      const SizedBox(width: 2),
                      Text(_tr('جديد', 'New'),
                          style: GoogleFonts.cairo(
                              color: C.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
