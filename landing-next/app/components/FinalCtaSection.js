export default function FinalCtaSection() {
  return (
    <section className="container section cta-block" id="partner-join">
      <p className="eyebrow">ابدأ الآن</p>
      <h2>تمرين مرن للمستخدم — دخل إضافي للنادي</h2>
      <p>اختر مسارك الآن وابدأ خلال دقائق.</p>

      <div className="cta-row center">
        <a className="btn btn-primary" href="#apk-download">
          ابدأ الآن
        </a>
        <a
          className="btn btn-outline"
          href="mailto:partners@sportpass.app?subject=%D8%B7%D9%84%D8%A8%20%D8%B4%D8%B1%D8%A7%D9%83%D8%A9%20%D9%86%D8%A7%D8%AF%D9%8A%20-%20SportPass"
        >
          سجّل ناديك
        </a>
        <a className="btn btn-soft" href="mailto:support@sportpass.app">
          تواصل معنا
        </a>
        <a
          className="btn btn-soft"
          href="mailto:partners@sportpass.app?subject=%D8%B7%D9%84%D8%A8%20%D8%AA%D8%AC%D8%B1%D8%A8%D8%A9%20SportPass"
        >
          اطلب تجربة
        </a>
      </div>

      <p className="hero-trustline">بدون اشتراك شهري — ادفع فقط عند الدخول</p>
    </section>
  );
}
