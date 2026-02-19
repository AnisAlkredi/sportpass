import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/glass_card.dart';
import '../cubit/auth_cubit.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  const OtpPage({super.key, required this.phoneNumber});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) context.go(AppRouter.home);
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: C.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.lock_outline, size: 64, color: C.cyan)
                    .animate()
                    .fadeIn()
                    .scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 24),
                Text('رمز التحقق',
                        style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: C.textPrimary))
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'تم إرسال رمز التحقق إلى ${widget.phoneNumber}',
                  style:
                      GoogleFonts.cairo(fontSize: 14, color: C.textSecondary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: C.textPrimary,
                            letterSpacing: 8),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: GoogleFonts.cairo(
                              color: C.textMuted,
                              fontSize: 28,
                              letterSpacing: 8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (ctx, state) {
                          final loading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      context.read<AuthCubit>().verifyOtp(
                                          widget.phoneNumber,
                                          _otpCtrl.text.trim());
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text('تحقق',
                                      style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
