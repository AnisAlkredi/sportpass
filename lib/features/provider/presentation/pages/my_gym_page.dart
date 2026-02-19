import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class MyGymPage extends StatefulWidget {
  const MyGymPage({super.key});
  @override
  State<MyGymPage> createState() => _MyGymPageState();
}

class _MyGymPageState extends State<MyGymPage> {
  bool _loading = true;
  bool _canCreateGym = false;
  String _role = 'athlete';
  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final profile = await sb
          .from('profiles')
          .select('role')
          .eq('user_id', uid)
          .maybeSingle();
      _role = profile?['role']?.toString() ?? 'athlete';
      _canCreateGym = _role == 'gym_owner' || _role == 'admin';

      final ps =
          await sb.from('partners').select().eq('owner_id', uid).limit(1);
      if (ps.isNotEmpty) {
        _partner = ps.first;
        _locations = await sb
            .from('partner_locations')
            .select()
            .eq('partner_id', _partner!['id']);
      }
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
        title: Text('ناديي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
        actions: [
          if (_partner == null && _canCreateGym)
            IconButton(
              icon: const Icon(Icons.storefront, color: C.gold),
              onPressed: () => context.push(AppRouter.gymSetup),
              tooltip: 'إنشاء نادي',
            ),
          if (_partner != null)
            IconButton(
                icon: const Icon(Icons.add_location_alt, color: C.cyan),
                onPressed: () =>
                    context.push(AppRouter.addLocation, extra: _partner!['id']),
                tooltip: 'إضافة فرع'),
        ],
      ),
      floatingActionButton: _partner != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push(AppRouter.addLocation, extra: _partner!['id']),
              backgroundColor: C.cyan,
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: Text('إضافة فرع',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : _partner == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.store, size: 64, color: C.textMuted),
                  const SizedBox(height: 12),
                  Text('لم تُنشئ نادياً بعد',
                      style:
                          GoogleFonts.cairo(color: C.textMuted, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    _role == 'gym_owner_pending'
                        ? 'طلبك قيد مراجعة الإدارة، بعد الموافقة يمكنك إنشاء النادي.'
                        : _canCreateGym
                            ? 'أنشئ ناديك الآن ثم أضف الفروع ليتم اعتمادها من الإدارة.'
                            : 'النادي يُربط من قبل الإدارة بعد الموافقة.',
                    style: GoogleFonts.cairo(color: C.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_canCreateGym) ...[
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRouter.gymSetup),
                      icon: const Icon(Icons.storefront),
                      label: Text(
                        'إنشاء نادي',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text('تحديث',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                ]))
              : RefreshIndicator(
                  color: C.cyan,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    children: [
                      // Gym info card
                      GlassCard(
                        gradient: C.goldGradient,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.store,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_partner!['name'] ?? '',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800)),
                                    if (_partner!['category'] != null)
                                      Text(
                                          _partner!['category']
                                              .toString()
                                              .toUpperCase(),
                                          style: GoogleFonts.cairo(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const SizedBox.shrink(),
                            ]),
                            if (_partner!['description'] != null &&
                                _partner!['description'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_partner!['description'],
                                    style: GoogleFonts.cairo(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                        height: 1.5)),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الفروع ومواقع التدريب',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: C.textPrimary,
                                  fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: C.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: C.border)),
                            child: Text('${_locations.length}',
                                style: GoogleFonts.cairo(
                                    color: C.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_locations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text('لا توجد فروع مضافة بعد',
                              style: GoogleFonts.cairo(color: C.textMuted)),
                        ),

                      ..._locations.asMap().entries.map((e) {
                        final i = e.key;
                        final l = e.value;
                        final photosCount =
                            ((l['photos'] as List?) ?? const []).length;
                        final hoursSummary =
                            _extractHoursSummary(l['operating_hours']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: C.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: C.border),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(l['name'] ?? '',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w700,
                                              color: C.textPrimary,
                                              fontSize: 15))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        gradient: C.goldGradient,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text('سعر الدخول',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                      formatSYP((l['base_price'] as num?)
                                              ?.toDouble() ??
                                          0),
                                      style: GoogleFonts.cairo(
                                          color: C.gold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                ]),
                                if (l['address_text'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14, color: C.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(l['address_text'],
                                                style: GoogleFonts.cairo(
                                                    color: C.textMuted,
                                                    fontSize: 12))),
                                      ],
                                    ),
                                  ),
                                if (hoursSummary != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule,
                                            size: 14, color: C.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'الدوام: $hoursSummary',
                                            style: GoogleFonts.cairo(
                                                color: C.textMuted,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (photosCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.image_outlined,
                                            size: 14, color: C.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          'صور مرفوعة: $photosCount',
                                          style: GoogleFonts.cairo(
                                              color: C.textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.radar,
                                          size: 14, color: C.cyan),
                                      const SizedBox(width: 4),
                                      Text('نطاق ${l['radius_m'] ?? 150}م',
                                          style: GoogleFonts.cairo(
                                              color: C.cyan, fontSize: 11)),
                                      const Spacer(),
                                      Icon(
                                        (l['is_active'] as bool? ?? false)
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 14,
                                        color:
                                            (l['is_active'] as bool? ?? false)
                                                ? C.green
                                                : C.gold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (l['is_active'] as bool? ?? false)
                                            ? 'نشط'
                                            : 'قيد المراجعة',
                                        style: GoogleFonts.cairo(
                                          color:
                                              (l['is_active'] as bool? ?? false)
                                                  ? C.green
                                                  : C.gold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 100));
                      }),
                    ],
                  ),
                ),
    );
  }

  String? _extractHoursSummary(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    for (final key in ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri']) {
      final dayData = map[key];
      if (dayData is! Map) {
        continue;
      }
      final data = Map<String, dynamic>.from(dayData);
      final open = (data['open'] ?? '').toString();
      final close = (data['close'] ?? '').toString();
      if (open.isNotEmpty && close.isNotEmpty) {
        return '$open - $close';
      }
    }
    return null;
  }
}
