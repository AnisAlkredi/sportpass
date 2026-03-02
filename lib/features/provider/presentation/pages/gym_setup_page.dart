import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';

class GymSetupPage extends StatefulWidget {
  const GymSetupPage({super.key});
  @override
  State<GymSetupPage> createState() => _GymSetupPageState();
}

class _GymSetupPageState extends State<GymSetupPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'gym';
  bool _loading = false;

  final _categories = {
    'gym': {'icon': '🏋️', 'label': 'نادي رياضي'},
    'yoga': {'icon': '🧘', 'label': 'يوغا'},
    'pool': {'icon': '🏊', 'label': 'مسبح'},
    'spa': {'icon': '💆', 'label': 'سبا'},
    'martial_arts': {'icon': '🥋', 'label': 'فنون قتالية'},
  };
  String _tr(String ar, String en) => context.trd(ar, en);
  String _categoryEn(String key) => switch (key) {
        'gym' => 'Gym',
        'yoga' => 'Yoga',
        'pool' => 'Pool',
        'spa' => 'Spa',
        'martial_arts' => 'Martial arts',
        _ => key,
      };

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('أدخل اسم النادي', 'Enter gym name'),
                style: GoogleFonts.cairo()),
            backgroundColor: C.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) {
        throw Exception(_tr('يجب تسجيل الدخول أولاً', 'You must login first'));
      }
      final profile = await sb
          .from('profiles')
          .select('role')
          .eq('user_id', uid)
          .maybeSingle();
      final role = profile?['role']?.toString() ?? 'athlete';
      final isAdmin = role == 'admin';
      final canCreate = isAdmin || role == 'gym_owner';
      if (!canCreate) {
        throw Exception(_tr(
          'يجب موافقة الإدارة على طلب صاحب النادي أولاً',
          'Admin approval is required for gym owner request first',
        ));
      }
      final res = await Supabase.instance.client
          .from('partners')
          .insert({
            'owner_id': uid,
            'name': _nameCtrl.text.trim(),
            'category': _category,
            'description': _descCtrl.text.trim(),
            // Owner-created gyms stay pending until admin review.
            'is_active': isAdmin,
          })
          .select()
          .single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                isAdmin
                    ? _tr(
                        'تم إنشاء "${_nameCtrl.text}" بنجاح!',
                        '"${_nameCtrl.text}" created successfully!',
                      )
                    : _tr(
                        'تم إرسال "${_nameCtrl.text}" للمراجعة الإدارية',
                        '"${_nameCtrl.text}" was sent for admin review',
                      ),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: C.green),
        );
        context.push(AppRouter.addLocation, extra: res['id']);
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
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_tr('إنشاء ملف النادي', 'Create gym profile'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GlassCard(
              gradient: C.goldGradient,
              child: Row(
                children: [
                  const Icon(Icons.store, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tr('أنشئ ملف ناديك', 'Create your gym profile'),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(
                            _tr('أضف معلومات النادي والبدء باستقبال الرياضيين',
                                'Add gym information and start accepting athletes'),
                            style: GoogleFonts.cairo(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 28),

            // Name
            Text(_tr('اسم النادي', 'Gym name'),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: C.textPrimary,
                    fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                hintText: _tr('مثال: Olympia Health Club',
                    'Example: Olympia Health Club'),
                prefixIcon: const Icon(Icons.fitness_center, color: C.cyan),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Category
            Text(_tr('تصنيف النادي', 'Gym category'),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: C.textPrimary,
                    fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((e) {
                final selected = _category == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _category = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? C.cyanGradient : null,
                      color: selected ? null : C.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? C.cyan : C.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value['icon']!,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(_tr(e.value['label']!, _categoryEn(e.key)),
                            style: GoogleFonts.cairo(
                              color: selected ? Colors.white : C.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Description
            Text(_tr('وصف النادي (اختياري)', 'Gym description (optional)'),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: C.textPrimary,
                    fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _tr('اكتب وصفاً مختصراً يجذب الرياضيين...',
                    'Write a short description that attracts athletes...'),
                prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.description, color: C.cyan)),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  _loading
                      ? _tr('جاري الإنشاء...', 'Creating...')
                      : _tr('متابعة — إضافة الموقع', 'Continue — add location'),
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: C.cyan),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 16),

            GlassCard(
              borderColor: C.textMuted.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: C.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _tr(
                        'عمولة المنصة 20% تُخصم تلقائياً من كل زيارة. أنت تحدد السعر الذي يدفعه الرياضي.',
                        'Platform fee is 20%, deducted automatically per visit. You set the price paid by the athlete.',
                      ),
                      style: GoogleFonts.cairo(
                          color: C.textMuted, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
