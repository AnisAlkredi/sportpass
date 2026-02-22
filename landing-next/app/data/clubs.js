export const clubs = [
  {
    slug: "olympia-mazzeh",
    name: "Olympia Gym",
    branch: "فرع المزة",
    city: "دمشق",
    address: "المزة - قرب ساحة المحافظة",
    entryPrice: 8000,
    openHours: "8:00 صباحًا - 11:00 مساءً",
    highlights: ["حديد وكارديو", "صالة مكيفة", "دخول سريع عبر QR"],
  },
  {
    slug: "golden-abu-rummaneh",
    name: "Golden Gym",
    branch: "فرع أبو رمانة",
    city: "دمشق",
    address: "أبو رمانة - شارع بغداد",
    entryPrice: 12000,
    openHours: "7:00 صباحًا - 12:00 منتصف الليل",
    highlights: ["حديد + مسبح", "منطقة كارديو", "ساونا"],
  },
  {
    slug: "peak-mezzeh-villas",
    name: "Peak Fitness",
    branch: "فرع الفيلات الغربية",
    city: "دمشق",
    address: "مزة فيلات غربية - قرب المدارس",
    entryPrice: 10000,
    openHours: "9:00 صباحًا - 10:30 مساءً",
    highlights: ["جلسات تدريب فردي", "كروس فت", "دخول يومي مرن"],
  },
];

export function findClubBySlug(slug) {
  return clubs.find((club) => club.slug === slug) || null;
}
