import Image from "next/image";

export default function HeaderNav() {
  return (
    <header className="topbar-wrap">
      <div className="topbar container">
        <a href="#top" className="brand" aria-label="SportPass">
          <span className="brand-mark p-0.5">
            <Image
              src="/brand/sportpass-icon-192.png"
              alt="SportPass App Icon"
              width={36}
              height={36}
              className="h-9 w-9 rounded-xl"
            />
          </span>
          <span className="brand-copy">
            <strong className="brand-text">SportPass</strong>
            <small>ادخل وتدرّب بدون اشتراك شهري</small>
          </span>
        </a>

        <nav className="topnav" aria-label="روابط الصفحة">
          <a href="#how-it-works">كيف يعمل</a>
          <a href="#user-benefits">للمستخدم</a>
          <a href="#gym-benefits">للنوادي</a>
          <a href="#transparency">الشفافية</a>
          <a href="#faq">الأسئلة الشائعة</a>
        </nav>

        <a className="topbar-cta" href="#partner-join">
          سجّل ناديك
        </a>
      </div>
    </header>
  );
}
