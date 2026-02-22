const entriesToday = [
  { member: "مستخدم #A12", branch: "فرع المزة", time: "10:14", amount: "8,000 ل.س" },
  { member: "مستخدم #B39", branch: "فرع المزة", time: "12:32", amount: "8,000 ل.س" },
  { member: "مستخدم #C01", branch: "فرع أبو رمانة", time: "17:05", amount: "12,000 ل.س" },
];

const metrics = [
  { label: "زيارات اليوم", value: "23" },
  { label: "دخل اليوم الإجمالي", value: "212,000 ل.س" },
  { label: "حصة النادي (80%)", value: "169,600 ل.س" },
];

export default function OwnerControlSection() {
  return (
    <section className="container section" id="owner-control">
      <div className="section-head reveal">
        <p className="eyebrow">الإدارة المالية والتشغيل</p>
        <h2>ارتاح من جمع المصاري يدويًا وخلي كل شيء موثق</h2>
      </div>

      <p className="interfaces-lead reveal">
        مع SportPass صاحب النادي يشوف مباشرة: مين دخل، إيمت دخل، وعلى أي فرع، وكم حصته لحظيًا.
        كل عملية محسوبة تلقائيًا بدون دفتر يدوي أو جرد يومي مرهق.
      </p>

      <div className="owner-control-grid">
        <article className="owner-panel reveal">
          <h3>لوحة المتابعة اليومية</h3>
          <div className="owner-metrics">
            {metrics.map((metric) => (
              <div key={metric.label}>
                <span>{metric.label}</span>
                <strong>{metric.value}</strong>
              </div>
            ))}
          </div>
        </article>

        <article className="owner-panel reveal">
          <h3>آخر عمليات الدخول</h3>
          <div className="entry-table">
            <div className="entry-head">
              <span>المستخدم</span>
              <span>الفرع</span>
              <span>الوقت</span>
              <span>القيمة</span>
            </div>
            {entriesToday.map((entry) => (
              <div key={`${entry.member}-${entry.time}`} className="entry-row">
                <span>{entry.member}</span>
                <span>{entry.branch}</span>
                <span>{entry.time}</span>
                <span>{entry.amount}</span>
              </div>
            ))}
          </div>
        </article>
      </div>
    </section>
  );
}
