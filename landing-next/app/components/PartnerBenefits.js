import LineIcon from "./LineIcon";

const benefitCards = [
  {
    icon: "noFee",
    title: "لا يوجد اشتراك شهري",
    text: "تبدأ بدون أي تكلفة ثابتة. تدفع المنصة حصتها فقط عند وجود دخول فعلي.",
  },
  {
    icon: "extraTraffic",
    title: "دخول إضافي فقط",
    text: "SportPass لا يلغي نظام ناديك؛ بل يضيف لك فئة عملاء جديدة فوق اشتراكاتك المعتادة.",
  },
  {
    icon: "qr",
    title: "QR سريع عند الباب",
    text: "كل فرع يحصل على QR واضح للدخول السريع بدون ازدحام أو تعقيد تشغيلي.",
  },
  {
    icon: "transparency",
    title: "شفافية مالية كاملة",
    text: "كل عملية دخول موثقة. تعرف عدد الزيارات وقيمة حصتك بشكل لحظي.",
  },
  {
    icon: "dashboard",
    title: "لوحة أرباح واضحة",
    text: "تقارير مبسطة تساعدك تعرف الفروع الأكثر نشاطًا ومواعيد الذروة اليومية.",
  },
  {
    icon: "localMarket",
    title: "مناسب للسوق السوري",
    text: "هيكل تسعير وتجربة استخدام مصممة فعليًا لطبيعة الأندية الرياضية المحلية.",
  },
];

export default function PartnerBenefits() {
  return (
    <section className="container section" id="partner-benefits">
      <div className="section-head reveal">
        <p className="eyebrow">لماذا ينضم صاحب النادي؟</p>
        <h2>نمو إضافي بدون المخاطرة بتشغيلك الحالي</h2>
      </div>

      <div className="benefits-grid">
        {benefitCards.map((card) => (
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
    </section>
  );
}
