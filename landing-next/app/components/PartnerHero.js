import Image from "next/image";

const ownerPoints = [
  "زبائن إضافيون بدون مخاطرة",
  "احتفظ باشتراكاتك الشهرية كما هي",
  "تحصل على 80% من كل زيارة",
  "لا رسوم شهرية",
  "لوحة تحكم واضحة للإحصائيات",
];

export default function PartnerHero() {
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
        <div className="hero-showcase">
          <div className="hero-preview hero-preview-main">
            <Image
              src="/screenshots/checkin.png"
              alt="نظام دخول QR"
              width={1080}
              height={2400}
              priority
              className="hero-shot"
            />
            <span>دخول QR</span>
          </div>
          <div className="hero-preview">
            <Image
              src="/screenshots/shot_current.png"
              alt="واجهة المستخدم الرئيسية"
              width={1080}
              height={2400}
              className="hero-shot"
            />
            <span>الواجهة الرئيسية</span>
          </div>
          <div className="hero-preview">
            <Image
              src="/screenshots/shot_wallet_try1.png"
              alt="المحفظة وسجل العمليات"
              width={1080}
              height={2400}
              className="hero-shot"
            />
            <span>المحفظة</span>
          </div>
        </div>

        <div className="revenue-box">
          <p>تقسيم الإيراد لكل زيارة</p>
          <div className="revenue-split">
            <span>80% للنادي</span>
            <span>20% للمنصة</span>
          </div>
          <small>بدون رسوم ثابتة أو اشتراك شهري</small>
        </div>
      </div>
    </section>
  );
}
