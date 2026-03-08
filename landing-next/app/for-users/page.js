import Image from "next/image";
import Link from "next/link";

const userSteps = [
  "سجّل بحسابك عبر البريد الإلكتروني",
  "اشحن المحفظة من وسيلة الدفع المحلية المعتمدة",
  "اختر ناديك من الخريطة حسب السعر والموقع",
  "امسح (QR) عند المدخل وابدأ التمرين فورًا",
];

export const metadata = {
  title: "SportPass للمستخدم | تمرين مرن بدون اشتراك",
  description:
    "تعرف على تجربة المستخدم في SportPass: ادفع فقط عند الدخول، محفظة واضحة، وسجل زيارات دقيق.",
};

export default function ForUsersPage() {
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
              للمستخدمين
            </span>
            <h1 className="mt-4 text-3xl font-black md:text-4xl" style={{ fontFamily: "var(--font-tajawal), var(--font-cairo), sans-serif" }}>
              تمرّن بحرية وادفع فقط عند الاستخدام
            </h1>
            <p className="mt-4 text-sm leading-7 text-slate-600 dark:text-slate-300">
              SportPass يلغي الاشتراك الشهري. كل ما عليك: شحن المحفظة، اختيار النادي، ثم دخول سريع عبر
              (QR).
            </p>

            <ul className="mt-6 space-y-3">
              {userSteps.map((step) => (
                <li
                  key={step}
                  className="rounded-xl border border-slate-200/80 bg-white/80 px-4 py-3 text-sm font-semibold text-slate-700 dark:border-white/10 dark:bg-white/[0.04] dark:text-slate-200"
                >
                  {step}
                </li>
              ))}
            </ul>

            <div className="mt-6 flex flex-wrap gap-3">
              <a
                href="/apk/sportpass.apk"
                download
                className="inline-flex items-center justify-center rounded-xl border border-emerald-400 bg-gradient-to-r from-emerald-400 to-teal-400 px-5 py-3 text-sm font-black text-slate-900"
              >
                تحميل التطبيق (APK)
              </a>
              <Link
                href="/"
                className="inline-flex items-center justify-center rounded-xl border border-slate-300 bg-white/80 px-5 py-3 text-sm font-black text-slate-700 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
              >
                أنا صاحب نادي
              </Link>
            </div>
          </article>

          <article className="mx-auto w-full max-w-[320px] rounded-[2rem] border border-slate-300/80 bg-white/80 p-2 shadow-2xl shadow-cyan-900/10 backdrop-blur dark:border-white/20 dark:bg-slate-900/80">
            <Image
              src="/screenshots/shot_current.png"
              alt="واجهة SportPass للمستخدم"
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
