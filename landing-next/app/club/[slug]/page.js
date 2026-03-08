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
  if (!club) return { title: "النادي غير موجود | SportPass" };

  return {
    title: `${club.name} - ${club.branch} | SportPass`,
    description: `تعرف على ${club.name} ${club.branch} وادخل عبر SportPass بدون اشتراك شهري.`,
  };
}

export default function ClubBrochurePage({ params }) {
  const club = findClubBySlug(params.slug);
  if (!club) notFound();

  return (
    <main className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#04070f] dark:text-slate-100">
      <section className="mx-auto w-full max-w-6xl px-4 pb-16 pt-10 md:px-6 md:pt-16">
        <Link
          href="/"
          className="inline-flex items-center gap-2 rounded-xl border border-slate-300 bg-white/70 px-4 py-2 text-sm font-bold text-slate-700 transition hover:border-emerald-300 hover:text-emerald-600 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
        >
          العودة للصفحة الرئيسية
        </Link>

        <div className="mt-8 grid items-start gap-8 lg:grid-cols-[1.1fr_.9fr]">
          <article className="rounded-3xl border border-slate-200/70 bg-white/75 p-6 shadow-xl shadow-slate-900/5 backdrop-blur dark:border-white/10 dark:bg-white/[0.04]">
            <span className="inline-flex rounded-full border border-emerald-300/50 bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-700 dark:border-emerald-400/30 dark:bg-emerald-500/15 dark:text-emerald-300">
              نادي شريك مع SportPass
            </span>
            <h1 className="mt-4 text-3xl font-black md:text-4xl" style={{ fontFamily: "var(--font-tajawal), var(--font-cairo), sans-serif" }}>
              {club.name} - {club.branch}
            </h1>
            <p className="mt-4 text-sm leading-7 text-slate-600 dark:text-slate-300">
              ادفع فقط وقت التمرين وادخل مباشرة عبر (QR) بدون اشتراك شهري.
            </p>

            <div className="mt-6 grid gap-3 sm:grid-cols-3">
              <div className="rounded-xl border border-slate-200/80 bg-white/80 p-3 text-sm dark:border-white/10 dark:bg-white/[0.04]">
                <p className="text-slate-500 dark:text-slate-400">الموقع</p>
                <p className="mt-1 font-bold">
                  {club.city} - {club.address}
                </p>
              </div>
              <div className="rounded-xl border border-slate-200/80 bg-white/80 p-3 text-sm dark:border-white/10 dark:bg-white/[0.04]">
                <p className="text-slate-500 dark:text-slate-400">سعر الدخول</p>
                <p className="mt-1 font-bold">{formatCurrency(club.entryPrice)} ل.س</p>
              </div>
              <div className="rounded-xl border border-slate-200/80 bg-white/80 p-3 text-sm dark:border-white/10 dark:bg-white/[0.04]">
                <p className="text-slate-500 dark:text-slate-400">الدوام</p>
                <p className="mt-1 font-bold">{club.openHours}</p>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap gap-3">
              <a
                href="/apk/sportpass.apk"
                download
                className="inline-flex items-center justify-center rounded-xl border border-emerald-400 bg-gradient-to-r from-emerald-400 to-teal-400 px-5 py-3 text-sm font-black text-slate-900"
              >
                تحميل التطبيق
              </a>
              <a
                href="#how-to-enter"
                className="inline-flex items-center justify-center rounded-xl border border-slate-300 bg-white/80 px-5 py-3 text-sm font-black text-slate-700 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
              >
                كيف أدخل؟
              </a>
            </div>

            <section id="how-to-enter" className="mt-8">
              <h2 className="text-xl font-black">خطوات الدخول</h2>
              <ol className="mt-3 space-y-2 text-sm leading-7 text-slate-600 dark:text-slate-300">
                <li>1. حمّل التطبيق وسجّل حسابك.</li>
                <li>2. اشحن المحفظة.</li>
                <li>3. عند المدخل امسح (QR).</li>
                <li>4. يبدأ التمرين فورًا بعد تأكيد الدخول.</li>
              </ol>
            </section>

            <section className="mt-8">
              <h2 className="text-xl font-black">مزايا النادي</h2>
              <div className="mt-3 flex flex-wrap gap-2">
                {club.highlights.map((item) => (
                  <span
                    key={item}
                    className="rounded-full border border-slate-300 bg-white/80 px-3 py-1 text-xs font-bold text-slate-700 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
                  >
                    {item}
                  </span>
                ))}
              </div>
            </section>
          </article>

          <article className="mx-auto w-full max-w-[320px] rounded-[2rem] border border-slate-300/80 bg-white/80 p-2 shadow-2xl shadow-cyan-900/10 backdrop-blur dark:border-white/20 dark:bg-slate-900/80">
            <Image
              src="/screenshots/checkin.png"
              alt="واجهة مسح QR"
              width={1080}
              height={2400}
              className="h-auto w-full rounded-[1.6rem]"
              priority
            />
          </article>
        </div>
      </section>
    </main>
  );
}
