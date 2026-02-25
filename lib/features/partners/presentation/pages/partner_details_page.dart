import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/l10n/app_localizations.dart';
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
  String _tr(String ar, String en) => context.trd(ar, en);

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
          _tr('تفاصيل المركز', 'Center details'),
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
                _tr('تعذر تحميل بيانات المركز', 'Failed to load center data'),
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
                    _tr('لا توجد فروع مضافة بعد', 'No branches added yet'),
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
              partner.isActive
                  ? _tr('نشط', 'Active')
                  : _tr('متوقف', 'Inactive'),
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
                  formatCurrency(context, location.userPrice),
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
                Icons.pin_drop_outlined,
                AppLocalizations.of(context).isEnglish
                    ? 'Range ${location.radiusM.toInt()} m'
                    : '${_tr('نطاق', 'Range')} ${location.radiusM.toInt()}${_tr('م', 'm')}',
              ),
              _pill(
                Icons.paid_outlined,
                '${_tr('حصة النادي', 'Gym share')} ${formatCurrency(context, location.basePrice)}',
              ),
              _pill(
                Icons.account_balance_wallet_outlined,
                '${_tr('عمولة المنصة', 'Platform fee')} ${formatCurrency(context, location.platformFee)}',
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
              _tr('ساعات الدوام', 'Working hours'),
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
                    _tr('الاتجاهات', 'Directions'),
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
                    _tr('شيك إن عند الوصول', 'Check-in on arrival'),
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
      'sat': _tr('السبت', 'Saturday'),
      'sun': _tr('الأحد', 'Sunday'),
      'mon': _tr('الاثنين', 'Monday'),
      'tue': _tr('الثلاثاء', 'Tuesday'),
      'wed': _tr('الأربعاء', 'Wednesday'),
      'thu': _tr('الخميس', 'Thursday'),
      'fri': _tr('الجمعة', 'Friday'),
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
          content: Text(
            _tr('تعذر فتح تطبيق الخرائط', 'Unable to open maps application'),
            style: GoogleFonts.cairo(),
          ),
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
        return _tr('نادي رياضي', 'Gym');
      case 'pool':
        return _tr('مسبح', 'Pool');
      case 'yoga':
        return _tr('يوغا', 'Yoga');
      case 'spa':
        return _tr('سبا', 'Spa');
      case 'martial_arts':
        return _tr('فنون قتالية', 'Martial arts');
      default:
        return _tr('مركز رياضي', 'Fitness center');
    }
  }

  String _amenityLabel(String value) {
    switch (value) {
      case 'weights':
        return _tr('أوزان', 'Weights');
      case 'cardio':
        return _tr('كارديو', 'Cardio');
      case 'pool':
        return _tr('مسبح', 'Pool');
      case 'sauna':
        return _tr('ساونا', 'Sauna');
      case 'parking':
        return _tr('موقف سيارات', 'Parking');
      default:
        return value;
    }
  }
}
