# Android Release Signing (SportPass)

## الهدف
تفعيل توقيع إصدار الإنتاج (Release) لتطبيق SportPass ومنع أي بناء Release موقّع بـ Debug عن طريق الخطأ.

## ما تم اعتماده في المشروع
1. Gate أمني في `android/app/build.gradle.kts`:
- إذا لم يوجد `android/key.properties` أو keystore إنتاج => يفشل `flutter build apk --release`.
- يمكن تجاوز ذلك محليًا للاختبار فقط عبر:
  - `ORG_GRADLE_PROJECT_allowDebugRelease=true flutter build apk --release`

2. سكربت إعداد تلقائي:
- `tools/setup_android_release_signing.sh`

## إنشاء/تجديد keystore
من جذر المشروع:

```bash
./tools/setup_android_release_signing.sh
```

خيارات مفيدة:

```bash
./tools/setup_android_release_signing.sh --help
./tools/setup_android_release_signing.sh --force
./tools/setup_android_release_signing.sh --alias sportpass-release --dname "CN=SportPass Release,O=SportPass,C=SY"
```

## الملفات الناتجة
- `android/key.properties`  (غير متتبع في Git)
- `android/keystore/sportpass-release.jks` (غير متتبع)
- `android/keystore/release_signing_credentials.txt` (غير متتبع)

## بناء Release

```bash
flutter build apk --release
```

## تحقق التوقيع

```bash
tools/android-build-tools/android-16/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

يجب أن ترى:
- `Signer #1 certificate DN: CN=SportPass Release, O=SportPass, C=SY`

## متطلبات الحوكمة
- احفظ `sportpass-release.jks` + كلمات المرور في خزنة آمنة (offline vault).
- لا تشارك `key.properties` أو ملف كلمات المرور عبر Git أو قنوات عامة.
- فقدان هذا المفتاح يعني عدم القدرة على تحديث نفس package id مستقبلًا.
