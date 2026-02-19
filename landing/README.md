# SportPass Landing

صفحة هبوط تسويقية جاهزة للنشر.

## تشغيل محلي سريع

```bash
cd /home/programming/Downloads/SportPass_v2
python3 -m http.server 4173
```

ثم افتح:

`http://localhost:4173/landing/`

## النشر على Vercel

- ملف `vercel.json` في جذر المشروع يوجه الدومين مباشرة إلى صفحة `landing`.
- يكفي ربط المستودع بـ Vercel والضغط على Deploy.
