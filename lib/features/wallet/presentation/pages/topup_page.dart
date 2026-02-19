import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final _presets = [50000, 100000, 200000, 500000];

  InputDecoration _fieldDecoration({
    String? hintText,
    String? suffixText,
    TextStyle? suffixStyle,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.cairo(color: C.textMuted),
      suffixText: suffixText,
      suffixStyle: suffixStyle ?? GoogleFonts.cairo(color: C.textMuted),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: C.surfaceAlt,
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
        borderSide: BorderSide(color: C.border.withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountCtrl.text = widget.amount!.toStringAsFixed(0);
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('اختر مصدر الصورة',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary,
                  fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: C.cyan),
            title: Text('الكاميرا',
                style: GoogleFonts.cairo(color: C.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: C.gold),
            title:
                Text('المعرض', style: GoogleFonts.cairo(color: C.textPrimary)),
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final canTopup =
        authState is AuthAuthenticated && authState.user.role == 'athlete';

    if (!canTopup) {
      return Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text('شحن المحفظة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: C.bg,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'ميزة شحن الرصيد متاحة لحساب الرياضي فقط.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: C.textMuted, fontSize: 15),
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
                  content: Text('تم إرسال طلب الشحن بنجاح! سيتم مراجعته قريباً',
                      style: GoogleFonts.cairo()),
                  backgroundColor: C.green),
            );
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('فشل إرسال الطلب', style: GoogleFonts.cairo()),
                  backgroundColor: C.red),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text('شحن المحفظة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          backgroundColor: C.bg,
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
                                Text('رصيدك الحالي',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(formatSYP(balance),
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

              // Presets
              if (widget.amount == null) ...[
                Text('اختر مبلغ الشحن',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: C.textPrimary)),
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
                            color: selected ? null : C.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: selected ? C.cyan : C.border),
                          ),
                          child: Center(
                              child: Text(formatSYP(v),
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? C.navy
                                          : C.textSecondary))),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                Text('أو أدخل مبلغ مخصص',
                    style: GoogleFonts.cairo(
                        color: C.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
              ],

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                readOnly: widget.amount != null,
                cursorColor: C.cyan,
                style: GoogleFonts.cairo(color: C.textPrimary, fontSize: 20),
                decoration: _fieldDecoration(
                  hintText: 'مثال: 50000',
                  suffixText: 'ل.س',
                  suffixStyle: GoogleFonts.cairo(color: C.textMuted),
                  prefixIcon: const Icon(Icons.attach_money, color: C.cyan),
                ),
                onChanged: (_) => setState(() => _selectedPreset = null),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // TX ID
              Text('رقم معاملة شام كاش',
                  style:
                      GoogleFonts.cairo(color: C.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text('أدخل رقم العملية كما يظهر في إيصال شام كاش',
                  style: GoogleFonts.cairo(color: C.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              TextField(
                controller: _txIdCtrl,
                cursorColor: C.cyan,
                style: GoogleFonts.cairo(color: C.textPrimary),
                decoration: _fieldDecoration(
                  hintText: 'مثال: SC-12345678',
                  prefixIcon: const Icon(Icons.receipt, color: C.cyan),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Receipt upload
              Text('صورة الإيصال (اختياري)',
                  style:
                      GoogleFonts.cairo(color: C.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickReceipt,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: _receiptImage != null ? 200 : 100,
                  decoration: BoxDecoration(
                    color: C.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _receiptImage != null ? C.green : C.border,
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
                              const Icon(Icons.add_a_photo,
                                  color: C.textMuted, size: 32),
                              const SizedBox(height: 8),
                              Text('التقط صورة الإيصال أو اختر من المعرض',
                                  style: GoogleFonts.cairo(
                                      color: C.textMuted, fontSize: 12)),
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
                          final amount = double.tryParse(_amountCtrl.text);
                          final txId = _txIdCtrl.text.trim();
                          if (amount == null || amount <= 0) {
                            messenger.showSnackBar(SnackBar(
                                content: Text('أدخل مبلغ صحيح',
                                    style: GoogleFonts.cairo()),
                                backgroundColor: C.red));
                            return;
                          }
                          if (txId.isEmpty) {
                            messenger.showSnackBar(SnackBar(
                                content: Text('أدخل رقم المعاملة',
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
                          final notes = 'TX: $txId';
                          walletCubit.submitTopup(amount,
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
                      : Text('إرسال طلب الشحن',
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
                              'سيتم مراجعة طلبك وشحن رصيدك خلال دقائق. عمولة التطبيق 20% يتم خصمها عند كل تسجيل دخول لنادي.',
                              style: GoogleFonts.cairo(
                                  color: C.textMuted,
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
