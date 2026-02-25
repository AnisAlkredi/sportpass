import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/admin_cubit.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _tr(String ar, String en) => context.trd(ar, en);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<AdminCubit>().loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(_tr('لوحة التحكم', 'Admin dashboard'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart, color: C.cyan),
            onPressed: () => context.push(AppRouter.checkinMonitor),
            tooltip: _tr('مراقبة الزيارات', 'Visit monitor'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: C.red),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(AppRouter.login);
            },
            tooltip: _tr('تسجيل الخروج', 'Logout'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: C.cyan,
          labelColor: C.cyan,
          unselectedLabelColor: C.textMuted,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          tabs: [
            Tab(
                text: _tr('المدفوعات', 'Payments'),
                icon: const Icon(Icons.payment, size: 20)),
            Tab(
                text: _tr('المراكز', 'Gyms'),
                icon: const Icon(Icons.fitness_center, size: 20)),
            Tab(
                text: _tr('المستخدمون', 'Users'),
                icon: const Icon(Icons.people, size: 20)),
          ],
        ),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (ctx, state) {
          if (state is AdminLoading) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }
          if (state is AdminLoaded) {
            return Column(
              children: [
                // Stats bar
                _buildStatsBar(state.stats).animate().fadeIn(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPaymentsTab(
                        state.topupRequests,
                        state.qrRegenRequests,
                        state.gymOwnerRequests,
                      ),
                      _buildPartnersTab(state.partners),
                      _buildUsersTab(state.users),
                    ],
                  ),
                ),
              ],
            );
          }
          if (state is AdminError) {
            return Center(
                child: Text((state).message,
                    style: GoogleFonts.cairo(color: C.red)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsBar(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statBadge(
              _tr('مستخدمون', 'Users'), '${stats['totalUsers'] ?? 0}', C.cyan),
          const SizedBox(width: 8),
          _statBadge(_tr('معلقة', 'Pending'),
              '${stats['pendingRequests'] ?? 0}', C.gold),
          const SizedBox(width: 8),
          _statBadge(
              _tr('مراكز', 'Gyms'), '${stats['partnersCount'] ?? 0}', C.green),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderColor: color.withValues(alpha: 0.3),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(
    List<Map<String, dynamic>> topupRequests,
    List<Map<String, dynamic>> qrRegenRequests,
    List<Map<String, dynamic>> gymOwnerRequests,
  ) {
    if (topupRequests.isEmpty &&
        qrRegenRequests.isEmpty &&
        gymOwnerRequests.isEmpty) {
      return Center(
          child: Text(_tr('لا توجد مدفوعات', 'No payments found'),
              style: GoogleFonts.cairo(color: C.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_tr('طلبات الشحن', 'Top-up requests'),
            style: GoogleFonts.cairo(
                color: C.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (topupRequests.isEmpty)
          Text(_tr('لا توجد طلبات شحن', 'No top-up requests'),
              style: GoogleFonts.cairo(color: C.textMuted))
        else
          ...topupRequests.asMap().entries.map(
                (entry) => _buildTopupCard(entry.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: entry.key * 40)),
              ),
        const SizedBox(height: 18),
        Text(_tr('طلبات تجديد QR', 'QR regeneration requests'),
            style: GoogleFonts.cairo(
                color: C.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (qrRegenRequests.isEmpty)
          Text(_tr('لا توجد طلبات QR', 'No QR requests'),
              style: GoogleFonts.cairo(color: C.textMuted))
        else
          ...qrRegenRequests.asMap().entries.map(
                (entry) => _buildQrRegenCard(entry.value).animate().fadeIn(
                    delay: Duration(milliseconds: 120 + entry.key * 40)),
              ),
        const SizedBox(height: 18),
        Text(_tr('طلبات ترقية صاحب نادي', 'Gym owner upgrade requests'),
            style: GoogleFonts.cairo(
                color: C.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (gymOwnerRequests.isEmpty)
          Text(_tr('لا توجد طلبات ترقية', 'No upgrade requests'),
              style: GoogleFonts.cairo(color: C.textMuted))
        else
          ...gymOwnerRequests.asMap().entries.map(
                (entry) => _buildOwnerRequestCard(entry.value).animate().fadeIn(
                    delay: Duration(milliseconds: 220 + entry.key * 40)),
              ),
      ],
    );
  }

  Widget _buildTopupCard(Map<String, dynamic> p) {
    final status = p['status'] as String? ?? 'pending';
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    final profile = p['profiles'] as Map<String, dynamic>?;
    final phone = profile?['phone'] ?? '';
    final name = profile?['name'] ?? _tr('مستخدم', 'User');
    final isPending = status == 'pending';
    final proofUrl = p['proof_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? C.gold.withValues(alpha: 0.3)
              : C.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, color: C.textPrimary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.cairo(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(phone,
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12)),
          Text('${_tr('المبلغ', 'Amount')}: ${formatCurrency(context, amount)}',
              style: GoogleFonts.cairo(
                  color: C.cyan, fontSize: 14, fontWeight: FontWeight.w600)),
          Text('${_tr('رقم المعاملة', 'Transaction ID')}: ${p['tx_id'] ?? '-'}',
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
          if (proofUrl != null && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showReceiptDialog(proofUrl),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border),
                  image: DecorationImage(
                    image: NetworkImage(proofUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(_tr('عرض الإيصال', 'View receipt'),
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontSize: 10)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context
                        .read<AdminCubit>()
                        .approvePayment(p['id'], p['user_id'], amount),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_tr('موافقة', 'Approve'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: C.green,
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(p['id']),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(_tr('رفض', 'Reject'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: C.red,
                        side: const BorderSide(color: C.red)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrRegenCard(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final location = request['partner_locations'] as Map<String, dynamic>?;
    final requester = request['requester'] as Map<String, dynamic>?;
    final locationName = location?['name']?.toString() ?? _tr('فرع', 'Branch');
    final requesterName =
        requester?['name']?.toString() ?? _tr('صاحب نادي', 'Gym owner');
    final requesterPhone = requester?['phone']?.toString() ?? '-';
    final adminNotes = request['admin_notes']?.toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? C.cyan.withValues(alpha: 0.4)
              : C.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_tr('طلب QR', 'QR request')}: $locationName',
                  style: GoogleFonts.cairo(
                    color: C.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.cairo(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$requesterName • $requesterPhone',
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12)),
          if (!isPending && adminNotes != null && adminNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_tr('ملاحظة الإدارة', 'Admin note')}: $adminNotes',
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 12),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showQrReviewDialog(
                      requestId: request['id'] as String,
                      approve: true,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_tr('موافقة', 'Approve'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQrReviewDialog(
                      requestId: request['id'] as String,
                      approve: false,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(_tr('رفض', 'Reject'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.red,
                      side: const BorderSide(color: C.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final requester = request['requester'] as Map<String, dynamic>?;
    final requesterName =
        requester?['name']?.toString() ?? _tr('مستخدم', 'User');
    final requesterPhone = requester?['phone']?.toString() ?? '-';
    final adminNotes = request['admin_notes']?.toString().trim();
    final gymName = request['gym_name']?.toString().trim();
    final gymCity = request['gym_city']?.toString().trim();
    final gymAddress = request['gym_address']?.toString().trim();
    final gymCategory = request['gym_category']?.toString().trim();
    final gymCategoryDisplay = gymCategory == null || gymCategory.isEmpty
        ? null
        : gymCategory
            .split(',')
            .map((e) => _gymCategoryLabel(e.trim()))
            .where((e) => e.isNotEmpty)
            .join(' • ');
    final businessDescription =
        request['business_description']?.toString().trim();
    final branchesCount = (request['branches_count'] as num?)?.toInt();
    final requestNotes = request['notes']?.toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? C.gold.withValues(alpha: 0.45)
              : C.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('طلب دور صاحب نادي', 'Gym owner role request'),
                style: GoogleFonts.cairo(
                  color: C.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.cairo(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$requesterName • $requesterPhone',
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12)),
          if (gymName != null && gymName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_tr('اسم النادي', 'Gym name')}: $gymName',
              style: GoogleFonts.cairo(
                color: C.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if ((gymCity != null && gymCity.isNotEmpty) ||
              (gymAddress != null && gymAddress.isNotEmpty) ||
              branchesCount != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_tr('المدينة', 'City')}: ${gymCity?.isNotEmpty == true ? gymCity : '-'}'
              ' • ${_tr('الفروع', 'Branches')}: ${branchesCount ?? 1}',
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11),
            ),
            if (gymAddress != null && gymAddress.isNotEmpty)
              Text(
                '${_tr('العنوان', 'Address')}: $gymAddress',
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11),
              ),
            if (gymCategoryDisplay != null && gymCategoryDisplay.isNotEmpty)
              Text(
                '${_tr('النشاط', 'Activity')}: $gymCategoryDisplay',
                style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11),
              ),
          ],
          if (businessDescription != null &&
              businessDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              businessDescription,
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 12),
            ),
          ],
          if ((gymName == null || gymName.isEmpty) &&
              requestNotes != null &&
              requestNotes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${_tr('تفاصيل الطلب', 'Request details')}: $requestNotes',
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 12),
            ),
          ],
          if (!isPending && adminNotes != null && adminNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_tr('ملاحظة الإدارة', 'Admin note')}: $adminNotes',
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 12),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOwnerReviewDialog(
                      requestId: request['id'] as String,
                      approve: true,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(_tr('موافقة', 'Approve'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOwnerReviewDialog(
                      requestId: request['id'] as String,
                      approve: false,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(_tr('رفض', 'Reject'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.red,
                      side: const BorderSide(color: C.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showOwnerReviewDialog({
    required String requestId,
    required bool approve,
  }) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve
              ? _tr('موافقة طلب صاحب نادي', 'Approve gym owner request')
              : _tr('رفض طلب صاحب نادي', 'Reject gym owner request'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: _tr('ملاحظة إدارية', 'Admin note'),
            hintText: approve
                ? _tr(
                    'مثال: تمت الموافقة، يمكنك ربط النادي الآن',
                    'Example: Approved, you can link the gym now',
                  )
                : _tr(
                    'مثال: يرجى استكمال بيانات الحساب',
                    'Example: Please complete account details',
                  ),
          ),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('إلغاء', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final note = noteCtrl.text.trim();
              if (note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _tr('يرجى إدخال ملاحظة', 'Please enter a note'),
                        style: GoogleFonts.cairo()),
                    backgroundColor: C.red,
                  ),
                );
                return;
              }
              context.read<AdminCubit>().reviewGymOwnerRequest(
                    requestId,
                    approve: approve,
                    adminNotes: note,
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? C.green : C.red,
            ),
            child: Text(
              approve ? _tr('موافقة', 'Approve') : _tr('رفض', 'Reject'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrReviewDialog({
    required String requestId,
    required bool approve,
  }) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve
              ? _tr('موافقة طلب QR', 'Approve QR request')
              : _tr('رفض طلب QR', 'Reject QR request'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText:
                _tr('ملاحظة للإدارة/صاحب النادي', 'Note for admin/gym owner'),
            hintText: approve
                ? _tr(
                    'مثال: تمت الموافقة وتم إصدار رمز جديد',
                    'Example: Approved and a new token has been issued',
                  )
                : _tr(
                    'مثال: يرجى تحديث بيانات الفرع قبل إعادة الطلب',
                    'Example: Please update branch details before requesting again',
                  ),
          ),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('إلغاء', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final note = noteCtrl.text.trim();
              if (note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _tr('يرجى إدخال ملاحظة قبل المتابعة',
                          'Please enter a note before continuing'),
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: C.red,
                  ),
                );
                return;
              }
              context.read<AdminCubit>().reviewQrRegeneration(
                    requestId,
                    approve: approve,
                    adminNotes: note,
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? C.green : C.red,
            ),
            child: Text(
              approve ? _tr('موافقة', 'Approve') : _tr('رفض', 'Reject'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('رفض طلب الشحن', 'Reject top-up request'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          decoration:
              InputDecoration(labelText: _tr('سبب الرفض', 'Rejection reason')),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tr('إلغاء', 'Cancel'))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AdminCubit>()
                  .rejectPayment(requestId, reasonCtrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.red),
            child: Text(_tr('رفض', 'Reject')),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersTab(List<Map<String, dynamic>> partners) {
    // Sort: Pending (inactive partner OR has inactive locations) first
    final sortedPartners = List<Map<String, dynamic>>.from(partners);
    sortedPartners.sort((a, b) {
      final aLocs = (a['partner_locations'] as List?) ?? [];
      final bLocs = (b['partner_locations'] as List?) ?? [];
      final aPending =
          (a['is_active'] != true) || aLocs.any((l) => l['is_active'] != true);
      final bPending =
          (b['is_active'] != true) || bLocs.any((l) => l['is_active'] != true);
      if (aPending && !bPending) return -1;
      if (!aPending && bPending) return 1;
      return (a['name'] ?? '').compareTo(b['name'] ?? '');
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPartnerDialog(),
              icon: const Icon(Icons.add),
              label: Text(_tr('إضافة مركز جديد', 'Add new gym'),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedPartners.length,
            itemBuilder: (ctx, i) {
              final p = sortedPartners[i];
              final locs = (p['partner_locations'] as List?) ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(p['name'] ?? '',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                    color: C.textPrimary))),
                        Switch(
                          value: p['is_active'] ?? false,
                          activeThumbColor: C.green,
                          inactiveThumbColor: C.red,
                          inactiveTrackColor: C.red.withValues(alpha: 0.3),
                          onChanged: (val) => context
                              .read<AdminCubit>()
                              .togglePartnerStatus(p['id'], val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (_) {
                      final owner = p['owner'] as Map<String, dynamic>?;
                      final ownerName = owner?['name']?.toString();
                      final ownerPhone = owner?['phone']?.toString();
                      final hasOwner =
                          ownerName != null && ownerName.trim().isNotEmpty;
                      return Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: C.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hasOwner
                                  ? '$ownerName${(ownerPhone != null && ownerPhone.isNotEmpty) ? ' • $ownerPhone' : ''}'
                                  : _tr('لا يوجد مالك مرتبط',
                                      'No owner assigned'),
                              style: GoogleFonts.cairo(
                                  color: C.textSecondary, fontSize: 11),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAssignOwnerDialog(
                              partnerId: p['id'],
                              partnerName: p['name'] ?? '',
                              currentPhone: ownerPhone,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: C.gold,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              hasOwner
                                  ? _tr('تغيير المالك', 'Change owner')
                                  : _tr('تعيين مالك', 'Assign owner'),
                              style: GoogleFonts.cairo(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('${locs.length} ${_tr('فرع', 'branches')}',
                                style: GoogleFonts.cairo(
                                    color: C.textMuted, fontSize: 12)),
                            const SizedBox(width: 8),
                            // Check for pending locations
                            if (locs.any((l) => l['is_active'] != true))
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: C.red, shape: BoxShape.circle),
                                child: Text(
                                    '${locs.where((l) => l['is_active'] != true).length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            TextButton.icon(
                              onPressed: () =>
                                  _showLocationsManager(p['name'] ?? '', locs),
                              icon: const Icon(Icons.settings, size: 14),
                              label: Text(
                                  _tr('إدارة الفروع', 'Manage branches'),
                                  style: GoogleFonts.cairo(fontSize: 11)),
                              style: TextButton.styleFrom(
                                foregroundColor: C.cyan,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        if (p['is_active'] != true)
                          Text(_tr('معطل', 'Disabled'),
                              style: GoogleFonts.cairo(
                                  color: C.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(p['category'] ?? '',
                        style: GoogleFonts.cairo(
                            color: C.textMuted, fontSize: 12)),
                    Text(
                        _tr('عمولة: 80/20 (ثابتة)',
                            'Commission: 80/20 (fixed)'),
                        style: GoogleFonts.cairo(color: C.gold, fontSize: 12)),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab(List<Map<String, dynamic>> users) {
    return Column(
      children: [
        // Search could be added here
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              // Handle wallets - can be either a Map (single) or List (multiple)
              final walletsData = u['wallets'];
              double balance = 0;
              if (walletsData != null) {
                if (walletsData is List && walletsData.isNotEmpty) {
                  balance = ((walletsData.first as Map)['balance'] as num?)
                          ?.toDouble() ??
                      0;
                } else if (walletsData is Map) {
                  balance = (walletsData['balance'] as num?)?.toDouble() ?? 0;
                }
              }
              return GestureDetector(
                onTap: () => context.push('/admin/user/${u['user_id']}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            _roleColor(u['role']).withValues(alpha: 0.15),
                        child: Icon(_roleIcon(u['role']),
                            color: _roleColor(u['role']), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name'] ?? _tr('مستخدم', 'User'),
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w600,
                                    color: C.textPrimary,
                                    fontSize: 14)),
                            Text(
                                '${u['phone'] ?? '-'} • ${_roleLabel(u['role'])}',
                                style: GoogleFonts.cairo(
                                    color: C.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatCurrency(context, balance),
                              style: GoogleFonts.cairo(
                                  color: C.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Icon(Icons.chevron_right,
                              color: C.textMuted, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
            },
          ),
        ),
      ],
    );
  }

  Color _statusColor(String s) =>
      switch (s) { 'approved' => C.green, 'rejected' => C.red, _ => C.gold };
  String _statusLabel(String s) => switch (s) {
        'approved' => _tr('تمت الموافقة', 'Approved'),
        'rejected' => _tr('مرفوض', 'Rejected'),
        _ => _tr('معلق', 'Pending')
      };
  Color _roleColor(String? r) =>
      switch (r) { 'admin' => C.purple, 'gym_owner' => C.gold, _ => C.cyan };
  IconData _roleIcon(String? r) => switch (r) {
        'admin' => Icons.admin_panel_settings,
        'gym_owner' => Icons.store,
        _ => Icons.person
      };
  String _roleLabel(String? r) => switch (r) {
        'admin' => _tr('مدير', 'Admin'),
        'gym_owner' => _tr('صاحب نادي', 'Gym owner'),
        _ => _tr('رياضي', 'Athlete')
      };

  String _gymCategoryLabel(String key) => switch (key) {
        'gym' => _tr('نادي رياضي', 'Gym'),
        'women_only' => _tr('نادي نسائي', 'Women only gym'),
        'pool' => _tr('مسبح', 'Pool'),
        'martial_arts' => _tr('فنون قتالية', 'Martial arts'),
        'studio' => _tr('استوديو لياقة', 'Fitness studio'),
        _ => key,
      };

  void _showAddPartnerDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'gym');
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('إضافة مركز', 'Add gym'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      labelText: _tr('اسم المركز', 'Gym name'))),
              const SizedBox(height: 12),
              TextField(
                  controller: catCtrl,
                  decoration: InputDecoration(
                      labelText: _tr('التصنيف (gym/spa/yoga)',
                          'Category (gym/spa/yoga)'))),
              const SizedBox(height: 12),
              TextField(
                  controller: descCtrl,
                  decoration:
                      InputDecoration(labelText: _tr('وصف', 'Description')),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tr('إلغاء', 'Cancel'))),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AdminCubit>()
                  .addPartner(nameCtrl.text, catCtrl.text, descCtrl.text);
              Navigator.pop(ctx);
            },
            child: Text(_tr('إضافة', 'Add')),
          ),
        ],
      ),
    );
  }

  void _showAssignOwnerDialog({
    required String partnerId,
    required String partnerName,
    String? currentPhone,
  }) {
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(
          _tr('تعيين مالك للنادي', 'Assign gym owner'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: C.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_tr('النادي', 'Gym')}: $partnerName',
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                labelText: _tr('رقم هاتف المستخدم', 'User phone number'),
                hintText: _tr('09XXXXXXXX', '09XXXXXXXX'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'سيتم ربط المستخدم بالنادي وترقيته إلى gym_owner.',
                'The user will be linked to this gym and promoted to gym_owner.',
              ),
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('إلغاء', 'Cancel'), style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminCubit>().assignGymOwnerByPhone(
                    partnerId: partnerId,
                    phone: phoneCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.gold),
            child: Text(
              _tr('تعيين', 'Assign'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationsManager(String partnerName, List<dynamic> locations) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('${_tr('فروع', 'Branches')} $partnerName',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700, color: C.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: locations.isEmpty
              ? Center(
                  child: Text(_tr('لا توجد فروع', 'No branches'),
                      style: GoogleFonts.cairo(color: C.textMuted)))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const Divider(color: C.border),
                  itemBuilder: (c, i) {
                    final l = locations[i];
                    final isActive = l['is_active'] ?? false;
                    final priceCtrl =
                        TextEditingController(text: '${l['base_price']}');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(l['name'],
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          color: C.textPrimary))),
                              Switch(
                                value: isActive,
                                activeThumbColor: C.green,
                                onChanged: (v) {
                                  context
                                      .read<AdminCubit>()
                                      .toggleLocationStatus(l['id'], v);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                  '${_tr('السعر الأساسي', 'Base price')} (${currencyLabel(context)}): ',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12, color: C.textSecondary)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: C.cyan,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 8)),
                                  onSubmitted: (v) {
                                    final p = double.tryParse(v);
                                    if (p != null) {
                                      context
                                          .read<AdminCubit>()
                                          .updateLocationPrice(l['id'], p);
                                      Navigator.pop(ctx);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.save,
                                    size: 18, color: C.green),
                                onPressed: () {
                                  final p = double.tryParse(priceCtrl.text);
                                  if (p != null) {
                                    context
                                        .read<AdminCubit>()
                                        .updateLocationPrice(l['id'], p);
                                    Navigator.pop(ctx);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tr('إغلاق', 'Close'), style: GoogleFonts.cairo())),
        ],
      ),
    );
  }
}
