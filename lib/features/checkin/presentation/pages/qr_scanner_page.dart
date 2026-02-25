import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../cubit/checkin_cubit.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _controller;
  bool _scanned = false;
  bool _torchOn = false;
  String _tr(String ar, String en) => context.trd(ar, en);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) {
      return;
    }
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
  }

  Future<void> _openManualTokenDialog() async {
    final tokenCtrl = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(
          _tr('إدخال QR يدويًا', 'Manual QR input'),
          style: GoogleFonts.cairo(
            color: C.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tokenCtrl,
              style: GoogleFonts.cairo(color: C.textPrimary),
              decoration: InputDecoration(
                hintText: _tr(
                  'ألصق التوكن هنا (مثال: SP-XXXXXXXXXXXX)',
                  'Paste token here (example: SP-XXXXXXXXXXXX)',
                ),
                hintStyle: GoogleFonts.cairo(color: C.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.qr_code_2_rounded, color: C.cyan),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text?.trim();
                  if (text != null && text.isNotEmpty) {
                    tokenCtrl.text = text;
                    tokenCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: tokenCtrl.text.length),
                    );
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(
                  _tr('لصق من الحافظة', 'Paste from clipboard'),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('إلغاء', 'Cancel'), style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              final value = tokenCtrl.text.trim();
              if (value.isEmpty) {
                return;
              }
              Navigator.pop(ctx, value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.cyan),
            child: Text(
              _tr('تحقق الآن', 'Validate now'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted || token == null || token.trim().isEmpty) {
      return;
    }

    setState(() => _scanned = true);
    context.read<CheckinCubit>().processQr(token.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckinCubit, CheckinState>(
      listener: (context, state) {
        if (state is CheckinSuccess) {
          context.pushReplacement(AppRouter.checkinResult, extra: state.result);
          return;
        }

        if (state is CheckinError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: C.red,
            ),
          );
          setState(() => _scanned = false);
        }
      },
      child: Scaffold(
        backgroundColor: C.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (_scanned) {
                  return;
                }
                final code = capture.barcodes.firstOrNull?.rawValue;
                if (code == null || code.trim().isEmpty) {
                  return;
                }
                setState(() => _scanned = true);
                context.read<CheckinCubit>().processQr(code);
              },
            ),
            _scrim(),
            SafeArea(
              child: Column(
                children: [
                  _topBar(context),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _tr('سجّل دخول النادي', 'Gym check-in'),
                      style: GoogleFonts.cairo(
                        color: C.textPrimary,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _tr(
                        'وجّه الكاميرا نحو رمز QR عند البوابة',
                        'Point your camera to the QR code at the gate',
                      ),
                      style: GoogleFonts.cairo(
                        color: C.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const _ScanFrame(),
                  const Spacer(),
                  _actionPanel(),
                  const SizedBox(height: 22),
                ],
              ),
            ),
            BlocBuilder<CheckinCubit, CheckinState>(
              builder: (context, state) {
                if (state is! CheckinProcessing) {
                  return const SizedBox.shrink();
                }
                return ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: C.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: C.cyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: C.cyan),
                              const SizedBox(height: 12),
                              Text(
                                _tr('جاري التحقق...', 'Verifying...'),
                                style: GoogleFonts.cairo(
                                  color: C.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: C.navy.withValues(alpha: 0.55),
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          _miniButton(
            icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onTap: _toggleTorch,
          ),
          const SizedBox(width: 8),
          _miniButton(
            icon: Icons.cameraswitch_rounded,
            onTap: _switchCamera,
          ),
        ],
      ),
    );
  }

  Widget _miniButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: C.navy.withValues(alpha: 0.55),
      ),
      icon: Icon(icon, color: Colors.white),
    );
  }

  Widget _actionPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.navy.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: C.cyan.withValues(alpha: 0.24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: C.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: C.cyan.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _tr('QR Scanner', 'QR Scanner'),
                        style: GoogleFonts.cairo(
                          color: C.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _scanned
                          ? _tr('تمت القراءة...', 'Scanned...')
                          : _tr('جاهز للمسح', 'Ready to scan'),
                      style: GoogleFonts.cairo(
                        color: _scanned ? C.warning : C.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _tr(
                    'حافظ على ثبات الكاميرا داخل الإطار للحصول على نتيجة أدق.',
                    'Keep the camera steady inside the frame for better accuracy.',
                  ),
                  style: GoogleFonts.cairo(
                    color: C.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _scanned ? null : _openManualTokenDialog,
                    icon: const Icon(Icons.keyboard_alt_rounded, size: 18),
                    label: Text(
                      _tr('إدخال التوكن يدويًا', 'Enter token manually'),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scrim() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            C.bg.withValues(alpha: 0.65),
            Colors.transparent,
            C.bg.withValues(alpha: 0.75),
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      height: 265,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
          ),
          ..._corners(),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 220,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    C.cyan.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 36.0;
    const stroke = 4.0;

    Widget corner(Alignment align, BorderRadius radius) {
      return Align(
        alignment: align,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border(
              top: BorderSide(
                color: align.y <= 0 ? C.cyan : Colors.transparent,
                width: stroke,
              ),
              bottom: BorderSide(
                color: align.y >= 0 ? C.cyan : Colors.transparent,
                width: stroke,
              ),
              left: BorderSide(
                color: align.x <= 0 ? C.cyan : Colors.transparent,
                width: stroke,
              ),
              right: BorderSide(
                color: align.x >= 0 ? C.cyan : Colors.transparent,
                width: stroke,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft,
          const BorderRadius.only(topLeft: Radius.circular(12))),
      corner(
        Alignment.topRight,
        const BorderRadius.only(topRight: Radius.circular(12)),
      ),
      corner(
        Alignment.bottomLeft,
        const BorderRadius.only(bottomLeft: Radius.circular(12)),
      ),
      corner(
        Alignment.bottomRight,
        const BorderRadius.only(bottomRight: Radius.circular(12)),
      ),
    ];
  }
}
