const userPoints = [
  "ادفع فقط عندما تتمرن",
  "محفظة إلكترونية واضحة",
  "استكشف النوادي على الخريطة",
  "امسح QR وادخل فورًا",
];

export default function UserSection() {
  return (
    <section className="container section user-section" id="for-users">
      <div className="section-head reveal">
        <p className="eyebrow">للمستخدم</p>
        <h2>حرية التمرين بدون اشتراك</h2>
      </div>

      <div className="user-card reveal" id="apk-download">
        <ul>
          {userPoints.map((point) => (
            <li key={point}>{point}</li>
          ))}
        </ul>

        <div className="cta-row">
          <a href="/for-users" className="btn btn-outline">
            صفحة المستخدم
          </a>
          <a href="/apk/sportpass.apk" className="btn btn-primary" download>
            تحميل التطبيق (APK)
          </a>
        </div>
      </div>
    </section>
  );
}
