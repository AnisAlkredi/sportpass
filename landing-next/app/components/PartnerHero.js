"use client";

import Image from "next/image";
import { useEffect, useState } from "react";

const ownerPoints = [
  "زبائن إضافيون بدون مخاطرة",
  "احتفظ باشتراكاتك الشهرية كما هي",
  "تحصل على 80% من كل زيارة",
  "لا رسوم شهرية",
  "لوحة تحكم واضحة للإحصائيات",
];

const heroScreens = [
  {
    id: "home",
    label: "الرئيسية",
    src: "/screenshots/shot_current.png",
    alt: "واجهة المستخدم الرئيسية في تطبيق SportPass",
    caption: "واجهة سريعة تضع الدفع وQR والخرائط أمام العميل مباشرة.",
  },
  {
    id: "checkin",
    label: "QR",
    src: "/screenshots/checkin.png",
    alt: "واجهة تسجيل دخول النادي عبر QR",
    caption: "دخول فوري عبر المسح من دون تعقيد وبمتابعة لحظية.",
  },
  {
    id: "wallet",
    label: "المحفظة",
    src: "/screenshots/shot_wallet_try1.png",
    alt: "واجهة المحفظة وسجل الرصيد",
    caption: "رصيد وسجل واضحان لرفع الثقة وتقليل مشاكل التحصيل.",
  },
  {
    id: "map",
    label: "الخريطة",
    src: "/screenshots/shot_map_try1.png",
    alt: "واجهة الخريطة لاكتشاف النوادي",
    caption: "ظهور ناديك على الخريطة يجلب عملاء جدد قريبين من موقعك.",
  },
];

const AUTO_ROTATE_MS = 4200;

export default function PartnerHero() {
  const [activeScreenIndex, setActiveScreenIndex] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setActiveScreenIndex((current) => (current + 1) % heroScreens.length);
    }, AUTO_ROTATE_MS);

    return () => clearInterval(timer);
  }, []);

  const activeScreen = heroScreens[activeScreenIndex];

  return (
    <section className="hero container section" id="top">
      <div className="hero-copy reveal">
        <p className="eyebrow">برنامج الشركاء - السوق السوري</p>
        <h1>اجذب زبائن جدد بدون تغيير نظام ناديك الحالي</h1>
        <p className="lead">
          SportPass يساعدك على استقبال عملاء جدد بنظام QR بسيط مع تتبع أرباحك لحظة بلحظة.
        </p>

        <ul className="badge-row">
          {ownerPoints.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>

        <div className="cta-row">
          <a href="#partner-join" className="btn btn-primary">
            انضم كشريك الآن
          </a>
          <a href="#owner-flow" className="btn btn-outline">
            شاهد كيف يعمل النظام
          </a>
        </div>
      </div>

      <div className="hero-visual reveal">
        <div className="hero-device">
          <div className="hero-device-frame">
            <Image
              src={activeScreen.src}
              alt={activeScreen.alt}
              width={1080}
              height={2400}
              priority={activeScreenIndex === 0}
              className="hero-shot"
            />
          </div>
          <p className="hero-screen-note">{activeScreen.caption}</p>
        </div>

        <div className="hero-tabs" role="tablist" aria-label="تبديل واجهات التطبيق">
          {heroScreens.map((screen, index) => (
            <button
              type="button"
              key={screen.id}
              role="tab"
              aria-selected={activeScreenIndex === index}
              className={`hero-tab${activeScreenIndex === index ? " is-active" : ""}`}
              onClick={() => setActiveScreenIndex(index)}
            >
              {screen.label}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
