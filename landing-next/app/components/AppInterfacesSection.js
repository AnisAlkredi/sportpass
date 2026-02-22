import Image from "next/image";

const showcaseCards = [
  {
    id: "checkin",
    title: "دخول سريع عبر QR",
    caption: "واجهة المسح مع خيار الإدخال اليدوي للطوارئ",
    src: "/screenshots/checkin.png",
    className: "screen-card screen-feature",
  },
  {
    id: "home",
    title: "واجهة رئيسية واضحة",
    caption: "رصيد سريع وإجراءات يومية في أول شاشة",
    src: "/screenshots/shot_current.png",
    className: "screen-card",
  },
  {
    id: "wallet",
    title: "محفظة وسجل رصيد",
    caption: "عرض الرصيد وحركات الشحن بدقة",
    src: "/screenshots/shot_wallet_try1.png",
    className: "screen-card",
  },
  {
    id: "map",
    title: "اكتشاف المراكز",
    caption: "الخريطة لتوجيه المستخدم للنادي الأقرب",
    src: "/screenshots/shot_map_try1.png",
    className: "screen-card",
  },
  {
    id: "history",
    title: "سجل النشاط",
    caption: "شفافية كاملة لكل العمليات",
    src: "/screenshots/shot_history_try1.png",
    className: "screen-card",
  },
  {
    id: "home-alt",
    title: "تفاصيل التشغيل اليومي",
    caption: "كل ما يحتاجه اللاعب في دقائق",
    src: "/screenshots/home.png",
    className: "screen-card",
  },
  {
    id: "wallet-alt",
    title: "حالة المحفظة",
    caption: "ملخص فوري لحركة الرصيد",
    src: "/screenshots/wallet.png",
    className: "screen-card",
  },
];

export default function AppInterfacesSection() {
  return (
    <section className="container section" id="app-interfaces">
      <div className="section-head reveal">
        <p className="eyebrow">واجهات التطبيق</p>
        <h2>تجربة بصرية غنية توضح مسار التشغيل كاملًا</h2>
      </div>

      <p className="interfaces-lead reveal">
        من مسح QR إلى المحفظة والخريطة وسجل النشاط، كل شاشة مصممة لتقليل الاحتكاك وتسريع
        الدخول، مع تجربة واضحة لصاحب النادي والمستخدم.
      </p>

      <div className="screens-bento">
        {showcaseCards.map((card) => (
          <article className={`${card.className} reveal`} key={card.id}>
            <div className="screen-frame">
              <Image src={card.src} alt={card.title} width={1080} height={2400} />
            </div>
            <div className="screen-copy">
              <h3>{card.title}</h3>
              <p>{card.caption}</p>
            </div>
          </article>
        ))}
      </div>

      <div className="screens-strip reveal" aria-label="معاينة سريعة للواجهات">
        {showcaseCards.map((card) => (
          <div className="strip-item" key={`strip-${card.id}`}>
            <Image src={card.src} alt={card.title} width={1080} height={2400} />
          </div>
        ))}
      </div>
    </section>
  );
}
