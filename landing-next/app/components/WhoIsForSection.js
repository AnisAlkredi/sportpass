const users = [
  "من لا يريد اشتراكًا شهريًا ثابتًا",
  "من يفضّل الدفع المرن حسب عدد الزيارات",
  "من يريد دخول سريع وسعر واضح قبل التمرين",
];

const gyms = [
  "نوادٍ تريد عملاء إضافيين بدون تغيير نموذجها الحالي",
  "نوادٍ تبحث عن قناة دخل إضافية قابلة للقياس",
  "نوادٍ تريد تشغيل دخول منظم عبر (QR)",
];

export default function WhoIsForSection() {
  return (
    <section className="container section" id="who-is-for">
      <div className="section-head reveal">
        <p className="eyebrow">لمن SportPass؟</p>
        <h2>مصمم للمستخدمين والنوادي معًا</h2>
      </div>

      <div className="audience-grid">
        <article className="audience-card reveal">
          <h3>للمستخدمين</h3>
          <ul>
            {users.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </article>

        <article className="audience-card reveal">
          <h3>للنوادي</h3>
          <ul>
            {gyms.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </article>
      </div>
    </section>
  );
}
