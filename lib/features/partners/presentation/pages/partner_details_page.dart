import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';
import '../../domain/models/partner.dart';
import '../../domain/partners_repository.dart';

class PartnerDetailsPage extends StatefulWidget {
  final String partnerId;
  const PartnerDetailsPage({super.key, required this.partnerId});

  @override
  State<PartnerDetailsPage> createState() => _PartnerDetailsPageState();
}

class _PartnerDetailsPageState extends State<PartnerDetailsPage> {
  late Future<Partner?> _partnerFuture;

  @override
  void initState() {
    super.initState();
    _partnerFuture = sl<PartnersRepository>().getPartnerById(widget.partnerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(
          'تفاصيل المركز',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<Partner?>(
        future: _partnerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }

          final partner = snapshot.data;
          if (partner == null) {
            return Center(
              child: Text(
                'تعذر تحميل بيانات المركز',
                style: GoogleFonts.cairo(color: C.textSecondary),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _header(partner),
              const SizedBox(height: 14),
              if (partner.description?.trim().isNotEmpty == true)
                GlassCard(
                  child: Text(
                    partner.description!,
                    style: GoogleFonts.cairo(
                      color: C.textSecondary,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
              if (partner.description?.trim().isNotEmpty == true)
                const SizedBox(height: 14),
              ...partner.locations.map(_locationCard),
              if (partner.locations.isEmpty)
                GlassCard(
                  child: Text(
                    'لا توجد فروع مضافة بعد',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: C.textSecondary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(Partner partner) {
    return GlassCard(
      borderColor: C.cyan.withValues(alpha: 0.3),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          C.cyan.withValues(alpha: 0.12),
          C.navy.withValues(alpha: 0.5),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: C.cyanGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                partner.categoryIcon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: GoogleFonts.cairo(
                    color: C.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _categoryLabel(partner.category),
                  style: GoogleFonts.cairo(
                    color: C.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: partner.isActive
                  ? C.green.withValues(alpha: 0.18)
                  : C.red.withValues(alpha: 0.15),
            ),
            child: Text(
              partner.isActive ? 'نشط' : 'متوقف',
              style: GoogleFonts.cairo(
                color: partner.isActive ? C.green : C.red,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(PartnerLocation location) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: location.isActive
          ? C.cyan.withValues(alpha: 0.24)
          : C.border.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  location.name,
                  style: GoogleFonts.cairo(
                    color: C.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: C.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatSYP(location.userPrice),
                  style: GoogleFonts.cairo(
                    color: C.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (location.addressText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              location.addressText!,
              style: GoogleFonts.cairo(color: C.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(Icons.location_city_rounded, location.city),
              _pill(
                  Icons.pin_drop_outlined, 'نطاق ${location.radiusM.toInt()}م'),
              _pill(Icons.paid_outlined,
                  'حصة النادي ${formatSYP(location.basePrice)}'),
              _pill(
                Icons.account_balance_wallet_outlined,
                'عمولة المنصة ${formatSYP(location.platformFee)}',
              ),
            ],
          ),
          if (location.amenities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: location.amenities
                  .map((amenity) => _chip(_amenityLabel(amenity)))
                  .toList(),
            ),
          ],
          if (location.operatingHours != null &&
              location.operatingHours!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ساعات الدوام',
              style: GoogleFonts.cairo(
                color: C.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ..._buildOperatingHours(location.operatingHours!),
          ],
          if (location.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: location.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final url = location.photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 130,
                        color: C.surfaceAlt,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: C.textMuted),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(location),
                  icon: const Icon(Icons.directions_rounded),
                  label: Text(
                    'الاتجاهات',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRouter.scanner),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    'شيك إن عند الوصول',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOperatingHours(Map<String, dynamic> hours) {
    final order = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];
    final labels = {
      'sat': 'السبت',
      'sun': 'الأحد',
      'mon': 'الاثنين',
      'tue': 'الثلاثاء',
      'wed': 'الأربعاء',
      'thu': 'الخميس',
      'fri': 'الجمعة',
    };
    final widgets = <Widget>[];
    for (final day in order) {
      final raw = hours[day];
      if (raw is! Map) {
        continue;
      }
      final data = Map<String, dynamic>.from(raw);
      final open = (data['open'] ?? '').toString();
      final close = (data['close'] ?? '').toString();
      if (open.isEmpty || close.isEmpty) {
        continue;
      }
      widgets.add(
        Text(
          '${labels[day]}: $open - $close',
          style: GoogleFonts.cairo(
            color: C.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _openDirections(PartnerLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.lat},${location.lng}&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح تطبيق الخرائط', style: GoogleFonts.cairo()),
          backgroundColor: C.red,
        ),
      );
    }
  }

  Widget _pill(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: C.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: C.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: C.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'gym':
        return 'نادي رياضي';
      case 'pool':
        return 'مسبح';
      case 'yoga':
        return 'يوغا';
      case 'spa':
        return 'سبا';
      case 'martial_arts':
        return 'فنون قتالية';
      default:
        return 'مركز رياضي';
    }
  }

  String _amenityLabel(String value) {
    switch (value) {
      case 'weights':
        return 'أوزان';
      case 'cardio':
        return 'كارديو';
      case 'pool':
        return 'مسبح';
      case 'sauna':
        return 'ساونا';
      case 'parking':
        return 'موقف سيارات';
      default:
        return value;
    }
  }
}
