import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _sections(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? C.textSecondary : const Color(0xFF4E6580);
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          context.trd('سياسة الخصوصية', 'Privacy policy'),
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
                  context.trd(
                    'سياسة الخصوصية الرسمية لتطبيق SportPass',
                    'Official SportPass privacy policy',
                  ),
                  style: GoogleFonts.cairo(
                    color: C.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.trd(
                    'الجهة المسؤولة: مؤسسة سامي حمدان التجارية',
                    'Responsible entity: Sami Hamdan Commercial Establishment',
                  ),
                  style: GoogleFonts.cairo(
                    color: C.navy.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'anis.alkredi@gmail.com  |  0937164384',
                  style: GoogleFonts.cairo(
                    color: C.navy.withValues(alpha: 0.86),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.trd('آخر تحديث: 08-03-2026', 'Last updated: 2026-03-08'),
                  style: GoogleFonts.cairo(
                    color: C.navy.withValues(alpha: 0.86),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...sections.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: GoogleFonts.cairo(
                      color: onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.body,
                    style: GoogleFonts.cairo(
                      color: secondary,
                      fontSize: 13,
                      height: 1.75,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_PolicySection> _sections(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    if (isAr) {
      return const [
        _PolicySection(
          title: '1) ما البيانات التي نجمعها',
          body:
              'نجمع بيانات الحساب الأساسية (الاسم، البريد الإلكتروني)، وبيانات تشغيل الخدمة مثل السجل المالي، عمليات الدخول عبر QR، وسجل النشاط داخل التطبيق.',
        ),
        _PolicySection(
          title: '2) لماذا نجمع البيانات',
          body:
              'لاستخدام التطبيق بشكل صحيح: تسجيل الدخول، تنفيذ الدخول إلى النادي، إدارة المحفظة، عرض السجل، وتحسين الجودة التشغيلية والدعم الفني.',
        ),
        _PolicySection(
          title: '3) مشاركة البيانات',
          body:
              'لا يتم بيع البيانات الشخصية. قد يتم عرض الحد الأدنى من بيانات العملية للطرف المعني بالخدمة (مثل بيانات الدخول للنادي)، أو للجهات المختصة عند وجود التزام قانوني.',
        ),
        _PolicySection(
          title: '4) حماية البيانات',
          body:
              'نطبق ضوابط تقنية وتنظيمية لحماية البيانات من الوصول غير المصرح به، مع تقييد الصلاحيات حسب الدور ومراقبة العمليات الحساسة.',
        ),
        _PolicySection(
          title: '5) الاحتفاظ بالبيانات',
          body:
              'يتم الاحتفاظ بالبيانات للمدة اللازمة لتقديم الخدمة، والامتثال للمتطلبات التنظيمية والتدقيق المالي، ثم تتم المعالجة أو الإزالة وفق السياسة الداخلية.',
        ),
        _PolicySection(
          title: '6) حقوق المستخدم',
          body:
              'يمكنك طلب الاطلاع على بياناتك، أو تصحيحها، أو تقديم طلب متعلق بخصوصيتك عبر قنوات التواصل الرسمية المعلنة في التطبيق.',
        ),
        _PolicySection(
          title: '7) خصوصية القاصرين',
          body:
              'استخدام القاصرين يخضع للأنظمة النافذة ومسؤولية ولي الأمر عند الاقتضاء، ويحق للجهة المشغلة اتخاذ إجراءات تقييد أو إغلاق للحساب المخالف.',
        ),
        _PolicySection(
          title: '8) تحديثات السياسة',
          body:
              'قد نقوم بتحديث سياسة الخصوصية عند الحاجة. أي تغييرات جوهرية تُنشر داخل التطبيق وعلى الصفحة الرسمية.',
        ),
      ];
    }

    return const [
      _PolicySection(
        title: '1) Data we collect',
        body:
            'We collect account basics (name, email) and service data such as wallet transactions, QR check-ins, and activity history.',
      ),
      _PolicySection(
        title: '2) Why we collect data',
        body:
            'To operate login, check-in flows, wallet management, history tracking, and service support.',
      ),
      _PolicySection(
        title: '3) Data sharing',
        body:
            'We do not sell personal data. Minimum operational data may be shared with service parties or lawful authorities when required.',
      ),
      _PolicySection(
        title: '4) Data protection',
        body:
            'We use technical and organizational controls, role-based access, and sensitive operation monitoring.',
      ),
      _PolicySection(
        title: '5) Data retention',
        body:
            'Data is retained for service operation, compliance, and audit requirements, then handled per internal policy.',
      ),
      _PolicySection(
        title: '6) User rights',
        body:
            'Users may request access, correction, or privacy-related support through official channels.',
      ),
      _PolicySection(
        title: '7) Minors',
        body:
            'Minors usage is subject to local law and guardian responsibility when applicable.',
      ),
      _PolicySection(
        title: '8) Policy updates',
        body:
            'We may update this policy when needed. Material changes are published in the app and official website.',
      ),
    ];
  }
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
