import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';

class AddLocationPage extends StatefulWidget {
  final String partnerId;
  const AddLocationPage({super.key, required this.partnerId});
  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '33.5138');
  final _lngCtrl = TextEditingController(text: '36.2765');
  final _photosCtrl = TextEditingController();
  final MapController _mapCtrl = MapController();

  double _radius = 150;
  bool _loading = false;
  LatLng _pickedPoint = const LatLng(33.5138, 36.2765);
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  @override
  void initState() {
    super.initState();
    _setPoint(_pickedPoint, moveMap: false);
  }

  void _setPoint(LatLng point, {bool moveMap = true}) {
    setState(() {
      _pickedPoint = point;
      _latCtrl.text = point.latitude.toStringAsFixed(6);
      _lngCtrl.text = point.longitude.toStringAsFixed(6);
    });
    if (moveMap) {
      _mapCtrl.move(point, 15);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _photosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final initial = isOpen
        ? (_openTime ?? const TimeOfDay(hour: 6, minute: 0))
        : (_closeTime ?? const TimeOfDay(hour: 22, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic>? _buildOperatingHours() {
    if (_openTime == null || _closeTime == null) {
      return null;
    }
    final open = _formatTime(_openTime!);
    final close = _formatTime(_closeTime!);
    const days = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];
    return {
      for (final day in days) day: {'open': open, 'close': close}
    };
  }

  List<String> _parsePhotos() {
    return _photosCtrl.text
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يلزم السماح بالوصول للموقع',
                  style: GoogleFonts.cairo()),
              backgroundColor: C.red,
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      _setPoint(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تعذر جلب الموقع الحالي: $e', style: GoogleFonts.cairo()),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('أدخل اسم الفرع', style: GoogleFonts.cairo()),
            backgroundColor: C.red),
      );
      return;
    }
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('حدد موقعًا صحيحًا على الخريطة',
                style: GoogleFonts.cairo()),
            backgroundColor: C.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final photos = _parsePhotos();
      final operatingHours = _buildOperatingHours();
      final payload = <String, dynamic>{
        'partner_id': widget.partnerId,
        'name': _nameCtrl.text.trim(),
        'address_text': _addressCtrl.text.trim(),
        'lat': lat,
        'lng': lng,
        'radius_m': _radius,
        'base_price': 8000, // Default: admin will adjust
        'is_active': false, // Requires admin approval
      };
      if (photos.isNotEmpty) {
        payload['photos'] = photos;
      }
      if (operatingHours != null) {
        payload['operating_hours'] = operatingHours;
      }

      // Note: base_price will be set by admin later
      // Gym owner only provides location details
      await Supabase.instance.client.from('partner_locations').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تمت إضافة الفرع بنجاح! في انتظار موافقة المدير',
                  style: GoogleFonts.cairo()),
              backgroundColor: C.green),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRouter.myGym);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e', style: GoogleFonts.cairo()),
              backgroundColor: C.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text('إضافة فرع',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: C.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            GlassCard(
              gradient: C.goldGradient,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'سيقوم المدير بمراجعة الفرع وتحديد السعر قبل تفعيله',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Branch name
            _label('اسم الفرع'),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                  hintText: 'مثال: فرع المالكي',
                  prefixIcon: const Icon(Icons.location_city, color: C.cyan)),
            ).animate().fadeIn(),

            const SizedBox(height: 20),
            _label('العنوان'),
            TextField(
              controller: _addressCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                  hintText: 'دمشق - المالكي',
                  prefixIcon: const Icon(Icons.pin_drop, color: C.cyan)),
            ).animate().fadeIn(delay: 50.ms),

            const SizedBox(height: 20),

            _label('حدد الموقع على الخريطة'),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _pickedPoint,
                    initialZoom: 14,
                    onTap: (_, point) => _setPoint(point, moveMap: false),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sportpass.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pickedPoint,
                          width: 52,
                          height: 52,
                          child: const Icon(Icons.location_pin,
                              color: C.cyan, size: 44),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text('موقعي الحالي',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(foregroundColor: C.cyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    style:
                        GoogleFonts.cairo(color: C.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'خط العرض'),
                    onSubmitted: (_) {
                      final lat = double.tryParse(_latCtrl.text.trim());
                      final lng = double.tryParse(_lngCtrl.text.trim());
                      if (lat != null && lng != null) {
                        _setPoint(LatLng(lat, lng));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    style:
                        GoogleFonts.cairo(color: C.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'خط الطول'),
                    onSubmitted: (_) {
                      final lat = double.tryParse(_latCtrl.text.trim());
                      final lng = double.tryParse(_lngCtrl.text.trim());
                      if (lat != null && lng != null) {
                        _setPoint(LatLng(lat, lng));
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Radius
            _label('نطاق الجيوفنسينغ: ${_radius.toInt()} متر'),
            Slider(
              value: _radius,
              min: 50,
              max: 300,
              divisions: 25,
              activeColor: C.cyan,
              inactiveColor: C.surfaceAlt,
              onChanged: (v) => setState(() => _radius = v),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            _label('ساعات الدوام (اختياري)'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isOpen: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _openTime == null
                          ? 'وقت الفتح'
                          : 'فتح ${_formatTime(_openTime!)}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isOpen: false),
                    icon: const Icon(Icons.schedule_send_rounded),
                    label: Text(
                      _closeTime == null
                          ? 'وقت الإغلاق'
                          : 'إغلاق ${_formatTime(_closeTime!)}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 170.ms),

            const SizedBox(height: 20),
            _label('صور الفرع (روابط - اختياري)'),
            TextField(
              controller: _photosCtrl,
              maxLines: 3,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                hintText: 'ضع روابط الصور مفصولة بفاصلة أو سطر جديد',
                hintStyle: GoogleFonts.cairo(color: C.textMuted, fontSize: 12),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 42),
                  child: Icon(Icons.image_outlined, color: C.cyan),
                ),
              ),
            ).animate().fadeIn(delay: 190.ms),

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: Text(_loading ? 'جاري الحفظ...' : 'إرسال للمراجعة',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: C.green),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: C.textPrimary,
                fontSize: 14)),
      );
}
