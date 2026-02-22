import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { clubs, findClubBySlug } from "../../data/clubs";

function formatCurrency(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

export function generateStaticParams() {
  return clubs.map((club) => ({ slug: club.slug }));
}

export function generateMetadata({ params }) {
  const club = findClubBySlug(params.slug);
  if (!club) {
    return { title: "النادي غير موجود | SportPass" };
  }
  return {
    title: `${club.name} - ${club.branch} | SportPass`,
    description: `تعرف على ${club.name} - ${club.branch} وابدأ الدخول عبر SportPass خلال أقل من دقيقة.`,
  };
}

export default function ClubBrochurePage({ params }) {
  const club = findClubBySlug(params.slug);
  if (!club) {
    notFound();
  }

  return (
    <main className="club-page">
      <div className="orb orb-a" />
      <div className="orb orb-b" />

      <section className="container section">
        <Link href="/" className="mini-back">
          العودة إلى صفحة الشركاء
        </Link>

        <div className="club-hero reveal">
          <div className="club-copy">
            <p className="eyebrow">بروشور النادي</p>
            <h1>
              {club.name} - {club.branch}
            </h1>
            <p className="lead">
              هذا النادي شريك مع SportPass. ادفع فقط وقت التمرين وادخل مباشرة عبر QR بدون اشتراك
              شهري.
            </p>

            <div className="club-meta">
              <div>
                <span>الموقع</span>
                <strong>
                  {club.city} - {club.address}
                </strong>
              </div>
              <div>
                <span>سعر الدخول</span>
                <strong>{formatCurrency(club.entryPrice)} ل.س</strong>
              </div>
              <div>
                <span>أوقات الدوام</span>
                <strong>{club.openHours}</strong>
              </div>
            </div>

            <div className="cta-row">
              <a href="/apk/sportpass.apk" className="btn btn-primary" download>
                تحميل التطبيق
              </a>
              <a href="#how-to-enter" className="btn btn-outline">
                كيف أدخل؟
              </a>
            </div>
          </div>

          <div className="club-phone">
            <Image
              src="/screenshots/checkin.png"
              alt="شاشة مسح QR في SportPass"
              width={1080}
              height={2400}
              className="hero-shot"
              priority
            />
          </div>
        </div>

        <section className="club-steps reveal" id="how-to-enter">
          <h2>خطوات الدخول في أقل من دقيقة</h2>
          <ol>
            <li>حمّل التطبيق وسجّل حسابك.</li>
            <li>اشحن رصيدك من المحفظة.</li>
            <li>وجّه الكاميرا إلى QR عند الباب.</li>
            <li>يتم تسجيل الدخول فورًا.</li>
          </ol>
        </section>

        <section className="club-highlights reveal">
          <h2>مزايا هذا النادي</h2>
          <div className="club-tags">
            {club.highlights.map((item) => (
              <span key={item}>{item}</span>
            ))}
          </div>
        </section>
      </section>
    </main>
  );
}
