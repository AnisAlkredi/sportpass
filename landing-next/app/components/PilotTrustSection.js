const trustPoints = [
  "عدد محدود من النوادي في أول 3 أشهر",
  "مراجعة واعتماد يدوي لكل شريك قبل التفعيل",
  "تهيئة تشغيلية مباشرة للفريق داخل النادي",
  "متابعة أسبوعية لمؤشرات الزيارات والدخل",
  "نظام موحد مناسب للسوق السوري",
];

const pilotPlan = [
  { month: "الشهر 1", task: "اعتماد الشركاء وتجهيز الفروع" },
  { month: "الشهر 2", task: "تشغيل فعلي + تحسين التحويل داخل النادي" },
  { month: "الشهر 3", task: "تقييم النتائج وتوسيع الشراكة" },
];

export default function PilotTrustSection() {
  return (
    <section className="container section" id="pilot-trust">
      <div className="section-head reveal">
        <p className="eyebrow">الثقة والمرحلة التجريبية</p>
        <h2>برنامج مؤسسين مصمم للنوادي الجادة في النمو</h2>
      </div>

      <div className="trust-layout reveal">
        <ul className="trust-list">
          {trustPoints.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>

        <div className="pilot-timeline">
          {pilotPlan.map((item) => (
            <div key={item.month}>
              <span>{item.month}</span>
              <p>{item.task}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
