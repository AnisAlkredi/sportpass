import Link from "next/link";

const sections = [
  {
    title: "1) البيانات التي نجمعها",
    body: "نجمع بيانات الحساب الأساسية وبيانات التشغيل الضرورية مثل سجل الشحن، سجل الدخول عبر QR، وسجل النشاط داخل التطبيق.",
  },
  {
    title: "2) غاية جمع البيانات",
    body: "لتشغيل الخدمات الأساسية (تسجيل الدخول، المحفظة، الدخول للنادي) وتحسين الاستقرار التشغيلي والدعم الفني.",
  },
  {
    title: "3) مشاركة البيانات",
    body: "لا يتم بيع البيانات الشخصية. تتم مشاركة الحد الأدنى اللازم لتقديم الخدمة، أو عند وجود التزام قانوني صادر عن جهة مختصة.",
  },
  {
    title: "4) حماية البيانات",
    body: "نطبق ضوابط وصول بحسب الدور، ومراجعة للعمليات الحساسة، وإجراءات أمنية تشغيلية لحماية البيانات من الوصول غير المصرح.",
  },
  {
    title: "5) حقوق المستخدم",
    body: "يمكن للمستخدم طلب الاطلاع على بياناته أو تصحيحها أو التواصل بخصوص الخصوصية عبر قنوات التواصل الرسمية.",
  },
  {
    title: "6) تحديثات السياسة",
    body: "قد يتم تحديث هذه السياسة عند الحاجة، وتُعلن النسخة المحدثة داخل التطبيق وعلى الموقع الرسمي.",
  },
];

export const metadata = {
  title: "SportPass | سياسة الخصوصية",
  description: "سياسة الخصوصية الرسمية لتطبيق SportPass.",
};

export default function PrivacyPolicyPage() {
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
            سياسة الخصوصية
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
