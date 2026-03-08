import Link from "next/link";

const contacts = [
  {
    title: "الجهة المسؤولة",
    value: "مؤسسة سامي حمدان التجارية",
  },
  {
    title: "البريد الإلكتروني",
    value: "anis.alkredi@gmail.com",
  },
  {
    title: "رقم الهاتف",
    value: "0937164384",
  },
  {
    title: "أوقات الاستجابة",
    value: "من السبت إلى الخميس",
  },
];

export const metadata = {
  title: "SportPass | اتصل بنا",
  description: "قنوات التواصل الرسمية لتطبيق SportPass.",
};

export default function ContactUsPage() {
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
            اتصل بنا
          </h1>
          <p className="mt-4 text-sm leading-7 text-slate-700 dark:text-slate-200">
            لأي استفسار أو شكوى أو طلب دعم فني متعلق بتطبيق SportPass، تواصل معنا عبر القنوات التالية:
          </p>
        </div>

        <div className="mt-5 grid gap-3">
          {contacts.map((item) => (
            <article
              key={item.title}
              className="rounded-2xl border border-slate-200/80 bg-white/80 p-5 dark:border-white/10 dark:bg-white/[0.04]"
            >
              <h2 className="text-lg font-black">{item.title}</h2>
              <p className="mt-2 text-sm font-semibold text-slate-600 dark:text-slate-300">{item.value}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
