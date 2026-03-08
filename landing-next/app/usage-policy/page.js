import Link from "next/link";

const sections = [
  {
    title: "1) تعريف بالتطبيق",
    body: "SportPass منصة دخول رياضي تتيح للمستخدمين التمرين بدون اشتراك شهري عبر محفظة رقمية ودخول QR.",
  },
  {
    title: "2) الجهة المسؤولة",
    body: "الجهة المالكة والمشغلة: مؤسسة سامي حمدان التجارية.",
  },
  {
    title: "3) مسؤوليات المستخدم",
    body: "يلتزم المستخدم بإدخال بيانات صحيحة، وحماية معلومات حسابه، وعدم إساءة استخدام التطبيق أو محاولة التحايل على النظام.",
  },
  {
    title: "4) مسؤوليات المنصة",
    body: "تلتزم المنصة بتقديم الخدمة ضمن الإمكانات التشغيلية، وحماية البيانات، وإتاحة قنوات دعم واضحة للمستخدمين والشركاء.",
  },
  {
    title: "5) المخالفات",
    body: "عند مخالفة سياسة الاستخدام يحق للمنصة اتخاذ إجراءات تشمل الإنذار أو التعليق أو إيقاف الحساب وفق جسامة المخالفة.",
  },
];

export const metadata = {
  title: "SportPass | سياسة الاستخدام",
  description: "سياسة الاستخدام الرسمية لتطبيق SportPass.",
};

export default function UsagePolicyPage() {
  return (
    <main className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#04070f] dark:text-slate-100">
      <section className="mx-auto w-full max-w-4xl px-4 pb-16 pt-10 md:px-6 md:pt-14">
        <Link
          href="/"
          className="inline-flex rounded-xl border border-slate-300 bg-white/80 px-4 py-2 text-sm font-bold text-slate-700 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
        >
          العودة للرئيسية
        </Link>

        <div className="mt-6 rounded-3xl border border-slate-200/70 bg-white/80 p-6 shadow-xl shadow-slate-900/5 dark:border-white/10 dark:bg-white/[0.04]">
          <h1 className="text-3xl font-black md:text-4xl" style={{ fontFamily: "var(--font-tajawal), var(--font-cairo), sans-serif" }}>
            سياسة الاستخدام
          </h1>
          <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">آخر تحديث: 08-03-2026</p>
          <p className="mt-4 text-sm leading-7 text-slate-700 dark:text-slate-200">
            الجهة المسؤولة: مؤسسة سامي حمدان التجارية — البريد: anis.alkredi@gmail.com — الهاتف: 0937164384
          </p>
        </div>

        <div className="mt-5 space-y-3">
          {sections.map((s) => (
            <article
              key={s.title}
              className="rounded-2xl border border-slate-200/80 bg-white/80 p-5 dark:border-white/10 dark:bg-white/[0.04]"
            >
              <h2 className="text-lg font-black">{s.title}</h2>
              <p className="mt-2 text-sm leading-7 text-slate-600 dark:text-slate-300">{s.body}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
