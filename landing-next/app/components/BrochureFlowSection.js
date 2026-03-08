import { clubs } from "../data/clubs";

function formatCurrency(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

export default function BrochureFlowSection() {
  return (
    <section className="container section" id="club-brochure">
      <div className="section-head reveal">
        <p className="eyebrow">سيناريو التحويل داخل النادي</p>
        <h2>صفحة تعريف النادي تعمل كبروشور بيع خلال 30 ثانية</h2>
      </div>

      <div className="brochure-box reveal">
        <p>
          عند الاستقبال، يمكن عرض صفحة النادي على العميل ليفهم النظام مباشرة: السعر، خطوات الدخول،
          وكيف يحمّل التطبيق في لحظتها.
        </p>

        <div className="brochure-flow">
          <article>
            <span>1</span>
            <h3>QR تعريفي</h3>
            <p>يفتح صفحة النادي كمادة تعريفية سريعة قبل أول تجربة.</p>
          </article>
          <article>
            <span>2</span>
            <h3>QR الدخول</h3>
            <p>يُستخدم داخل التطبيق لتنفيذ check-in الفعلي عند الباب.</p>
          </article>
          <article>
            <span>3</span>
            <h3>تحويل مباشر</h3>
            <p>المستخدم يفهم الفكرة، يشحن، ويدخل خلال دقائق.</p>
          </article>
        </div>

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
