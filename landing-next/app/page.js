"use client";

import Image from "next/image";
import { useState } from "react";

const heroShots = [
  { key: "home", label: "الرئيسية", src: "/screenshots/shot_current.png" },
  { key: "qr", label: "QR", src: "/screenshots/checkin.png" },
  { key: "wallet", label: "المحفظة", src: "/screenshots/shot_wallet_try1.png" },
  { key: "map", label: "الخريطة", src: "/screenshots/shot_map_try1.png" },
];

export default function HomePage() {
  const [activeShot, setActiveShot] = useState(heroShots[0]);

  return (
    <>
      <div className="orb orb-a" />
      <div className="orb orb-b" />
      <div className="orb orb-c" />

      <header className="topbar container">
        <a href="#top" className="brand" aria-label="SportPass">
          <span className="brand-mark">SP</span>
          <span className="brand-text">SportPass</span>
        </a>

        <nav className="topnav">
          <a href="#features">المزايا</a>
          <a href="#how">كيف يعمل</a>
          <a href="#screens">الواجهات</a>
        </nav>
      </header>

      <main id="top">
        <section className="hero container section">
          <div className="hero-copy reveal">
            <p className="eyebrow">منصة ذكية لسوق الأندية الرياضية</p>
            <h1>ادخل النادي بثواني عبر QR وادفع من محفظتك مباشرة</h1>
            <p className="lead">
              SportPass يجمع اللاعب، النادي، والإدارة في نظام واحد: شحن رصيد، اكتشاف مراكز،
              وتسجيل دخول فوري بدون فوضى.
            </p>
            <div className="cta-row">
              <a href="#cta" className="btn btn-primary">
                ابدأ الإطلاق
              </a>
              <a href="#screens" className="btn btn-outline">
                شاهد الواجهات
              </a>
            </div>
            <ul className="badge-row">
              <li>Check-in QR فوري</li>
              <li>محفظة رقمية واضحة</li>
              <li>إدارة صلاحيات للأدوار</li>
            </ul>
          </div>

          <div className="hero-visual reveal">
            <div className="phone">
              <Image
                key={activeShot.src}
                src={activeShot.src}
                alt={`واجهة ${activeShot.label}`}
                width={1080}
                height={2400}
                priority
                className="hero-shot"
              />
            </div>

            <div className="switcher" role="tablist" aria-label="واجهة التطبيق">
              {heroShots.map((shot) => (
                <button
                  key={shot.key}
                  type="button"
                  className={activeShot.key === shot.key ? "is-active" : ""}
                  onClick={() => setActiveShot(shot)}
                >
                  {shot.label}
                </button>
              ))}
            </div>
          </div>
        </section>

        <section className="container section stats" id="features">
          <article className="stat reveal">
            <span className="stat-title">تدفق دخول واضح</span>
            <p>المستخدم يصل للمركز، يفتح الكاميرا، ويدخل فورًا عبر QR.</p>
          </article>
          <article className="stat reveal">
            <span className="stat-title">محاسبة دقيقة</span>
            <p>المحفظة وسجل العمليات يوضحان كل حركة رصيد بشكل مباشر.</p>
          </article>
          <article className="stat reveal">
            <span className="stat-title">جاهز للتوسع</span>
            <p>دعم أصحاب الأندية، موافقات الإدارة، وخريطة مراكز في تجربة موحدة.</p>
          </article>
        </section>

        <section className="container section flow" id="how">
          <div className="section-head reveal">
            <p className="eyebrow">كيف يعمل</p>
            <h2>3 خطوات وتكون العملية كاملة</h2>
          </div>
          <div className="flow-grid">
            <article className="flow-card reveal">
              <span className="flow-num">01</span>
              <h3>سجل وأنشئ محفظتك</h3>
              <p>إنشاء حساب بالبريد الإلكتروني ثم شحن الرصيد ليصبح الحساب جاهزًا للاستخدام.</p>
            </article>
            <article className="flow-card reveal">
              <span className="flow-num">02</span>
              <h3>اختر النادي الأقرب</h3>
              <p>من الخريطة تشوف المراكز، السعر، والاتجاهات قبل الوصول إلى الموقع.</p>
            </article>
            <article className="flow-card reveal">
              <span className="flow-num">03</span>
              <h3>امسح QR وادخل</h3>
              <p>التسجيل يتم فورًا مع خصم الرصيد وتوثيق العملية في السجل.</p>
            </article>
          </div>
        </section>

        <section className="container section gallery" id="screens">
          <div className="section-head reveal">
            <p className="eyebrow">واجهات حقيقية من التطبيق</p>
            <h2>تصميم عربي واضح وتجربة سريعة</h2>
          </div>
          <div className="gallery-grid">
            <figure className="shot reveal">
              <Image
                src="/screenshots/shot_current.png"
                alt="الواجهة الرئيسية"
                width={1080}
                height={2400}
              />
              <figcaption>الرئيسية: رصيد + إجراءات سريعة</figcaption>
            </figure>
            <figure className="shot reveal">
              <Image src="/screenshots/checkin.png" alt="واجهة مسح الكود" width={1080} height={2400} />
              <figcaption>QR Scanner: دخول سريع أو إدخال يدوي</figcaption>
            </figure>
            <figure className="shot reveal">
              <Image src="/screenshots/shot_wallet_try1.png" alt="المحفظة" width={1080} height={2400} />
              <figcaption>المحفظة: رصيد وسجل شحن واضح</figcaption>
            </figure>
            <figure className="shot reveal">
              <Image src="/screenshots/shot_map_try1.png" alt="الخريطة" width={1080} height={2400} />
              <figcaption>الخريطة: اكتشاف المراكز القريبة</figcaption>
            </figure>
          </div>
        </section>

        <section className="container section audience">
          <div className="section-head reveal">
            <p className="eyebrow">لمن هذا النظام</p>
            <h2>قيمة عملية لكل طرف</h2>
          </div>
          <div className="audience-grid">
            <article className="audience-card reveal">
              <h3>لللاعب</h3>
              <p>وصول أسرع، شفافية في الرصيد، وتجربة دخول بدون انتظار.</p>
            </article>
            <article className="audience-card reveal">
              <h3>لصاحب النادي</h3>
              <p>تنظيم الحضور، إدارة أسهل للدخول، وسجل واضح للعمليات اليومية.</p>
            </article>
            <article className="audience-card reveal">
              <h3>للإدارة</h3>
              <p>صلاحيات مركزية، موافقات دقيقة، وتحكم كامل بدورة العمل.</p>
            </article>
          </div>
        </section>

        <section className="container section cta-block" id="cta">
          <p className="eyebrow">جاهز للنشر</p>
          <h2>Landing Page مبنية بـ Next.js وجاهزة للرفع على Vercel</h2>
          <p>اربط الريبو في Vercel واختر مجلد الجذر `landing-next` وسيتم النشر مباشرة.</p>
          <div className="cta-row center">
            <a
              className="btn btn-primary"
              href="https://github.com/AnisAlkredi/sportpass"
              target="_blank"
              rel="noopener noreferrer"
            >
              افتح المشروع على GitHub
            </a>
          </div>
        </section>
      </main>
    </>
  );
}
