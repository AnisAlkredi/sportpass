import 'package:equatable/equatable.dart';

class PartnerLocation extends Equatable {
  final String id;
  final String partnerId;
  final String name;
  final String? addressText;
  final String city;
  final double lat;
  final double lng;
  final double basePrice;
  final double radiusM;
  final List<String> amenities;
  final List<String> photos;
  final Map<String, dynamic>? operatingHours;
  final bool isActive;

  const PartnerLocation({
    required this.id,
    required this.partnerId,
    required this.name,
    this.addressText,
    this.city = 'Damascus',
    required this.lat,
    required this.lng,
    this.basePrice = 8000,
    this.radiusM = 150,
    this.amenities = const [],
    this.photos = const [],
    this.operatingHours,
    this.isActive = false,
  });

  // Freeze V1: base_price represents gym 80% share.
  double get userPrice {
    final calculated = basePrice / 0.80;
    return (calculated / 500).ceil() * 500;
  }

  double get platformFee => userPrice - basePrice;

  factory PartnerLocation.fromJson(Map<String, dynamic> j) => PartnerLocation(
        id: j['id'] as String,
        partnerId: (j['partner_id'] as String?) ?? '',
        name: (j['name'] as String?) ?? 'فرع',
        addressText: j['address_text'] as String?,
        city: (j['city'] as String?) ?? 'Damascus',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        basePrice: (j['base_price'] as num?)?.toDouble() ?? 8000,
        radiusM: (j['radius_m'] as num?)?.toDouble() ?? 150,
        amenities: ((j['amenities'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        photos: ((j['photos'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        operatingHours: j['operating_hours'] as Map<String, dynamic>?,
        isActive: j['is_active'] == true,
      );

  @override
  List<Object?> get props => [
        id,
        partnerId,
        name,
        city,
        basePrice,
        radiusM,
        amenities,
        isActive,
      ];
}

class Partner extends Equatable {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final List<PartnerLocation> locations;

  const Partner({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.logoUrl,
    this.isActive = true,
    this.locations = const [],
  });

  String get categoryIcon => switch (category) {
        'gym' => '🏋️',
        'yoga' => '🧘',
        'pool' => '🏊',
        'spa' => '💆',
        'martial_arts' => '🥋',
        _ => '🏟️',
      };

  factory Partner.fromJson(Map<String, dynamic> j) {
    final locs = j['partner_locations'] as List<dynamic>? ?? [];
    return Partner(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? 'مركز رياضي',
      category: (j['category'] as String?) ?? 'gym',
      description: j['description'] as String?,
      logoUrl: j['logo_url'] as String?,
      isActive: j['is_active'] == true,
      locations: locs
          .map((location) => PartnerLocation.fromJson(
              Map<String, dynamic>.from(location as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, category, isActive, locations];
}
