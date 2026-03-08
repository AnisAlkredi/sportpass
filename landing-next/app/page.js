"use client";

import Image from "next/image";
import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";
import {
  ArrowUpRight,
  BadgeCheck,
  BarChart3,
  Building2,
  CheckCircle2,
  Clock3,
  CreditCard,
  Gem,
  MapPinned,
  QrCode,
  ShieldCheck,
  Sparkles,
  Users,
  Wallet,
} from "lucide-react";

const steps = [
  {
    title: "اشحن رصيدك",
    text: "اشحن محفظتك عبر وسيلة الدفع المحلية المعتمدة، وابدأ مباشرة بدون أي اشتراك شهري.",
    icon: Wallet,
  },
  {
    title: "اختر النادي",
    text: "شاهد النوادي المشاركة وسعر الدخول لكل نادي قبل أن تتوجه إليه.",
    icon: MapPinned,
  },
  {
    title: "امسح QR وابدأ التمرين",
    text: "عند الباب امسح (QR)، يتم الخصم تلقائيًا وتدخل فورًا.",
    icon: QrCode,
  },
];

const userBenefits = [
  "بدون اشتراك شهري",
  "ادفع فقط عند التمرين",
  "حرية اختيار النادي",
  "سجل زيارات واضح",
  "محفظة رقمية شفافة",
];

const gymBenefits = [
  "وصول عملاء جدد بدون تغيير نموذج الاشتراكات الحالي",
  "تفعيل دخول ذكي عبر (QR) لتخفيف الازدحام على الاستقبال",
  "لوحة تحكم لحظية: زوار، أوقات دخول، وإيراد",
  "تشغيل بسيط وسريع لعدة فروع من نفس الحساب",
];

const trustBadges = ["دفع محلي معتمد", "سجل عمليات شفاف", "دخول آمن عبر QR", "دعم تشغيلي مباشر"];
const PARTNER_WEBAPP_URL =
  process.env.NEXT_PUBLIC_PARTNER_WEBAPP_URL?.trim() || "/webapp/index.html";
const PARTNER_WAITLIST_MAILTO =
  "mailto:partners@sportpass.app?subject=%D8%B7%D9%84%D8%A8%20%D8%A7%D9%86%D8%B6%D9%85%D8%A7%D9%85%20%D9%86%D8%A7%D8%AF%D9%8A%20-%20SportPass";
const PARTNER_CTA_HREF = PARTNER_WEBAPP_URL || PARTNER_WAITLIST_MAILTO;
const PARTNER_CTA_LINK_PROPS = PARTNER_WEBAPP_URL
  ? { target: "_blank", rel: "noopener noreferrer" }
  : {};

const fadeUp = {
  hidden: { opacity: 0, y: 22 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.55, ease: "easeOut" },
  },
};

function Reveal({ children, delay = 0, className = "" }) {
  return (
    <motion.div
      variants={fadeUp}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, amount: 0.2 }}
      transition={{ delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function HeroPhoneStack({ y }) {
  return (
    <motion.div style={{ y }} className="relative mx-auto h-[560px] w-full max-w-[520px]">
      <div className="pulse-glow absolute right-10 top-10 h-40 w-40 rounded-full bg-emerald-400/30 blur-3xl dark:bg-emerald-400/35" />
      <div className="pulse-glow absolute bottom-14 left-6 h-44 w-44 rounded-full bg-cyan-400/30 blur-3xl dark:bg-cyan-500/35" />

      <motion.div
        initial={{ opacity: 0, x: 40, rotate: 8 }}
        animate={{ opacity: 1, x: 0, rotate: 8 }}
        transition={{ duration: 0.8, ease: "easeOut", delay: 0.22 }}
        className="float-fast absolute right-2 top-14 hidden w-44 rounded-[2rem] border border-white/20 bg-slate-900/90 p-2 shadow-2xl shadow-emerald-950/30 md:block"
      >
        <Image
          src="/screenshots/checkin.png"
          alt="QR Entry"
          width={1080}
          height={2400}
          className="h-auto w-full rounded-[1.5rem]"
        />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, x: -50, rotate: -8 }}
        animate={{ opacity: 1, x: 0, rotate: -8 }}
        transition={{ duration: 0.8, ease: "easeOut", delay: 0.35 }}
        className="float-slow absolute left-2 top-24 hidden w-44 rounded-[2rem] border border-white/20 bg-slate-900/90 p-2 shadow-2xl shadow-cyan-950/30 md:block"
      >
        <Image
          src="/screenshots/shot_map_try1.png"
          alt="Gym Map"
          width={1080}
          height={2400}
          className="h-auto w-full rounded-[1.5rem]"
        />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 40, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="relative z-10 mx-auto w-[250px] rounded-[2.4rem] border border-slate-300/80 bg-white/80 p-2 shadow-[0_35px_90px_-40px_rgba(2,132,199,.55)] backdrop-blur-xl dark:border-white/20 dark:bg-slate-900/85 dark:shadow-[0_35px_90px_-35px_rgba(16,185,129,.45)] md:w-[285px]"
      >
        <Image
          src="/screenshots/shot_current.png"
          alt="SportPass App"
          width={1080}
          height={2400}
          className="h-auto w-full rounded-[1.9rem]"
          priority
        />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.55 }}
        className="glass-panel absolute -bottom-2 right-8 hidden w-52 p-4 md:block"
      >
        <p className="text-xs text-slate-500 dark:text-slate-400">الرصيد الحالي</p>
        <p className="mt-1 text-xl font-black text-slate-900 dark:text-white">205,000 ل.س</p>
        <p className="mt-2 text-xs text-emerald-600 dark:text-emerald-300">جاهز للدخول الفوري</p>
      </motion.div>
    </motion.div>
  );
}

