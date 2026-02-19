import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/utils.dart';
import '../../../partners/domain/models/partner.dart';
import '../../../partners/presentation/cubit/partners_cubit.dart';

class MapDiscoveryPage extends StatefulWidget {
  const MapDiscoveryPage({super.key});

  @override
  State<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends State<MapDiscoveryPage> {
  final MapController _mapCtrl = MapController();

  LatLng _center = const LatLng(33.5138, 36.2765);
  LatLng? _userPos;
  _PartnerPoint? _selected;
  bool _listView = false;
  bool _locationDenied = false;
  bool _mapLoadFailed = false;

  String _search = '';
  String _city = 'الكل';
  final Set<String> _categories = {};
  final Set<String> _amenities = {};
  RangeValues _priceRange = const RangeValues(0, 60000);
  double _distanceKm = 25;
  bool _useDistanceFilter = false;

  @override
  void initState() {
    super.initState();
    context.read<PartnersCubit>().loadPartners();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationDenied = true);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _center = _userPos!;
        _locationDenied = false;
      });
    } catch (_) {
      // Ignore location failures; map still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'اكتشف المراكز',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(_listView ? Icons.map_rounded : Icons.list_rounded,
                color: C.cyan),
            tooltip: _listView ? 'عرض الخريطة' : 'عرض القائمة',
            onPressed: () => setState(() => _listView = !_listView),
          ),
        ],
      ),
      body: BlocBuilder<PartnersCubit, PartnersState>(
        builder: (context, state) {
          if (state is PartnersLoading) {
            return const Center(
                child: CircularProgressIndicator(color: C.cyan));
          }

          if (state is! PartnersLoaded) {
            return const SizedBox.shrink();
          }

          final allPoints = _flatten(state.partners);
          final filtered = _applyFilters(allPoints);

          return _listView
              ? _buildListView(filtered, allPoints)
              : _buildMapView(filtered, allPoints);
        },
      ),
    );
  }

  List<_PartnerPoint> _flatten(List<Partner> partners) {
    final points = <_PartnerPoint>[];
    for (final partner in partners) {
      if (!partner.isActive) {
        continue;
      }
      for (final location in partner.locations) {
        if (!location.isActive) {
          continue;
        }
        points.add(_PartnerPoint(partner: partner, location: location));
      }
    }
    return points;
  }

  List<_PartnerPoint> _applyFilters(List<_PartnerPoint> points) {
    final query = _search.trim().toLowerCase();

    return points.where((point) {
      final partner = point.partner;
      final location = point.location;

      if (_city != 'الكل' && location.city != _city) {
        return false;
      }

      if (_categories.isNotEmpty && !_categories.contains(partner.category)) {
        return false;
      }

      if (_amenities.isNotEmpty &&
          location.amenities.toSet().intersection(_amenities).isEmpty) {
        return false;
      }

      final userPrice = location.userPrice;
      if (userPrice < _priceRange.start || userPrice > _priceRange.end) {
        return false;
      }

      if (query.isNotEmpty) {
        final partnerName = partner.name.toLowerCase();
        final locationName = location.name.toLowerCase();
        if (!partnerName.contains(query) && !locationName.contains(query)) {
          return false;
        }
      }

      if (_userPos != null && _useDistanceFilter) {
        final distanceMeters = Geolocator.distanceBetween(
          _userPos!.latitude,
          _userPos!.longitude,
          location.lat,
          location.lng,
        );
        if (distanceMeters > _distanceKm * 1000) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildMapView(
      List<_PartnerPoint> points, List<_PartnerPoint> allPoints) {
    if (_selected != null && !points.contains(_selected)) {
      _selected = null;
    }

    final markers = <Marker>[];

    if (_userPos != null) {
      markers.add(
        Marker(
          point: _userPos!,
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: C.cyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: C.cyan, width: 2),
            ),
            child: const Icon(Icons.my_location, color: C.cyan, size: 20),
          ),
        ),
      );
    }

    for (final point in points) {
      markers.add(
        Marker(
          point: LatLng(point.location.lat, point.location.lng),
          width: 48,
          height: 56,
          child: GestureDetector(
            onTap: () => setState(() => _selected = point),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selected == point ? C.cyan : C.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.cyan, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(point.partner.categoryIcon,
                      style: const TextStyle(fontSize: 18)),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: C.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sportpass.app',
              maxZoom: 19,
              errorTileCallback: (_, __, ___) {
                if (!mounted || _mapLoadFailed) {
                  return;
                }
                setState(() => _mapLoadFailed = true);
              },
              tileBuilder: _adaptiveTileBuilder,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _topFilterBar(points, allPoints),
        ),
        Positioned(
          right: 16,
          bottom: _selected != null ? 240 : 20,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            onPressed: () {
              if (_userPos != null) {
                _mapCtrl.move(_userPos!, 15);
              }
            },
            backgroundColor: C.surface,
            child: const Icon(Icons.my_location, color: C.cyan, size: 20),
          ),
        ),
        if (_selected == null)
          Positioned(
            left: 16,
            bottom: 20,
            child: FloatingActionButton.extended(
              heroTag: 'quick-checkin',
              onPressed: () => context.push(AppRouter.scanner),
              backgroundColor: C.cyan,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(
                'شيك إن',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        if (_locationDenied)
          Positioned(
            right: 12,
            left: 12,
            bottom: _selected != null ? 244 : 80,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.gold.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.gold.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: C.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم رفض إذن الموقع. يمكنك المتابعة عبر البحث أو الفلاتر.',
                      style: GoogleFonts.cairo(
                        color: C.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_mapLoadFailed)
          Positioned(
            top: 72,
            left: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.red.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: C.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تعذر تحميل بلاطات الخريطة. تحقق من الإنترنت ثم أعد المحاولة.',
                      style: GoogleFonts.cairo(
                        color: C.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _mapLoadFailed = false),
                    child:
                        Text('إخفاء', style: GoogleFonts.cairo(color: C.red)),
                  ),
                ],
              ),
            ),
          ),
        if (_selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPreview(_selected!),
          ),
      ],
    );
  }

  Widget _buildListView(
      List<_PartnerPoint> points, List<_PartnerPoint> allPoints) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _topFilterBar(points, allPoints),
        ),
        Expanded(
          child: points.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد نتائج مطابقة للفلاتر',
                    style: GoogleFonts.cairo(color: C.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    final distance = _distanceFromUser(point.location);
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selected = point);
                        if (!_listView) {
                          _mapCtrl.move(
                            LatLng(point.location.lat, point.location.lng),
                            15,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: C.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: C.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: C.cyanGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      point.partner.categoryIcon,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point.partner.name,
                                        style: GoogleFonts.cairo(
                                          color: C.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        point.location.name,
                                        style: GoogleFonts.cairo(
                                          color: C.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (distance != null)
                                        Text(
                                          distance < 1000
                                              ? '${distance.toInt()}م'
                                              : '${(distance / 1000).toStringAsFixed(1)}كم',
                                          style: GoogleFonts.cairo(
                                            color: C.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatSYP(point.location.userPrice),
                                  style: GoogleFonts.cairo(
                                    color: C.gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _openDirections(point.location),
                                    icon: const Icon(Icons.directions_rounded,
                                        size: 18),
                                    label: Text(
                                      'الاتجاهات',
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        context.push(AppRouter.scanner),
                                    icon: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 18),
                                    label: Text(
                                      'شيك إن',
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _topFilterBar(
      List<_PartnerPoint> filtered, List<_PartnerPoint> allPoints) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              style: GoogleFonts.cairo(color: C.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'ابحث باسم النادي أو الفرع',
                hintStyle: GoogleFonts.cairo(color: C.textMuted),
                filled: true,
                fillColor: C.bg.withValues(alpha: 0.45),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: C.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: () => _openFilters(allPoints),
            style: FilledButton.styleFrom(
              backgroundColor: C.cyan.withValues(alpha: 0.16),
              foregroundColor: C.cyan,
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              'فلترة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.bg.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${filtered.length}',
              style: GoogleFonts.cairo(
                color: C.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(List<_PartnerPoint> allPoints) async {
    final cities = {'الكل', ...allPoints.map((e) => e.location.city)}.toList();
    final categories =
        allPoints.map((e) => e.partner.category).toSet().toList();
    final amenities =
        allPoints.expand((e) => e.location.amenities).toSet().toList();

    var selectedCity = _city;
    final selectedCategories = {..._categories};
    final selectedAmenities = {..._amenities};
    var priceRange = _priceRange;
    var distanceKm = _distanceKm;
    var useDistanceFilter = _useDistanceFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: C.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'فلاتر الخريطة',
                      style: GoogleFonts.cairo(
                        color: C.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('المدينة',
                        style: GoogleFonts.cairo(
                            color: C.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cities.map((city) {
                        final selected = selectedCity == city;
                        return ChoiceChip(
                          label: Text(city, style: GoogleFonts.cairo()),
                          selected: selected,
                          onSelected: (_) {
                            setModalState(() => selectedCity = city);
                          },
                          selectedColor: C.cyan.withValues(alpha: 0.2),
                          labelStyle: GoogleFonts.cairo(
                            color: selected ? C.cyan : C.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('الفئة',
                        style: GoogleFonts.cairo(
                            color: C.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final selected = selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(_categoryLabel(category),
                              style: GoogleFonts.cairo()),
                          selected: selected,
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: C.cyan.withValues(alpha: 0.2),
                          checkmarkColor: C.cyan,
                          labelStyle: GoogleFonts.cairo(
                            color: selected ? C.cyan : C.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('المرافق',
                        style: GoogleFonts.cairo(
                            color: C.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities.map((amenity) {
                        final selected = selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(_amenityLabel(amenity),
                              style: GoogleFonts.cairo()),
                          selected: selected,
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selectedAmenities.add(amenity);
                              } else {
                                selectedAmenities.remove(amenity);
                              }
                            });
                          },
                          selectedColor: C.cyan.withValues(alpha: 0.2),
                          checkmarkColor: C.cyan,
                          labelStyle: GoogleFonts.cairo(
                            color: selected ? C.cyan : C.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'نطاق السعر (${priceRange.start.toInt()} - ${priceRange.end.toInt()} ل.س)',
                      style: GoogleFonts.cairo(
                        color: C.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 60000,
                      divisions: 120,
                      activeColor: C.cyan,
                      labels: RangeLabels(
                        priceRange.start.toInt().toString(),
                        priceRange.end.toInt().toString(),
                      ),
                      onChanged: (value) =>
                          setModalState(() => priceRange = value),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useDistanceFilter,
                      activeThumbColor: C.cyan,
                      onChanged: _userPos == null
                          ? null
                          : (value) =>
                              setModalState(() => useDistanceFilter = value),
                      title: Text(
                        'تفعيل فلتر المسافة',
                        style: GoogleFonts.cairo(
                          color: C.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _userPos == null
                            ? 'فعّل الموقع أولاً لاستخدام المسافة'
                            : 'إخفاء النوادي الأبعد من المسافة المحددة',
                        style: GoogleFonts.cairo(
                          color: C.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      'المسافة من موقعك (${distanceKm.toStringAsFixed(0)} كم)',
                      style: GoogleFonts.cairo(
                        color:
                            useDistanceFilter ? C.textSecondary : C.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: distanceKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: C.cyan,
                      label: '${distanceKm.toStringAsFixed(0)} كم',
                      onChanged: useDistanceFilter
                          ? (value) => setModalState(() => distanceKm = value)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _city = 'الكل';
                                _categories.clear();
                                _amenities.clear();
                                _priceRange = const RangeValues(0, 60000);
                                _distanceKm = 25;
                                _useDistanceFilter = false;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'إعادة تعيين',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _city = selectedCity;
                                _categories
                                  ..clear()
                                  ..addAll(selectedCategories);
                                _amenities
                                  ..clear()
                                  ..addAll(selectedAmenities);
                                _priceRange = priceRange;
                                _distanceKm = distanceKm;
                                _useDistanceFilter =
                                    _userPos != null && useDistanceFilter;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'تطبيق الفلاتر',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreview(_PartnerPoint point) {
    final location = point.location;
    final distance = _distanceFromUser(location);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: C.cyan.withValues(alpha: 0.28))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: C.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: C.cyanGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(point.partner.categoryIcon,
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.partner.name,
                      style: GoogleFonts.cairo(
                        color: C.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      location.name,
                      style: GoogleFonts.cairo(
                          color: C.textSecondary, fontSize: 12),
                    ),
                    if (distance != null)
                      Text(
                        distance < 1000
                            ? '${distance.toInt()}م'
                            : '${(distance / 1000).toStringAsFixed(1)}كم',
                        style:
                            GoogleFonts.cairo(color: C.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatSYP(location.userPrice),
                    style: GoogleFonts.cairo(
                      color: C.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text('لكل زيارة',
                      style:
                          GoogleFonts.cairo(color: C.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(AppRouter.scanner),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _openDirections(location),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(52, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.directions_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.push(
                  AppRouter.partnerDetails
                      .replaceFirst(':id', point.partner.id),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(52, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.info_outline_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adaptiveTileBuilder(
      BuildContext context, Widget tileWidget, TileImage tile) {
    // Keep original map colors to avoid ultra-dark rendering on some devices.
    return tileWidget;
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

  double? _distanceFromUser(PartnerLocation location) {
    if (_userPos == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _userPos!.latitude,
      _userPos!.longitude,
      location.lat,
      location.lng,
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'gym':
        return 'نادي';
      case 'pool':
        return 'مسبح';
      case 'yoga':
        return 'يوغا';
      case 'spa':
        return 'سبا';
      case 'martial_arts':
        return 'فنون قتالية';
      default:
        return category;
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
        return 'موقف';
      default:
        return value;
    }
  }
}

class _PartnerPoint {
  final Partner partner;
  final PartnerLocation location;

  const _PartnerPoint({required this.partner, required this.location});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PartnerPoint &&
        other.partner.id == partner.id &&
        other.location.id == location.id;
  }

  @override
  int get hashCode => Object.hash(partner.id, location.id);
}
