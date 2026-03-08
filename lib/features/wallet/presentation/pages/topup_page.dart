import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/payment_config.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/wallet_cubit.dart';

class TopupPage extends StatefulWidget {
  final double? amount;
  const TopupPage({super.key, this.amount});
  @override
  State<TopupPage> createState() => _TopupPageState();
}

class _TopupPageState extends State<TopupPage> {
  final _amountCtrl = TextEditingController();
  final _txIdCtrl = TextEditingController();
  int? _selectedPreset;
  File? _receiptImage;
  bool _uploading = false;

  final _presets = [500, 1000, 2000, 5000];
  String _tr(String ar, String en) => context.trd(ar, en);
  Color _onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  Color _surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  Color _surfaceAlt(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return C.surfaceAlt;
    }
    return const Color(0xFFF0F5FA);
  }

  Color _divider(BuildContext context) => Theme.of(context).dividerColor;

  Color _secondary(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return C.textSecondary;
    }
    return const Color(0xFF4E6580);
  }

  Color _muted(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return C.textMuted;
    }
    return const Color(0xFF6D8199);
  }

  Future<void> _copyText(String value, String arDone, String enDone) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_tr(arDone, enDone), style: GoogleFonts.cairo()),
        backgroundColor: C.green,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    String? suffixText,
    TextStyle? suffixStyle,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.cairo(color: _muted(context)),
      suffixText: suffixText,
      suffixStyle: suffixStyle ?? GoogleFonts.cairo(color: _muted(context)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _surfaceAlt(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.cyan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _divider(context).withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountCtrl.text = sypStorageToDisplay(widget.amount!).toStringAsFixed(0);
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_tr('اختر مصدر الصورة', 'Choose image source'),
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: _onSurface(context),
                  fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: C.cyan),
            title: Text(_tr('الكاميرا', 'Camera'),
                style: GoogleFonts.cairo(color: _onSurface(context))),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: C.gold),
            title: Text(_tr('المعرض', 'Gallery'),
                style: GoogleFonts.cairo(color: _onSurface(context))),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final file = await picker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 80);
    if (file != null) setState(() => _receiptImage = File(file.path));
  }

  Future<String?> _uploadReceipt() async {
    if (_receiptImage == null) return null;
    setState(() => _uploading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      final filename =
          'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('receipts')
          .upload(filename, _receiptImage!);
      return Supabase.instance.client.storage
          .from('receipts')
          .getPublicUrl(filename);
    } catch (e) {
      return null;
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildShamCashTransferCard() {
    return GlassCard(
      borderColor: C.cyan.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: C.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                _tr('التحويل عبر شام كاش', 'Transfer via ShamCash'),
                style: GoogleFonts.cairo(
                  color: _onSurface(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _tr('اسم المستفيد', 'Beneficiary name'),
            style: GoogleFonts.cairo(color: _muted(context), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            PaymentConfig.shamCashBeneficiaryName,
            style: GoogleFonts.cairo(
              color: _onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr('رقم الحساب', 'Account ID'),
            style: GoogleFonts.cairo(color: _muted(context), fontSize: 11),
          ),
          const SizedBox(height: 2),
          SelectableText(
            PaymentConfig.shamCashAccountId,
            style: GoogleFonts.cairo(
              color: _onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.border),
              ),
              child: QrImageView(
                data: PaymentConfig.shamCashQrData,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyText(
                    PaymentConfig.shamCashAccountId,
                    'تم نسخ رقم الحساب',
                    'Account ID copied',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    _tr('نسخ رقم الحساب', 'Copy account ID'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              'بعد التحويل: أدخل رقم العملية وارفع صورة الإيصال لإرسال طلب الشحن.',
              'After transfer: enter the transaction ID and upload receipt image to submit top-up request.',
            ),
            style: GoogleFonts.cairo(
              color: _secondary(context),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final canTopup =
        authState is AuthAuthenticated && authState.user.role == 'athlete';

    if (!canTopup) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_tr('شحن المحفظة', 'Top up wallet'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: _onSurface(context),
              )),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _tr('ميزة شحن الرصيد متاحة لحساب الرياضي فقط.',
                  'Top-up is available for athlete accounts only.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: _muted(context), fontSize: 15),
            ),
          ),
        ),
      );
    }

    return BlocListener<WalletCubit, WalletState>(
      listener: (ctx, state) {
        if (state is TopupSubmitted) {
          if (state.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      _tr('تم إرسال طلب الشحن بنجاح! سيتم مراجعته قريباً',
                          'Top-up request submitted successfully. It will be reviewed soon.'),
                      style: GoogleFonts.cairo()),
                  backgroundColor: C.green),
            );
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      _tr('فشل إرسال الطلب', 'Failed to submit request'),
                      style: GoogleFonts.cairo()),
                  backgroundColor: C.red),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_tr('شحن المحفظة', 'Top up wallet'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: _onSurface(context),
              )),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance
              BlocBuilder<WalletCubit, WalletState>(
                builder: (ctx, state) {
                  double balance = 0;
                  if (state is WalletLoaded) balance = state.wallet.balance;
                  return GlassCard(
                    gradient: C.walletGradient,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _tr('رصيدك الحالي', 'Your current balance'),
                                    style: GoogleFonts.cairo(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(formatCurrency(context, balance),
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                              ]),
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white54, size: 40),
                        ]),
                  );
                },
              ).animate().fadeIn(),

              const SizedBox(height: 28),

              _buildShamCashTransferCard().animate().fadeIn(delay: 80.ms),

              const SizedBox(height: 20),

              // Presets
              if (widget.amount == null) ...[
                Text(_tr('اختر مبلغ الشحن', 'Choose top-up amount'),
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _onSurface(context))),
                const SizedBox(height: 12),
                Row(
                  children: _presets.asMap().entries.map((e) {
                    final i = e.key;
                    final v = e.value;
                    final selected = _selectedPreset == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedPreset = i;
                          _amountCtrl.text = v.toString();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                              left: i < _presets.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: selected ? C.cyanGradient : null,
                            color: selected ? null : _surfaceAlt(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? C.cyan
                                  : _divider(context).withValues(alpha: 0.8),
                            ),
                          ),
                          child: Center(
                              child: Text(
                                  formatCurrency(context, v,
                                      includeCurrency: false,
                                      valueIsStorage: false),
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? C.navy
                                          : _secondary(context)))),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                Text(_tr('أو أدخل مبلغ مخصص', 'Or enter a custom amount'),
                    style: GoogleFonts.cairo(
                        color: _secondary(context), fontSize: 14)),
                const SizedBox(height: 8),
              ],

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                readOnly: widget.amount != null,
                cursorColor: C.cyan,
                style:
                    GoogleFonts.cairo(color: _onSurface(context), fontSize: 20),
                decoration: _fieldDecoration(
                  hintText: _tr('مثال: 500', 'Example: 500'),
                  suffixText: currencyLabel(context),
                  suffixStyle: GoogleFonts.cairo(color: _muted(context)),
                  prefixIcon: const Icon(Icons.attach_money, color: C.cyan),
                ),
                onChanged: (_) => setState(() => _selectedPreset = null),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // TX ID
              Text(_tr('رقم معاملة شام كاش', 'ShamCash transaction ID'),
                  style: GoogleFonts.cairo(
                      color: _secondary(context), fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                  _tr('أدخل رقم العملية كما يظهر في إيصال شام كاش',
                      'Enter the transaction number exactly as shown on the ShamCash receipt'),
                  style:
                      GoogleFonts.cairo(color: _muted(context), fontSize: 11)),
              const SizedBox(height: 8),
              TextField(
                controller: _txIdCtrl,
                cursorColor: C.cyan,
                style: GoogleFonts.cairo(color: _onSurface(context)),
                decoration: _fieldDecoration(
                  hintText: _tr('مثال: SC-12345678', 'Example: SC-12345678'),
                  prefixIcon: const Icon(Icons.receipt, color: C.cyan),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Receipt upload
              Text(_tr('صورة الإيصال (اختياري)', 'Receipt image (optional)'),
                  style: GoogleFonts.cairo(
                      color: _secondary(context), fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickReceipt,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: _receiptImage != null ? 200 : 100,
                  decoration: BoxDecoration(
                    color: _surfaceAlt(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _receiptImage != null
                            ? C.green
                            : _divider(context).withValues(alpha: 0.6),
                        style: _receiptImage != null
                            ? BorderStyle.solid
                            : BorderStyle.none),
                    image: _receiptImage != null
                        ? DecorationImage(
                            image: FileImage(_receiptImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _receiptImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_a_photo,
                                  color: _muted(context), size: 32),
                              const SizedBox(height: 8),
                              Text(
                                  _tr('التقط صورة الإيصال أو اختر من المعرض',
                                      'Take a receipt photo or choose one from gallery'),
                                  style: GoogleFonts.cairo(
                                      color: _muted(context), fontSize: 12)),
                            ])
                      : Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: C.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 16),
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _uploading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final walletCubit = context.read<WalletCubit>();
                          final amountDisplay =
                              parseSypDisplayInput(_amountCtrl.text);
                          final txId = _txIdCtrl.text.trim();
                          if (amountDisplay == null || amountDisplay <= 0) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(
                                    _tr('أدخل مبلغ صحيح',
                                        'Enter a valid amount'),
                                    style: GoogleFonts.cairo()),
                                backgroundColor: C.red));
                            return;
                          }
                          if (txId.isEmpty) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(
                                    _tr('أدخل رقم المعاملة',
                                        'Enter transaction ID'),
                                    style: GoogleFonts.cairo()),
                                backgroundColor: C.red));
                            return;
                          }
                          // Upload receipt if present
                          String? receiptUrl;
                          if (_receiptImage != null) {
                            receiptUrl = await _uploadReceipt();
                          }
                          if (!mounted) return;
                          final notes =
                              'Method: ${PaymentConfig.shamCashProvider} | '
                              'Beneficiary: ${PaymentConfig.shamCashBeneficiaryName} | '
                              'Account: ${PaymentConfig.shamCashAccountId} | '
                              'TX: $txId';
                          final amountStorage =
                              sypDisplayToStorage(amountDisplay);
                          walletCubit.submitTopup(amountStorage,
                              proofUrl: receiptUrl, notes: notes);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: C.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _uploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_tr('إرسال طلب الشحن', 'Submit top-up request'),
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 20),

              GlassCard(
                borderColor: C.gold.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: C.gold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              _tr(
                                'سيتم مراجعة طلبك وشحن رصيدك خلال دقائق. أنت تدفع فقط سعر الدخول المعلن لكل نادي.',
                                'Your request will be reviewed and your balance charged within minutes. You only pay each gym published entry price.',
                              ),
                              style: GoogleFonts.cairo(
                                  color: _muted(context),
                                  fontSize: 12,
                                  height: 1.6))),
                    ]),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
