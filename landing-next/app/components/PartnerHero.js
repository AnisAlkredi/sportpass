"use client";

import Image from "next/image";
import { useEffect, useState } from "react";

const heroScreens = [
  { id: "home", label: "الرئيسية", src: "/screenshots/shot_current.png", alt: "الواجهة الرئيسية" },
  { id: "wallet", label: "المحفظة", src: "/screenshots/shot_wallet_try1.png", alt: "واجهة المحفظة" },
  { id: "map", label: "الخريطة", src: "/screenshots/shot_map_try1.png", alt: "واجهة الخريطة" },
  { id: "checkin", label: "QR", src: "/screenshots/checkin.png", alt: "واجهة مسح QR" },
];

const quickPoints = [
  "بدون اشتراك شهري",
  "سعر دخول واضح لكل نادي",
  "خصم تلقائي عند مسح (QR)",
  "دخول فوري عند الباب",
];

const AUTO_ROTATE_MS = 4400;

export default function PartnerHero() {
  const [activeIndex, setActiveIndex] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % heroScreens.length);
    }, AUTO_ROTATE_MS);
    return () => clearInterval(timer);
  }, []);

  const activeScreen = heroScreens[activeIndex];

  return (
    <section className="hero container section" id="top">
      <div className="hero-copy reveal">
        <p className="hero-tag">منصة دخول رياضي مرنة في سوريا</p>
        <h1>ادخل النادي فورًا بدون اشتراك شهري</h1>
        <p className="lead">
          SportPass يعمل بنموذج ادفع حسب الاستخدام (Pay as you go): اشحن محفظتك، اختر النادي،
          امسح (QR)، وتدرّب. الدفع فقط عند الدخول.
        </p>

        <ul className="promise-grid">
          {quickPoints.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>

        <div className="cta-row">
          <a href="#apk-download" className="btn btn-primary">
            ابدأ الآن
          </a>
          <a href="#partner-join" className="btn btn-outline">
            سجّل ناديك
          </a>
        </div>

        <p className="hero-trustline">بدون اشتراك شهري — ادفع فقط عند الدخول</p>
      </div>

      <div className="hero-visual reveal">
        <div className="hero-phone-card">
          <div className="hero-phone-head">
            <p>واجهة التطبيق</p>
            <span>{activeScreen.label}</span>
          </div>

          <div className="hero-phone-frame">
            <Image
              src={activeScreen.src}
              alt={activeScreen.alt}
              width={1080}
              height={2400}
              className="hero-shot"
              priority={activeIndex === 0}
            />
          </div>

          <div className="hero-tabs" role="tablist" aria-label="تبديل الواجهات">
            {heroScreens.map((screen, index) => (
              <button
                key={screen.id}
                type="button"
                role="tab"
                aria-selected={activeIndex === index}
                className={`hero-tab${activeIndex === index ? " is-active" : ""}`}
                onClick={() => setActiveIndex(index)}
              >
                {screen.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
