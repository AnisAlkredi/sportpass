import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
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
  String _tr(String ar, String en) => context.trd(ar, en);

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
    final label = newStatus == 'suspended'
        ? _tr('تعليق', 'Suspend')
        : _tr('تفعيل', 'Activate');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(_tr('$label الحساب؟', '$label account?'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, color: C.textPrimary)),
        content: Text(
          newStatus == 'suspended'
              ? _tr(
                  'سيتم تعليق هذا المستخدم ولن يتمكن من الدخول',
                  'This user will be suspended and will not be able to sign in',
                )
              : _tr(
                  'سيتم تفعيل الحساب مرة أخرى',
                  'The account will be activated again',
                ),
          style: GoogleFonts.cairo(color: C.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr('إلغاء', 'Cancel'), style: GoogleFonts.cairo())),
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
              content: Text(_tr('تم $label الحساب', '$label account completed'),
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
          title: Text(_tr('تعديل الرصيد', 'Adjust balance'),
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
                        label: Text(_tr('إضافة +', 'Add +'),
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
                        label: Text(_tr('خصم -', 'Deduct -'),
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
                    labelText: _tr('المبلغ', 'Amount'),
                    suffixText: currencyLabel(context),
                    prefixIcon: Icon(isCredit ? Icons.add : Icons.remove,
                        color: isCredit ? C.green : C.red),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: GoogleFonts.cairo(color: C.textPrimary),
                  decoration: InputDecoration(
                      labelText: _tr('السبب', 'Reason'),
                      prefixIcon: const Icon(Icons.note, color: C.gold)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text(_tr('إلغاء', 'Cancel'), style: GoogleFonts.cairo())),
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
              child: Text(_tr('تأكيد', 'Confirm'),
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
              content: Text(
                  _tr('تم تعديل الرصيد بنجاح', 'Balance adjusted successfully'),
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
        title: Text(_tr('تفاصيل المستخدم', 'User details'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : _user == null
              ? Center(
                  child: Text(_tr('مستخدم غير موجود', 'User not found'),
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
        ? _tr('مدير', 'Admin')
        : role == 'gym_owner'
            ? _tr('صاحب نادي', 'Gym owner')
            : _tr('رياضي', 'Athlete');

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
                    Text(_user?['name'] ?? _tr('مستخدم', 'User'),
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
                      child: Text(_tr('معلّق', 'Suspended'),
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
              Text(_tr('الرصيد', 'Balance'),
                  style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12)),
              Text(formatCurrency(context, _balance),
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
            label: Text(_tr('تعديل الرصيد', 'Adjust balance'),
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
            label: Text(
                isSuspended
                    ? _tr('تفعيل', 'Activate')
                    : _tr('تعليق', 'Suspend'),
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
          Text(_tr('تفاصيل المحفظة', 'Wallet details'),
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _infoRow(_tr('الرصيد الحالي', 'Current balance'),
              formatCurrency(context, _balance), C.cyan),
          _infoRow(_tr('عدد المعاملات', 'Transactions count'),
              '${_transactions.length}', C.textSecondary),
          _infoRow(_tr('عدد الزيارات', 'Check-ins count'),
              '${_checkins.length}', C.textSecondary),
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
        Text(_tr('آخر المعاملات', 'Recent transactions'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: C.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Center(
              child: Text(_tr('لا توجد معاملات', 'No transactions'),
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
                      Text(
                          DateFormat(
                            'MM/dd HH:mm',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(ts),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Text(
                    '${isPositive ? '+' : ''}${formatCurrency(context, amount)}',
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
        Text(_tr('سجل الزيارات', 'Check-in history'),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: C.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 12),
        if (_checkins.isEmpty)
          Center(
              child: Text(_tr('لا توجد زيارات', 'No visits'),
                  style: GoogleFonts.cairo(color: C.textMuted))),
        ..._checkins.take(10).map((c) {
          final locName =
              (c['partner_locations'] as Map?)?['name'] ?? _tr('نادي', 'Gym');
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
                      Text(
                          DateFormat(
                            'MM/dd HH:mm',
                            AppLocalizations.of(context).isEnglish
                                ? 'en'
                                : 'ar',
                          ).format(ts),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Text(
                    formatCurrency(
                        context, (c['final_price'] as num?)?.toDouble() ?? 0),
                    style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
