import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('أدخل اسم النادي', style: GoogleFonts.cairo()),
            backgroundColor: C.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
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
        throw Exception('يجب موافقة الإدارة على طلب صاحب النادي أولاً');
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
                    ? 'تم إنشاء "${_nameCtrl.text}" بنجاح!'
                    : 'تم إرسال "${_nameCtrl.text}" للمراجعة الإدارية',
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
              content: Text('خطأ: $e', style: GoogleFonts.cairo()),
              backgroundColor: C.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text('إنشاء ملف النادي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
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
                        Text('أنشئ ملف ناديك',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text('أضف معلومات النادي والبدء باستقبال الرياضيين',
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
            Text('اسم النادي',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: C.textPrimary,
                    fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                hintText: 'مثال: Olympia Health Club',
                prefixIcon: const Icon(Icons.fitness_center, color: C.cyan),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Category
            Text('تصنيف النادي',
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
                        Text(e.value['label']!,
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
            Text('وصف النادي (اختياري)',
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
                hintText: 'اكتب وصفاً مختصراً يجذب الرياضيين...',
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
                  _loading ? 'جاري الإنشاء...' : 'متابعة — إضافة الموقع',
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
                      'عمولة المنصة 20% تُخصم تلقائياً من كل زيارة. أنت تحدد السعر الذي يدفعه الرياضي.',
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
