import LineIcon from "./LineIcon";

const gymPoints = [
  {
    icon: "extraTraffic",
    title: "عملاء جدد بدون تغيير نظامك",
    text: "تستقبل زوارًا إضافيين بدون المساس باشتراكات النادي الحالية.",
  },
  {
    icon: "noFee",
    title: "لا رسوم شهرية ثابتة",
    text: "الدفع للمنصة مرتبط بالدخولات الفعلية فقط.",
  },
  {
    icon: "qr",
    title: "تشغيل بسيط عند الباب",
    text: "(QR) واضح لكل فرع لتسريع الدخول وتقليل الضغط على الاستقبال.",
  },
  {
    icon: "dashboard",
    title: "لوحة تحكم تشغيلية",
    text: "تشوف الزيارات، أوقات الدخول، والإيراد لكل فرع بشكل لحظي.",
  },
];

export default function PartnerBenefits() {
  return (
    <section className="container section" id="gym-benefits">
      <div className="section-head reveal">
        <p className="eyebrow">مزايا للنوادي</p>
        <h2>دخل إضافي واضح بدون تعقيد تشغيلي</h2>
      </div>

      <div className="benefits-grid">
        {gymPoints.map((card) => (
          <article className="benefit-card reveal" key={card.title}>
            <div className="benefit-card-head">
              <span className="icon-badge" aria-hidden="true">
                <LineIcon name={card.icon} />
              </span>
              <h3>{card.title}</h3>
            </div>
            <p>{card.text}</p>
          </article>
        ))}
      </div>

      <article className="revenue-share-card reveal" aria-label="تقسيم الإيراد">
        <h3>تقسيم الإيراد</h3>
        <p>واضح وثابت لكل دخول عبر التطبيق:</p>
        <div className="share-lines">
          <strong>80% للنادي</strong>
          <strong>20% للمنصة</strong>
        </div>
      </article>
    </section>
  );
}
