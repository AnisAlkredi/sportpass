const trustPoints = [
  "برنامج شركاء المرحلة الأولى لمدة 3 أشهر",
  "عدد محدود من النوادي في البداية",
  "مراجعة واعتماد يدوي لضمان الجودة",
  "فريق دعم تشغيلي مباشر خلال فترة التجربة",
  "مصمم خصيصًا للسوق السوري",
];

export default function PilotTrustSection() {
  return (
    <section className="container section" id="pilot-trust">
      <div className="section-head reveal">
        <p className="eyebrow">الثقة والمرحلة التجريبية</p>
        <h2>انضم مبكرًا واستفد من برنامج الشركاء المؤسسين</h2>
      </div>

      <div className="trust-layout reveal">
        <ul className="trust-list">
          {trustPoints.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>

        <div className="pilot-timeline">
          <div>
            <span>الشهر 1</span>
            <p>تجهيز الحسابات والفروع</p>
          </div>
          <div>
            <span>الشهر 2</span>
            <p>تشغيل فعلي وتتبع الأداء</p>
          </div>
          <div>
            <span>الشهر 3</span>
            <p>تقييم النتائج وخطة التوسع</p>
          </div>
        </div>
      </div>
    </section>
  );
}
