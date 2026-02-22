import { clubs } from "../data/clubs";

function formatCurrency(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

export default function BrochureFlowSection() {
  return (
    <section className="container section" id="club-brochure">
      <div className="section-head reveal">
        <p className="eyebrow">بروشور داخل النادي</p>
        <h2>امسح QR التعريفي وخلّي المستخدم يفهم النظام خلال 30 ثانية</h2>
      </div>

      <div className="brochure-box reveal">
        <p>
          لكل نادي نعطيك <strong>QRين</strong>:
        </p>
        <ul>
          <li>
            <strong>QR التعريفي:</strong> يفتح صفحة النادي كبروشور (سعر، فرع، خطوات الدخول).
          </li>
          <li>
            <strong>QR الدخول:</strong> يستخدمه المشترك داخل التطبيق لتنفيذ check-in الفعلي.
          </li>
        </ul>

        <div className="brochure-links">
          {clubs.map((club) => (
            <a key={club.slug} href={`/club/${club.slug}`} className="brochure-link">
              <span>{club.name}</span>
              <small>
                {club.branch} - {formatCurrency(club.entryPrice)} ل.س
              </small>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}
