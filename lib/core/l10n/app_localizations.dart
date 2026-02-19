import 'package:flutter/material.dart';

/// App-wide localization using simple map-based approach
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_name': 'SportPass',
      'welcome_back': 'مرحباً بعودتك',
      'your_plan': 'محفظتك',
      'credits_remaining': 'الرصيد المتبقي',
      'check_in': 'تسجيل الدخول',
      'scan_qr': 'امسح QR للدخول',
      'partners': 'المراكز الرياضية',
      'home': 'الرئيسية',
      'activity': 'السجل',
      'wallet': 'المحفظة',
      'profile': 'حسابي',
      'admin': 'لوحة التحكم',
      'plans': 'الأسعار',
      'topup': 'شحن رصيد',
      'topup_wallet': 'شحن المحفظة',
      'balance': 'الرصيد',
      'total_spent': 'إجمالي الإنفاق',
      'total_earned': 'إجمالي الإيرادات',
      'transactions': 'المعاملات المالية',
      'no_transactions': 'لا توجد معاملات بعد',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'retry': 'إعادة المحاولة',
      'error': 'خطأ',
      'success': 'نجاح',
      'loading': 'جاري التحميل...',
      'phone_number': 'رقم الهاتف',
      'enter_phone': 'أدخل رقم الهاتف',
      'enter_otp': 'أدخل رمز التحقق',
      'verify': 'تحقق',
      'send_otp': 'إرسال الرمز',
      'no_subscription': 'لا يوجد رصيد كافٍ',
      'subscribe_now': 'اشحن الآن',
      'currency': 'ل.س',
      'syp': 'ليرة سورية',
      'commission': 'عمولة',
      'gym_earned': 'أرباح النادي',
      'athlete': 'رياضي',
      'gym_owner': 'صاحب نادي',
      'admin_role': 'مدير',
      'approve': 'موافقة',
      'reject': 'رفض',
      'pending': 'قيد المراجعة',
      'approved': 'تمت الموافقة',
      'rejected': 'مرفوض',
      'view_all': 'عرض الكل',
      'suggested_gyms': 'أندية مقترحة لك',
      'today_done': 'إنجاز اليوم! ✓',
      'low_balance': 'رصيد غير كافٍ',
      'no_plan': 'لا يوجد رصيد متاح',
    },
    'en': {
      'app_name': 'SportPass',
      'welcome_back': 'Welcome back',
      'home': 'Home',
      'wallet': 'Wallet',
      'partners': 'Partners',
      'activity': 'Activity',
      'login': 'Login',
      'logout': 'Logout',
    },
  };

  String tr(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  bool get isEnglish => locale.languageCode == 'en';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);
  String trd(String ar, String en) =>
      AppLocalizations.of(this).isEnglish ? en : ar;
}