export default function HomePage() {
  const { scrollYProgress } = useScroll();
  const orbA = useTransform(scrollYProgress, [0, 1], [0, 320]);
  const orbB = useTransform(scrollYProgress, [0, 1], [0, -240]);

  return (
    <div className="relative min-h-screen overflow-x-clip bg-slate-50 text-slate-900 transition-colors duration-300 dark:bg-[#04070f] dark:text-slate-100">
      <motion.div
        style={{ y: orbA }}
        className="pointer-events-none absolute -top-28 right-0 h-[440px] w-[440px] rounded-full bg-emerald-400/25 blur-[130px] dark:bg-emerald-500/20"
      />
      <motion.div
        style={{ y: orbB }}
        className="pointer-events-none absolute -left-28 top-[35%] h-[420px] w-[420px] rounded-full bg-cyan-300/25 blur-[130px] dark:bg-cyan-500/20"
      />
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_1px_1px,rgba(148,163,184,.14)_1px,transparent_0)] bg-[length:32px_32px] dark:bg-[radial-gradient(circle_at_1px_1px,rgba(148,163,184,.11)_1px,transparent_0)]" />

      <header className="sticky top-0 z-50 border-b border-slate-200/70 bg-white/70 backdrop-blur-xl dark:border-white/10 dark:bg-slate-950/55">
        <div className="section-shell flex h-16 items-center justify-between">
          <Link href="#" className="flex items-center gap-3">
            <span className="overflow-hidden rounded-xl ring-1 ring-slate-200/80 dark:ring-white/20">
              <Image
                src="/brand/sportpass-icon-192.png"
                alt="SportPass App Icon"
                width={44}
                height={44}
                className="h-11 w-11"
              />
            </span>
            <span>
              <strong className="block text-sm font-extrabold text-slate-900 dark:text-white">SportPass</strong>
              <small className="block text-[11px] text-slate-500 dark:text-slate-400">
                Train without subscription
              </small>
            </span>
          </Link>

          <nav className="hidden items-center gap-6 text-sm font-semibold text-slate-600 dark:text-slate-300 lg:flex">
            <a href="#how-it-works" className="transition hover:text-emerald-500">كيف يعمل</a>
            <a href="#users" className="transition hover:text-emerald-500">للمستخدمين</a>
            <a href="#gyms" className="transition hover:text-emerald-500">للنوادي</a>
            <a href="#trust" className="transition hover:text-emerald-500">الثقة</a>
          </nav>

          <div className="flex items-center gap-2">
            <a href="#download" className="neo-btn neo-btn-secondary hidden sm:inline-flex">
              حمّل التطبيق
            </a>
            <a
              href={PARTNER_CTA_HREF}
              {...PARTNER_CTA_LINK_PROPS}
              className="neo-btn neo-btn-primary"
            >
              سجّل ناديك
            </a>
          </div>
        </div>
      </header>

      <main className="relative z-10">
        <section className="section-shell grid items-center gap-12 pb-14 pt-16 md:pt-24 lg:grid-cols-2">
          <Reveal>
            <span className="section-label">
              <Sparkles className="h-3.5 w-3.5" />
              منصة رياضية ذكية للسوق السوري
            </span>
            <h1 className="section-title max-w-xl text-balance leading-[1.05]">
              تمرّن في أي نادٍ
              <br />
              بدون اشتراك شهري
            </h1>
            <p className="section-subtitle">
              اشحن رصيدك وادخل النادي فورًا عبر QR وادفع فقط عندما تتمرّن.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a href="#download" className="neo-btn neo-btn-primary">
                حمّل التطبيق
              </a>
              <a
                href={PARTNER_CTA_HREF}
                {...PARTNER_CTA_LINK_PROPS}
                className="neo-btn neo-btn-secondary"
              >
                سجّل ناديك
              </a>
            </div>
            <p className="mt-5 text-sm font-bold text-emerald-700 dark:text-emerald-300">
              بدون اشتراك شهري — ادفع فقط عند الدخول
            </p>
          </Reveal>

          <HeroPhoneStack y={useTransform(scrollYProgress, [0, 1], [0, -110])} />
        </section>

        <section id="how-it-works" className="section-shell py-14 md:py-20">
          <Reveal>
            <span className="section-label">How it works</span>
            <h2 className="section-title">ابدأ خلال أقل من دقيقة</h2>
          </Reveal>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {steps.map((step, idx) => {
              const Icon = step.icon;
              return (
                <Reveal key={step.title} delay={idx * 0.08}>
                  <motion.article
                    whileHover={{ y: -6 }}
                    className="glass-panel relative h-full p-6"
                  >
                    <span className="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-emerald-400/15 text-emerald-600 dark:bg-emerald-400/20 dark:text-emerald-300">
                      <Icon className="h-5 w-5" />
                    </span>
                    <span className="absolute left-4 top-4 text-xs font-black text-emerald-500/70 dark:text-emerald-300/70">
                      {idx + 1}
                    </span>
                    <h3 className="mt-4 text-xl font-black text-slate-900 dark:text-white">{step.title}</h3>
                    <p className="mt-3 text-sm leading-7 text-slate-600 dark:text-slate-300">{step.text}</p>
                  </motion.article>
                </Reveal>
              );
            })}
          </div>
        </section>

        <section id="users" className="section-shell py-14 md:py-20">
          <Reveal>
            <span className="section-label">للمستخدمين</span>
            <h2 className="section-title">ادفع حسب الاستخدام (Pay as you go)</h2>
          </Reveal>

          <div className="mt-8 grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            {userBenefits.map((benefit, index) => (
              <Reveal key={benefit} delay={index * 0.05}>
                <motion.div
                  whileHover={{ y: -4, scale: 1.01 }}
                  className="glass-panel flex h-full items-center gap-3 p-4"
                >
                  <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-500" />
                  <p className="text-sm font-bold text-slate-700 dark:text-slate-200">{benefit}</p>
                </motion.div>
              </Reveal>
            ))}
          </div>
        </section>

        <section id="gyms" className="section-shell py-14 md:py-20">
          <Reveal>
            <span className="section-label">للنوادي</span>
            <h2 className="section-title">نمو إضافي بدون تعقيد تشغيلي</h2>
          </Reveal>

          <div className="mt-8 grid gap-6 lg:grid-cols-[1.1fr_.9fr]">
            <Reveal>
              <div className="glass-panel p-6 md:p-8">
                <h3 className="text-2xl font-black text-slate-900 dark:text-white">تقسيم الإيراد واضح وثابت</h3>
                <div className="mt-6 grid gap-4 sm:grid-cols-2">
                  <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 dark:border-emerald-400/30 dark:bg-emerald-500/10">
                    <p className="text-sm font-bold text-emerald-700 dark:text-emerald-300">80% للنادي</p>
                    <p className="mt-2 text-xs text-emerald-700/90 dark:text-emerald-200/85">الحصة الأساسية من كل دخول</p>
                  </div>
                  <div className="rounded-2xl border border-cyan-200 bg-cyan-50 p-5 dark:border-cyan-400/30 dark:bg-cyan-500/10">
                    <p className="text-sm font-bold text-cyan-700 dark:text-cyan-300">20% للمنصة</p>
                    <p className="mt-2 text-xs text-cyan-700/90 dark:text-cyan-200/85">عمولة التشغيل والدعم</p>
                  </div>
                </div>

                <div className="mt-6 grid gap-3 sm:grid-cols-2">
                  {gymBenefits.map((item) => (
                    <div key={item} className="rounded-xl border border-slate-200/80 bg-white/70 p-3 text-sm font-semibold text-slate-700 dark:border-white/10 dark:bg-white/[0.04] dark:text-slate-200">
                      {item}
                    </div>
                  ))}
                </div>
              </div>
            </Reveal>

            <Reveal delay={0.14}>
              <div className="glass-panel h-full p-6 md:p-8">
                <p className="text-sm font-bold text-slate-500 dark:text-slate-400">مثال توضيحي قبل الإطلاق</p>
                <p className="mt-4 text-3xl font-black tracking-tight text-slate-900 dark:text-white">
                  سعر دخول واحد: 100 ل.س
                </p>
                <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">
                  هكذا يتوزع أي دخول داخل المنصة بشكل ثابت وشفاف:
                </p>

                <div className="mt-6 space-y-3">
                  <div className="stat-card flex items-center justify-between">
                    <span className="text-sm text-slate-500 dark:text-slate-400">حصة النادي (80%)</span>
                    <strong className="text-base font-black text-emerald-600 dark:text-emerald-300">80 ل.س</strong>
                  </div>
                  <div className="stat-card flex items-center justify-between">
                    <span className="text-sm text-slate-500 dark:text-slate-400">حصة المنصة (20%)</span>
                    <strong className="text-base font-black text-cyan-600 dark:text-cyan-300">20 ل.س</strong>
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="section-shell py-14 md:py-20">
          <Reveal>
            <span className="section-label">Dashboard</span>
            <h2 className="section-title">لوحات واضحة للطرفين</h2>
          </Reveal>

          <div className="mt-8 grid gap-5 lg:grid-cols-3">
            {[
              { title: "Gym Dashboard", img: "/screenshots/shot_map_try1.png", icon: BarChart3 },
              { title: "User Wallet", img: "/screenshots/shot_wallet_try1.png", icon: CreditCard },
              { title: "Entry History", img: "/screenshots/shot_history_try1.png", icon: Clock3 },
            ].map((item, idx) => {
              const Icon = item.icon;
              return (
                <Reveal key={item.title} delay={idx * 0.08}>
                  <motion.article
                    whileHover={{ y: -10, rotateX: 3, rotateY: -2 }}
                    transition={{ type: "spring", stiffness: 210, damping: 22 }}
                    style={{ transformStyle: "preserve-3d" }}
                    className="glass-panel overflow-hidden p-4"
                  >
                    <div className="mb-3 flex items-center justify-between">
                      <h3 className="text-sm font-black text-slate-800 dark:text-slate-100">{item.title}</h3>
                      <span className="grid h-8 w-8 place-items-center rounded-lg bg-emerald-400/15 text-emerald-600 dark:bg-emerald-400/20 dark:text-emerald-300">
                        <Icon className="h-4 w-4" />
                      </span>
                    </div>
                    <div className="overflow-hidden rounded-2xl border border-slate-200/80 dark:border-white/10">
                      <Image src={item.img} alt={item.title} width={1080} height={2400} className="h-auto w-full" />
                    </div>
                  </motion.article>
                </Reveal>
              );
            })}
          </div>
        </section>

        <section id="trust" className="section-shell py-14 md:py-20">
          <Reveal>
            <span className="section-label">Trust</span>
            <h2 className="section-title">بنية موثوقة للنمو الحقيقي</h2>
          </Reveal>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <Reveal>
              <div className="glass-panel p-6">
                <div className="flex items-center gap-3 text-emerald-500">
                  <Building2 className="h-5 w-5" />
                  <span className="text-sm font-bold">برنامج الشركاء المؤسسين</span>
                </div>
                <p className="mt-4 text-3xl font-black text-slate-900 dark:text-white">نستقبل أول 20 نادي</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">تفعيل يدوي لكل نادي لضمان الجودة التشغيلية.</p>
              </div>
            </Reveal>
            <Reveal delay={0.08}>
              <div className="glass-panel p-6">
                <div className="flex items-center gap-3 text-cyan-500">
                  <Users className="h-5 w-5" />
                  <span className="text-sm font-bold">قائمة انتظار المستخدمين</span>
                </div>
                <p className="mt-4 text-3xl font-black text-slate-900 dark:text-white">مفتوحة الآن</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">حمّل التطبيق وسجّل من الدفعة الأولى للإطلاق.</p>
              </div>
            </Reveal>
            <Reveal delay={0.16}>
              <div className="glass-panel p-6">
                <div className="flex items-center gap-3 text-violet-500">
                  <BadgeCheck className="h-5 w-5" />
                  <span className="text-sm font-bold">مرحلة الإطلاق الحالية</span>
                </div>
                <p className="mt-4 text-3xl font-black text-slate-900 dark:text-white">تجريبية مغلقة</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">توسع تدريجي منظم داخل السوق السوري.</p>
              </div>
            </Reveal>
          </div>

          <div className="mt-4 flex flex-wrap gap-2">
            {trustBadges.map((badge) => (
              <span
                key={badge}
                className="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-white/70 px-3 py-1.5 text-xs font-bold text-slate-700 dark:border-white/15 dark:bg-white/[0.04] dark:text-slate-200"
              >
                <ShieldCheck className="h-3.5 w-3.5 text-emerald-500" />
                {badge}
              </span>
            ))}
          </div>
        </section>

        <section id="join-gym" className="section-shell pb-20 pt-10 md:pt-14">
          <Reveal>
            <div className="relative overflow-hidden rounded-[2rem] border border-emerald-300/50 bg-gradient-to-br from-emerald-200 via-teal-200 to-cyan-200 p-8 text-slate-900 shadow-[0_35px_80px_-35px_rgba(13,148,136,.65)] dark:border-emerald-400/30 dark:from-emerald-600/25 dark:via-teal-500/20 dark:to-cyan-500/20 dark:text-white">
              <div className="pointer-events-none absolute -left-12 -top-14 h-36 w-36 rounded-full bg-white/35 blur-3xl dark:bg-emerald-300/20" />
              <div className="pointer-events-none absolute -bottom-20 right-0 h-44 w-44 rounded-full bg-cyan-100/45 blur-3xl dark:bg-cyan-300/20" />

              <div className="relative z-10 max-w-3xl">
                <span className="section-label border-white/60 bg-white/55 text-slate-800 dark:border-white/30 dark:bg-white/10 dark:text-emerald-100">
                  <Gem className="h-3.5 w-3.5" />
                  حرية التمرين بدون اشتراك
                </span>
                <h2 className="mt-5 text-3xl font-black leading-tight md:text-5xl" style={{ fontFamily: "var(--font-tajawal), var(--font-cairo), sans-serif" }}>
                  انضم إلى SportPass اليوم
                </h2>
                <p className="mt-4 max-w-2xl text-sm font-semibold text-slate-800/90 dark:text-slate-100/90">
                  منصة دخول ذكية للمستخدم، وقناة دخل إضافية مضمونة للنادي.
                </p>

                <div className="mt-7 flex flex-wrap gap-3" id="download">
                  <a href="/apk/sportpass.apk" download className="neo-btn neo-btn-primary">
                    حمّل التطبيق
                    <ArrowUpRight className="me-2 h-4 w-4" />
                  </a>
                  <a
                    href={PARTNER_CTA_HREF}
                    {...PARTNER_CTA_LINK_PROPS}
                    className="neo-btn neo-btn-secondary"
                  >
                    سجّل ناديك
                  </a>
                </div>
              </div>
            </div>
          </Reveal>
        </section>
      </main>

      <footer className="border-t border-slate-200/70 bg-white/60 py-8 dark:border-white/10 dark:bg-slate-950/55">
        <div className="section-shell flex flex-col items-start justify-between gap-4 md:flex-row md:items-center">
          <p className="text-sm text-slate-600 dark:text-slate-300">
            SportPass © {new Date().getFullYear()} — منصة موثوقة للدخول الرياضي الذكي.
          </p>
          <div className="flex flex-wrap gap-4 text-xs font-bold text-slate-500 dark:text-slate-400">
            <a className="transition hover:text-emerald-500" href="/privacy-policy">سياسة الخصوصية</a>
            <a className="transition hover:text-emerald-500" href="/usage-policy">سياسة الاستخدام</a>
            <a className="transition hover:text-emerald-500" href="/contact-us">اتصل بنا</a>
          </div>
        </div>
      </footer>
    </div>
  );
}
