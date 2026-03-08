import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? C.textSecondary : const Color(0xFF4E6580);
    final surface = Theme.of(context).colorScheme.surface;

    Widget item({
      required IconData icon,
      required String title,
      required String value,
      String? note,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: C.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.cairo(
                      color: secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: GoogleFonts.cairo(
                        color: secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          context.trd('اتصل بنا', 'Contact us'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: C.cyanGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trd('قنوات التواصل الرسمية', 'Official contact channels'),
                  style: GoogleFonts.cairo(
                    color: C.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.trd(
                    'للشكاوى، الدعم الفني، أو الاستفسارات التنظيمية المتعلقة بتطبيق SportPass.',
                    'For complaints, technical support, and regulatory inquiries related to SportPass.',
                  ),
                  style: GoogleFonts.cairo(
                    color: C.navy.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          item(
            icon: Icons.business_outlined,
            title: context.trd('الجهة المسؤولة', 'Responsible entity'),
            value: context.trd(
              'مؤسسة سامي حمدان التجارية',
              'Sami Hamdan Commercial Establishment',
            ),
          ),
          item(
            icon: Icons.email_outlined,
            title: context.trd('البريد الإلكتروني', 'Email'),
            value: 'anis.alkredi@gmail.com',
            note: context.trd(
              'يفضّل كتابة عنوان واضح للرسالة لتسريع الاستجابة.',
              'Use a clear subject line for faster response.',
            ),
          ),
          item(
            icon: Icons.phone_outlined,
            title: context.trd('رقم الهاتف', 'Phone'),
            value: '0937164384',
          ),
          item(
            icon: Icons.schedule_outlined,
            title: context.trd('أوقات الاستجابة', 'Response window'),
            value: context.trd('من السبت إلى الخميس', 'Saturday to Thursday'),
            note: context.trd(
              'يتم التعامل مع الرسائل حسب أولوية الحالة.',
              'Messages are handled based on case priority.',
            ),
          ),
        ],
      ),
    );
  }
}
