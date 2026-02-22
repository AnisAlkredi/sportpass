export default function FinalCtaSection() {
  return (
    <section className="container section cta-block" id="partner-join">
      <p className="eyebrow">دعوة شراكة</p>
      <h2>كن من أوائل النوادي الشريكة</h2>
      <p>
        افتح باب دخل إضافي لناديك خلال المرحلة التجريبية الأولى، بدون أي التزام شهري أو تغيير على
        نظام اشتراكاتك الحالي.
      </p>

      <div className="cta-row center">
        <a
          className="btn btn-primary"
          href="mailto:partners@sportpass.app?subject=%D8%B7%D9%84%D8%A8%20%D8%A7%D9%86%D8%B6%D9%85%D8%A7%D9%85%20%D9%86%D8%A7%D8%AF%D9%8A%20-%20SportPass"
        >
          سجّل ناديك الآن
        </a>
        <a className="btn btn-outline" href="/apk/sportpass.apk" download>
          تحميل التطبيق
        </a>
      </div>
    </section>
  );
}
