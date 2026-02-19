import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});
  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _checkins = [];
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final sb = Supabase.instance.client;
    try {
      final user = await sb
          .from('profiles')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final wallet = await sb
          .from('wallets')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();
      _balance = (wallet?['balance'] as num?)?.toDouble() ?? 0;

      _transactions = List<Map<String, dynamic>>.from(
        await sb
            .from('wallet_ledger')
            .select()
            .eq('wallet_owner_id', widget.userId)
            .eq('wallet_type', 'user')
            .order('created_at', ascending: false)
            .limit(20),
      );

      _checkins = List<Map<String, dynamic>>.from(
        await sb
            .from('checkins')
            .select('*, partner_locations(name)')
            .eq('user_id', widget.userId)
            .order('created_at', ascending: false)
            .limit(20),
      );

      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleSuspend() async {
    final newStatus = _user?['status'] == 'suspended' ? 'active' : 'suspended';
    final label = newStatus == 'suspended' ? 'تعليق' : 'تفعيل';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('$label الحساب؟',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, color: C.textPrimary)),
        content: Text(
          newStatus == 'suspended'
              ? 'سيتم تعليق هذا المستخدم ولن يتمكن من الدخول'
              : 'سيتم تفعيل الحساب مرة أخرى',
          style: GoogleFonts.cairo(color: C.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 'suspended' ? C.red : C.green),
            child: Text(label,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'status': newStatus}).eq('user_id', widget.userId);
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم $label الحساب', style: GoogleFonts.cairo()),
              backgroundColor: C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e', style: GoogleFonts.cairo()),
              backgroundColor: C.red),
        );
      }
    }
  }

  Future<void> _adjustBalance() async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isCredit = true;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          backgroundColor: C.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تعديل الرصيد',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700, color: C.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('إضافة +',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                        selected: isCredit,
                        onSelected: (_) => setD(() => isCredit = true),
                        selectedColor: C.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('خصم -',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                        selected: !isCredit,
                        onSelected: (_) => setD(() => isCredit = false),
                        selectedColor: C.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(color: C.textPrimary, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: 'ل.س',
                    prefixIcon: Icon(isCredit ? Icons.add : Icons.remove,
                        color: isCredit ? C.green : C.red),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: GoogleFonts.cairo(color: C.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'السبب',
                      prefixIcon: Icon(Icons.note, color: C.gold)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null ||
                    amount <= 0 ||
                    reasonCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, {
                  'amount': isCredit ? amount : -amount,
                  'reason': reasonCtrl.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: C.cyan),
              child: Text('تأكيد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (result == null) {
      return;
    }
    try {
      await Supabase.instance.client.rpc('admin_adjust_wallet', params: {
        'p_user_id': widget.userId,
        'p_amount': result['amount'],
        'p_reason': result['reason'],
      });
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('تم تعديل الرصيد بنجاح', style: GoogleFonts.cairo()),
              backgroundColor: C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e', style: GoogleFonts.cairo()),
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
        title: Text('تفاصيل المستخدم',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : _user == null
              ? Center(
                  child: Text('مستخدم غير موجود',
                      style: GoogleFonts.cairo(color: C.textMuted)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildProfileCard().animate().fadeIn(),
                    const SizedBox(height: 16),
                    _buildActions().animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),
                    _buildWalletInfo().animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),
                    _buildTransactions().animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 20),
                    _buildCheckins().animate().fadeIn(delay: 400.ms),
                  ],
                ),
    );
  }

  Widget _buildProfileCard() {
    final role = _user?['role'] ?? 'athlete';
    final isSuspended = _user?['status'] == 'suspended';
    final roleColor = role == 'admin'
        ? C.purple
        : role == 'gym_owner'
            ? C.gold
            : C.cyan;
    final roleLabel = role == 'admin'
        ? 'مدير'
        : role == 'gym_owner'
            ? 'صاحب نادي'
            : 'رياضي';

    return GlassCard(
      borderColor: isSuspended
          ? C.red.withValues(alpha: 0.4)
          : roleColor.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  (_user?['name'] ?? '?')[0],
                  style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: roleColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user?['name'] ?? 'مستخدم',
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                    Text(_user?['phone'] ?? '-',
                        style: GoogleFonts.cairo(
                            color: C.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(roleLabel,
                        style: GoogleFonts.cairo(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (isSuspended) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: C.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('معلّق',
                          style: GoogleFonts.cairo(
                              color: C.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الرصيد',
                  style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12)),
              Text(formatSYP(_balance),
                  style: GoogleFonts.cairo(
                      color: C.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final isSuspended = _user?['status'] == 'suspended';
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _adjustBalance,
            icon: const Icon(Icons.edit, size: 18),
            label: Text('تعديل الرصيد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: C.cyan,
                padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleSuspend,
            icon:
                Icon(isSuspended ? Icons.check_circle : Icons.block, size: 18),
            label: Text(isSuspended ? 'تفعيل' : 'تعليق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isSuspended ? C.green : C.red,
              side: BorderSide(color: isSuspended ? C.green : C.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletInfo() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل المحفظة',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _infoRow('الرصيد الحالي', formatSYP(_balance), C.cyan),
          _infoRow('عدد المعاملات', '${_transactions.length}', C.textSecondary),
          _infoRow('عدد الزيارات', '${_checkins.length}', C.textSecondary),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 13)),
            Text(value,
                style: GoogleFonts.cairo(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('آخر المعاملات',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: C.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Center(
              child: Text('لا توجد معاملات',
                  style: GoogleFonts.cairo(color: C.textMuted))),
        ..._transactions.take(10).map((tx) {
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
          final isPositive = amount >= 0;
          final ts =
              DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isPositive ? C.green : C.red, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['description'] ?? tx['type'] ?? '-',
                          style: GoogleFonts.cairo(
                              color: C.textPrimary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(DateFormat('MM/dd HH:mm').format(ts),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Text('${isPositive ? '+' : ''}${formatSYP(amount)}',
                    style: GoogleFonts.cairo(
                        color: isPositive ? C.green : C.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCheckins() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سجل الزيارات',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: C.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 12),
        if (_checkins.isEmpty)
          Center(
              child: Text('لا توجد زيارات',
                  style: GoogleFonts.cairo(color: C.textMuted))),
        ..._checkins.take(10).map((c) {
          final locName = (c['partner_locations'] as Map?)?['name'] ?? 'نادي';
          final ts = DateTime.tryParse(c['created_at'] ?? '') ?? DateTime.now();
          final approved = c['status'] == 'approved';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: C.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(approved ? Icons.check_circle : Icons.cancel,
                    color: approved ? C.green : C.red, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locName,
                          style: GoogleFonts.cairo(
                              color: C.textPrimary, fontSize: 12)),
                      Text(DateFormat('MM/dd HH:mm').format(ts),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Text(formatSYP((c['final_price'] as num?)?.toDouble() ?? 0),
                    style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
