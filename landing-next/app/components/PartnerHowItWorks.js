import LineIcon from "./LineIcon";

const steps = [
  {
    number: "01",
    icon: "register",
    title: "سجّل ناديك وبياناتك",
    text: "ترسل بيانات النادي الأساسية، الفريق يراجع الطلب بسرعة ويبدأ تجهيز الحساب.",
  },
  {
    number: "02",
    icon: "pricing",
    title: "أضف الفروع وحدد السعر الأساسي",
    text: "تحدد الفروع المتاحة وسعر الدخول لكل فرع ضمن لوحة إدارة واضحة وبسيطة.",
  },
  {
    number: "03",
    icon: "scan",
    title: "استخرج QR واطبعه عند الباب",
    text: "كل زيارة عبر SportPass تُسجل تلقائيًا ويظهر نصيب النادي فورًا في لوحة الأرباح.",
  },
];

export default function PartnerHowItWorks() {
  return (
    <section className="container section" id="owner-flow">
      <div className="section-head reveal">
        <p className="eyebrow">كيف يعمل النظام لصاحب النادي</p>
        <h2>تشغيل بسيط من أول يوم</h2>
      </div>

      <div className="flow-grid">
        {steps.map((step) => (
          <article className="flow-card reveal" key={step.number}>
            <div className="flow-card-head">
              <span className="icon-badge" aria-hidden="true">
                <LineIcon name={step.icon} />
              </span>
              <span className="flow-num">{step.number}</span>
            </div>
            <h3>{step.title}</h3>
            <p>{step.text}</p>
          </article>
        ))}
      </div>

      <aside className="economy-note reveal" aria-label="تقسيم الأرباح">
        <h3>كل دخول عبر التطبيق</h3>
        <p>
          <strong>80% للنادي</strong> - <strong>20% عمولة تشغيل للمنصة</strong>
        </p>
        <small>بدون رسوم ثابتة. بدون اشتراك شهري.</small>
      </aside>
    </section>
  );
}
