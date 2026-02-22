export default function HeaderNav() {
  return (
    <header className="topbar container">
      <a href="#top" className="brand" aria-label="SportPass">
        <span className="brand-mark">SP</span>
        <span className="brand-text">SportPass</span>
      </a>

      <nav className="topnav">
        <a href="#partner-benefits">لماذا SportPass</a>
        <a href="#owner-flow">آلية العمل</a>
        <a href="#owner-control">الإدارة المالية</a>
        <a href="#club-brochure">بروشور النادي</a>
        <a href="#app-interfaces">الواجهات</a>
        <a href="#pilot-trust">المرحلة التجريبية</a>
        <a href="/for-users">للمستخدم</a>
      </nav>
    </header>
  );
}
