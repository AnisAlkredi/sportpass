const userPoints = [
  "لا التزام شهري ولا عقود طويلة",
  "تدفع فقط عندما تستخدم",
  "محفظة واضحة مع رصيد محدث",
  "سجل زيارات وخصومات بعد كل دخول",
  "تصفح النوادي وسعر الدخول قبل الوصول",
  "دخول سريع عبر (QR) عند المدخل",
];

export default function UserSection() {
  return (
    <section className="container section user-section" id="user-benefits">
      <div className="section-head reveal">
        <p className="eyebrow">مزايا للمستخدم</p>
        <h2>تمرين مرن بدون اشتراك</h2>
      </div>

      <article className="user-card reveal" id="apk-download">
        <div className="user-copy">
          <p>هذا النموذج مناسب لمن يريد التمرين بمرونة كاملة بدون دفع شهري مسبق.</p>
          <ul>
            {userPoints.map((point) => (
              <li key={point}>{point}</li>
            ))}
          </ul>
        </div>

        <div className="cta-row">
          <a href="/apk/sportpass.apk" className="btn btn-primary" download>
            ابدأ الآن
          </a>
          <a href="#partner-join" className="btn btn-outline">
            تواصل معنا
          </a>
        </div>
      </article>
    </section>
  );
}
