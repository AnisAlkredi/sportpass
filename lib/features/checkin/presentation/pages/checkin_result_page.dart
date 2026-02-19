import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';

class CheckinResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  const CheckinResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result['success'] == true;
    final message =
        result['message']?.toString() ?? (success ? 'تم بنجاح' : 'فشل العملية');

    final gymName = result['gym_name']?.toString() ?? 'غير متاح';
    final locationName = result['location_name']?.toString() ?? 'غير متاح';

    final pricePaid = (result['price_paid'] as num?)?.toDouble() ?? 0;
    final basePrice = (result['base_price'] as num?)?.toDouble();
    final platformFee = (result['platform_fee'] as num?)?.toDouble();
    final newBalance = (result['new_balance'] as num?)?.toDouble() ?? 0;

    final createdAt = DateTime.tryParse(result['created_at']?.toString() ?? '');
    final createdAtText = createdAt == null
        ? null
        : DateFormat('yyyy/MM/dd - HH:mm').format(createdAt.toLocal());

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            _statusCircle(success)
                .animate()
                .scale(begin: const Offset(0.7, 0.7), duration: 450.ms),
            const SizedBox(height: 20),
            Text(
              success ? 'تم تسجيل الدخول' : 'فشل تسجيل الدخول',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: success ? C.green : C.red,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ).animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: C.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 24),
            GlassCard(
              borderColor: success
                  ? C.green.withValues(alpha: 0.35)
                  : C.red.withValues(alpha: 0.35),
              child: Column(
                children: [
                  _line('النادي', gymName),
                  const SizedBox(height: 10),
                  _line('الفرع', locationName),
                  if (createdAtText != null) ...[
                    const SizedBox(height: 10),
                    _line('الوقت', createdAtText),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06),
            if (success) ...[
              const SizedBox(height: 14),
              GlassCard(
                borderColor: C.cyan.withValues(alpha: 0.35),
                child: Column(
                  children: [
                    _valueLine(
                        'سعر الدخول النهائي', formatSYP(pricePaid), C.gold),
                    const SizedBox(height: 8),
                    const Divider(color: C.border),
                    const SizedBox(height: 8),
                    _valueLine(
                      'حصة النادي (base_price)',
                      basePrice == null ? 'غير متاح' : formatSYP(basePrice),
                      C.cyan,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: C.border),
                    const SizedBox(height: 8),
                    _valueLine(
                      'عمولة المنصة',
                      platformFee == null ? 'غير متاح' : formatSYP(platformFee),
                      C.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: C.border),
                    const SizedBox(height: 8),
                    _valueLine('الرصيد الجديد', formatSYP(newBalance), C.green),
                  ],
                ),
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.06),
            ],
            const SizedBox(height: 26),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRouter.home),
                icon: const Icon(Icons.home_rounded),
                label: Text(
                  'العودة للرئيسية',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? C.green : C.surfaceAlt,
                  foregroundColor: Colors.white,
                ),
              ),
            ).animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }

  Widget _statusCircle(bool success) {
    return Center(
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: success
              ? C.greenGradient
              : LinearGradient(
                  colors: [C.red, C.red.withValues(alpha: 0.75)],
                ),
          boxShadow: [
            BoxShadow(
              color: (success ? C.green : C.red).withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          success ? Icons.check_rounded : Icons.close_rounded,
          size: 62,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(color: C.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: C.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _valueLine(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
