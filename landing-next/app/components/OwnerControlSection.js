const userTransparency = [
  "الرصيد الحالي يظهر مباشرة داخل المحفظة",
  "كل خصم يظهر مع التاريخ والوقت",
  "المتبقي بعد كل دخول واضح فورًا",
];

const gymTransparency = [
  "عدد الزوار لكل فرع",
  "أوقات الدخول الفعلية",
  "الإيراد وصافي الحصة بشكل مباشر",
];

export default function OwnerControlSection() {
  return (
    <section className="container section" id="transparency">
      <div className="section-head reveal">
        <p className="eyebrow">الشفافية للطرفين</p>
        <h2>بيانات واضحة للمستخدم والنادي</h2>
      </div>

      <div className="transparency-grid">
        <article className="transparency-card reveal">
          <h3>للمستخدم</h3>
          <ul>
            {userTransparency.map((point) => (
              <li key={point}>{point}</li>
            ))}
          </ul>
        </article>

        <article className="transparency-card reveal">
          <h3>للنادي</h3>
          <ul>
            {gymTransparency.map((point) => (
              <li key={point}>{point}</li>
            ))}
          </ul>
        </article>
      </div>
    </section>
  );
}
