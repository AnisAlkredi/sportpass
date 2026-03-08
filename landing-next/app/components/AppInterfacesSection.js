import Image from "next/image";

const interfaces = [
  {
    id: "home",
    title: "الرئيسية",
    subtitle: "QR + المحافظ + إجراءات سريعة",
    src: "/screenshots/shot_current.png",
  },
  {
    id: "checkin",
    title: "شاشة الدخول",
    subtitle: "مسح QR مع تأكيد لحظي للنتيجة",
    src: "/screenshots/checkin.png",
  },
  {
    id: "wallet",
    title: "المحفظة",
    subtitle: "رصيد واضح وسجل حركات مباشر",
    src: "/screenshots/shot_wallet_try1.png",
  },
  {
    id: "map",
    title: "الخريطة",
    subtitle: "اكتشاف النوادي الشريكة بسهولة",
    src: "/screenshots/shot_map_try1.png",
  },
  {
    id: "activity",
    title: "سجل النشاط",
    subtitle: "تتبع زياراتك وتاريخ دخولك",
    src: "/screenshots/shot_history_try1.png",
  },
];

export default function AppInterfacesSection() {
  return (
    <section className="container section" id="app-interfaces">
      <div className="section-head reveal">
        <p className="eyebrow">واجهات التطبيق</p>
        <h2>تجربة استخدام مصممة للإقناع والتنفيذ السريع</h2>
      </div>

      <p className="section-lead reveal">
        من أول تحميل حتى أول check-in، الواجهات تبقي المستخدم داخل مسار بسيط وواضح يرفع معدل
        التحويل داخل النادي.
      </p>

      <div className="interfaces-grid">
        {interfaces.map((screen) => (
          <article className="interface-card reveal" key={screen.id}>
            <div className="interface-frame">
              <Image src={screen.src} alt={screen.title} width={1080} height={2400} />
            </div>
            <h3>{screen.title}</h3>
            <p>{screen.subtitle}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
