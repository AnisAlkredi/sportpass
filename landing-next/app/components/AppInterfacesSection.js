"use client";

import Image from "next/image";
import { useMemo, useState } from "react";

const interfaces = [
  {
    id: "home",
    title: "الرئيسية السريعة",
    subtitle: "رصيد + إجراءات مباشرة في أول شاشة",
    src: "/screenshots/shot_current.png",
    points: ["زر Check-in واضح", "وصول سريع للخريطة", "واجهة نظيفة للاستخدام اليومي"],
  },
  {
    id: "qr",
    title: "شاشة الدخول عبر QR",
    subtitle: "مسح فوري مع خيار إدخال يدوي احتياطي",
    src: "/screenshots/checkin.png",
    points: ["توجيه مباشر للمستخدم", "واجهة تركيز بدون تشتيت", "جاهزة للتشغيل عند الباب"],
  },
  {
    id: "wallet",
    title: "المحفظة وسجل الرصيد",
    subtitle: "شفافية كاملة لكل حركة مالية",
    src: "/screenshots/shot_wallet_try1.png",
    points: ["عرض الرصيد الحالي", "سجل الشحن والعمليات", "سهولة تتبع المستخدم للمدفوعات"],
  },
  {
    id: "scan",
    title: "الصفحة الرئيسية الكاملة",
    subtitle: "عرض شامل للرصيد والإجراءات في شاشة واحدة",
    src: "/screenshots/home.png",
    points: ["وضوح حالة الرصيد", "إجراءات سريعة متاحة", "تنقل مباشر لأهم المهام"],
  },
];

export default function AppInterfacesSection() {
  const [activeId, setActiveId] = useState(interfaces[0].id);

  const activeInterface = useMemo(
    () => interfaces.find((item) => item.id === activeId) || interfaces[0],
    [activeId]
  );

  return (
    <section className="container section" id="app-interfaces">
      <div className="section-head reveal">
        <p className="eyebrow">واجهات التطبيق</p>
        <h2>عرض منسق وواضح لتجربة SportPass</h2>
      </div>

      <p className="interfaces-lead reveal">
        اختر الواجهة من القائمة لمعاينة التفاصيل. الهدف هنا إظهار تجربة متناسقة بصريًا من أول
        شاشة حتى تنفيذ الدخول والمحفظة.
      </p>

      <div className="interfaces-layout">
        <article className="interface-stage reveal">
          <div className="interface-phone">
            <Image
              src={activeInterface.src}
              alt={activeInterface.title}
              width={1080}
              height={2400}
              className="hero-shot"
            />
          </div>

          <div className="interface-meta">
            <h3>{activeInterface.title}</h3>
            <p>{activeInterface.subtitle}</p>
            <ul>
              {activeInterface.points.map((point) => (
                <li key={point}>{point}</li>
              ))}
            </ul>
          </div>
        </article>

        <aside className="interface-selector reveal">
          {interfaces.map((item) => (
            <button
              key={item.id}
              type="button"
              className={`selector-item ${activeId === item.id ? "is-active" : ""}`}
              onClick={() => setActiveId(item.id)}
            >
              <div className="selector-thumb">
                <Image src={item.src} alt={item.title} width={1080} height={2400} />
              </div>
              <div className="selector-copy">
                <strong>{item.title}</strong>
                <span>{item.subtitle}</span>
              </div>
            </button>
          ))}
        </aside>
      </div>

      <div className="screens-strip reveal" aria-label="معاينة إضافية للواجهات">
        {interfaces.map((item) => (
          <div className="strip-item" key={`strip-${item.id}`}>
            <Image src={item.src} alt={item.title} width={1080} height={2400} />
          </div>
        ))}
      </div>
    </section>
  );
}
