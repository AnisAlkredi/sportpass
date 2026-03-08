import LineIcon from "./LineIcon";

const steps = [
  {
    number: "١",
    icon: "pricing",
    title: "اشحن المحفظة",
    text: "اشحن رصيدك عبر تحويل محلي معتمد مثل شام كاش أو أي وسيلة دفع معتمدة.",
  },
  {
    number: "٢",
    icon: "localMarket",
    title: "اختر النادي",
    text: "تصفح النوادي المشاركة وشاهد سعر الدخول لكل نادي قبل أن تذهب.",
  },
  {
    number: "٣",
    icon: "scan",
    title: "امسح (QR) وتدرّب",
    text: "عند المدخل امسح رمز (QR)، يتم الخصم تلقائيًا وتدخل مباشرة.",
  },
];

export default function PartnerHowItWorks() {
  return (
    <section className="container section" id="how-it-works">
      <div className="section-head reveal">
        <p className="eyebrow">كيف يعمل</p>
        <h2>٣ خطوات سريعة من الشحن إلى التمرين</h2>
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
    </section>
  );
}
