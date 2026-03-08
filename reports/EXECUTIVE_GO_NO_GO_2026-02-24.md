# SportPass Executive Go/No-Go (2026-02-24)

## القرار التنفيذي
- `NO-GO` للإطلاق العام الآن.
- `GO` لاختبار داخلي/مغلق فقط بعد تنفيذ البنود الحرجة أدناه.

## ما تم التحقق منه اليوم
1. فحص الجودة البرمجية:
- `flutter analyze` => ناجح (0 مشاكل).
- `flutter test` => ناجح (All tests passed).

2. قابلية بناء APK:
- تم بناء `app-release.apk` بنجاح.
- تم تشديد البناء بحيث يفشل `release` تلقائيًا إذا لا يوجد توقيع إنتاج.
- تم السماح ببناء محلي اختباري فقط عند تمرير علم صريح:
  - `ORG_GRADLE_PROJECT_allowDebugRelease=true flutter build apk --release`

3. تدقيق أمني سريع (Code + Config + DB scripts):
- تم إغلاق مخاطرة حرجة في `supabase/permissions_fix.sql` عبر حجب السكربت غير الآمن (deprecated/blocked).
- تقرير الأمن الموجود في `reports/SportPass_Security_Assessment_2026-02-22.html` لا يمثل SportPass الحالي (يحمل package مختلف `com.moica.moica`).
- في Android تم تفعيل سياسات backup/data extraction الصريحة وتعطيل النسخ الاحتياطي.

## البنود الحرجة قبل الإطلاق العام (P0)
1. **توقيع إنتاج حقيقي**
- إنشاء keystore إنتاج وربطه عبر `android/key.properties`.
- منع أي نشر لبناء موقّع Debug (تم تطبيق gate بالفعل).

2. **التحقق من تطبيق الصلاحيات في بيئة Supabase الفعلية**
- التأكد أن البيئات لا تحتوي آثار grants واسعة من سكربتات سابقة.
- اعتماد سياسة Least Privilege فقط عبر migrations المعتمدة.

3. **إعادة تقرير الأمن الرسمي على APK الصحيح**
- تنفيذ فحص جديد على `com.sportpass.app` بدل التقرير القديم.
- استخراج تقرير قابل للتقديم التنظيمي مع أدلة مطابقة للإصدار الحالي.

## بنود عالية الأولوية (P1)
1. إضافة اختبارات أمنية/تكامل لمسارات:
- تسجيل الدخول/الأدوار.
- شحن الرصيد/ledger.
- Check-in عبر QR.

2. مراجعة Functions الحساسة في Supabase (`SECURITY DEFINER`):
- توحيد نمط الحماية.
- إضافة `SET search_path` الصريح داخل الدوال الحساسة.

3. ضبط خط CI بسيط:
- Analyze + Test + Build + منع Debug release + فحص secrets + فحص SQL grants.

## البنود المتوسطة (P2)
1. تحديثات اعتماديات مختارة (أمنيًا) بدون كسر:
- `flutter_dotenv`, `go_router`, `mobile_scanner`, `permission_handler` وغيرها.
2. توثيق Runbook للإطلاق والرجوع السريع (Rollback).

## خطة التنفيذ المقترحة (7 أيام)
- اليوم 1: إعداد توقيع إنتاج + CI gate + تثبيت سياسة build.
- اليوم 2: مراجعة RLS/GRANT في بيئة Supabase الفعلية.
- اليوم 3: إعادة فحص أمني على APK الحالي + توثيق النتائج.
- اليوم 4: إصلاح أي High/Critical من التقرير الجديد.
- اليوم 5: اختبار Pilot مغلق (20–50 مستخدم).
- اليوم 6: مراقبة تشغيلية + إصلاحات سريعة.
- اليوم 7: قرار إطلاق عام (Go/No-Go) بناءً على مؤشرات واضحة.

## تعريف الجاهزية للإطلاق العام (Definition of Done)
- لا توجد ثغرات `Critical/High` مفتوحة.
- APK موقّع Production.
- CI يرفض أي Release غير مطابق.
- تقرير أمن حديث خاص بـ SportPass الحالي.
- تحقق وظيفي كامل لمسارات Auth/Wallet/QR/Admin.
