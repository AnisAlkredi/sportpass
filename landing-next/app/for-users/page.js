import Image from "next/image";
import Link from "next/link";

const userSteps = [
  "حمّل التطبيق وسجّل حسابك بالبريد الإلكتروني",
  "اشحن محفظتك مرة واحدة",
  "اختَر النادي من الخريطة",
  "امسح QR عند الباب وادخل فورًا",
];

export const metadata = {
  title: "SportPass للمستخدم | تمرين بدون اشتراك شهري",
  description:
    "صفحة مختصرة للمستخدم: ادفع فقط وقت التمرين، محفظة واضحة، ودخول سريع عبر QR.",
};

export default function ForUsersPage() {
  return (
    <main className="for-users-page">
      <div className="orb orb-a" />
      <div className="orb orb-b" />

      <section className="container section">
        <Link href="/" className="mini-back">
          العودة لصفحة الشركاء
        </Link>

        <div className="section-head reveal">
          <p className="eyebrow">للمستخدم</p>
          <h1>حرية التمرين بدون اشتراك شهري</h1>
        </div>

        <div className="for-users-layout reveal">
          <article className="for-users-card">
            <h3>كيف تبدأ خلال دقيقة</h3>
            <ul>
              {userSteps.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ul>

            <div className="cta-row">
              <a href="/apk/sportpass.apk" className="btn btn-primary" download>
                تحميل التطبيق (APK)
              </a>
              <Link href="/" className="btn btn-outline">
                أنا صاحب نادي
              </Link>
            </div>
          </article>

          <article className="for-users-phone">
            <Image
              src="/screenshots/shot_current.png"
              alt="واجهة SportPass للمستخدم"
              width={1080}
              height={2400}
              className="hero-shot"
            />
          </article>
        </div>
      </section>
    </main>
  );
}
