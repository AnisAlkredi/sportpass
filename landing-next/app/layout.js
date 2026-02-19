import { Cairo, Tajawal } from "next/font/google";
import "./globals.css";

const cairo = Cairo({
  variable: "--font-cairo",
  subsets: ["arabic", "latin"],
  weight: ["400", "600", "700", "800"],
});

const tajawal = Tajawal({
  variable: "--font-tajawal",
  subsets: ["arabic", "latin"],
  weight: ["700", "800"],
});

export const metadata = {
  title: "SportPass | بطاقات الرياضة الذكية",
  description:
    "منصة SportPass لدخول الأندية الرياضية عبر QR مع محفظة رقمية واكتشاف المراكز على الخريطة.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="ar" dir="rtl">
      <body className={`${cairo.variable} ${tajawal.variable}`}>{children}</body>
    </html>
  );
}
