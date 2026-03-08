import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';

class UsagePolicyPage extends StatelessWidget {
  const UsagePolicyPage({super.key});

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
          context.trd('سياسة الاستخدام', 'Usage policy'),
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
                    'سياسة الاستخدام الرسمية لتطبيق SportPass',
                    'Official SportPass usage policy',
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
          const SizedBox(height: 8),
          Text(
            context.trd(
              'هذه السياسة جزء من شروط استخدام التطبيق، ويعد استمرارك في الاستخدام موافقة عليها.',
              'This policy is part of the app terms. Continued usage means acceptance.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
          title: '1) تعريف بالتطبيق وطبيعة عمله',
          body:
              'SportPass تطبيق إلكتروني يتيح للمستخدمين الدخول إلى النوادي الرياضية عبر رمز QR، مع محفظة إلكترونية وسجل عمليات، ويتيح لأصحاب النوادي إدارة الفروع والزيارات ضمن نظام رقمي موحد.',
        ),
        _PolicySection(
          title: '2) الجهة المسؤولة عن التطبيق',
          body:
              'الجهة المالكة والمشغلة للتطبيق هي مؤسسة سامي حمدان التجارية، وهي المسؤولة عن تشغيل الخدمة وإدارة المنصة وحماية البيانات ومعالجة الشكاوى والاستفسارات.',
        ),
        _PolicySection(
          title: '3) الفئات المستهدفة',
          body:
              'الأفراد الراغبون بالدخول إلى النوادي الرياضية بنظام مرن، وأصحاب النوادي والمراكز الرياضية الراغبون بالانضمام كشركاء، والإدارة المخولة بمتابعة الطلبات والتشغيل والرقابة الفنية.',
        ),
        _PolicySection(
          title: '4) توصيف عمل التطبيق',
          body:
              'يشمل التطبيق تسجيل الحساب وتسجيل الدخول، واستكشاف النوادي الشريكة، وتنفيذ الدخول عبر QR، وإدارة رصيد المستخدم عبر المحفظة الإلكترونية، وتمكين صاحب النادي من إدارة النادي والفروع وفق الصلاحيات.',
        ),
        _PolicySection(
          title: '5) حقوق المستخدم ومسؤولياته وحماية بياناته',
          body:
              'يحق للمستخدم الاطلاع على بياناته وسجل عملياته وطلب التصحيح. ويلتزم بتقديم بيانات صحيحة، والحفاظ على سرية الحساب، وعدم إساءة الاستخدام أو التحايل. وتلتزم الجهة بجمع الحد الأدنى من البيانات وتطبيق ضوابط الحماية وعدم مشاركة البيانات إلا وفق القانون.',
        ),
        _PolicySection(
          title: '6) حقوق الجهة المسؤولة وواجباتها',
          body:
              'يحق للجهة تحديث الميزات أو تعليق الحسابات المخالفة وطلب معلومات إضافية عند الضرورة. وتلتزم بتشغيل الخدمة بموثوقية، وحماية البيانات، ومعالجة الشكاوى، وإشعار المستخدمين بالتعديلات الجوهرية.',
        ),
        _PolicySection(
          title: '7) سياسة القاصرين',
          body:
              'لا يُسمح باستخدام التطبيق للقاصرين إلا وفق الأنظمة النافذة ومسؤولية ولي الأمر عند الاقتضاء. ويحق للجهة اتخاذ إجراءات تحقق إضافية وتعليق أو إلغاء الحساب المخالف.',
        ),
        _PolicySection(
          title: '8) الإجراءات عند مخالفة السياسة',
          body:
              'عند ثبوت المخالفة يحق للجهة اتخاذ ما يلزم بحسب جسامة الحالة، بما في ذلك: الإنذار، التعليق المؤقت، الإيقاف النهائي، إلغاء أو تجميد العمليات، واللجوء للجهات المختصة عند وجود شبهة جرمية.',
        ),
      ];
    }

    return const [
      _PolicySection(
        title: '1) App definition',
        body:
            'SportPass enables gym access with QR check-in, wallet balance, and activity records for users, with management tools for gym partners.',
      ),
      _PolicySection(
        title: '2) Responsible entity',
        body:
            'The app is operated by Sami Hamdan Commercial Establishment, responsible for service operation, platform management, data protection, and support.',
      ),
      _PolicySection(
        title: '3) Target groups',
        body: 'Athletes, gym owners/partners, and authorized administrators.',
      ),
      _PolicySection(
        title: '4) Service description',
        body:
            'The app supports account login, gym discovery, QR check-in, wallet management, and partner/admin workflows according to permissions.',
      ),
      _PolicySection(
        title: '5) User rights and responsibilities',
        body:
            'Users can access their records and request corrections. Users must provide accurate data and keep credentials private. Misuse is prohibited.',
      ),
      _PolicySection(
        title: '6) Operator rights and obligations',
        body:
            'The operator may update features, suspend violating accounts, and request additional information when required. The operator commits to reliability and data protection.',
      ),
      _PolicySection(
        title: '7) Minors policy',
        body:
            'Usage by minors is subject to applicable law and guardian responsibility when required.',
      ),
      _PolicySection(
        title: '8) Violation handling',
        body:
            'Violations may result in warning, temporary suspension, permanent account closure, transaction freeze/cancelation, and legal escalation when needed.',
      ),
    ];
  }
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
