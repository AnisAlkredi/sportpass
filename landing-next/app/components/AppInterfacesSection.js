import Image from "next/image";

const interfaces = [
  {
    id: "map",
    title: "واجهة الخريطة",
    subtitle: "اكتشاف المراكز القريبة بسهولة",
    src: "/screenshots/shot_map_try1.png",
  },
  {
    id: "wallet",
    title: "واجهة المحفظة",
    subtitle: "رصيد واضح وسجل عمليات مباشر",
    src: "/screenshots/shot_wallet_try1.png",
  },
  {
    id: "checkin",
    title: "واجهة الدخول عبر QR",
    subtitle: "تنفيذ check-in بسرعة عند الباب",
    src: "/screenshots/checkin.png",
  },
  {
    id: "home",
    title: "الواجهة الرئيسية",
    subtitle: "كل الإجراءات اليومية في مكان واحد",
    src: "/screenshots/shot_current.png",
  },
];

export default function AppInterfacesSection() {
  return (
    <section className="container section" id="app-interfaces">
      <div className="section-head reveal">
        <p className="eyebrow">واجهات التطبيق</p>
        <h2>تصميم منسق وتجربة سريعة للمستخدم وصاحب النادي</h2>
      </div>

      <p className="interfaces-lead reveal">
        واجهات واضحة ومترابطة من لحظة اختيار النادي حتى تنفيذ الدخول ومتابعة الرصيد.
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
