import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _signupMode = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (ctx, state) {
        if (state is AuthRoleSelectionRequired) {
          context.go(AppRouter.onboarding);
        } else if (state is AuthAuthenticated) {
          context.go(AppRouter.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: C.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: C.cyanGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: C.cyan.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sports_gymnastics,
                      size: 46, color: Colors.white),
                ).animate().fadeIn(duration: 500.ms).scale(),
                const SizedBox(height: 20),
                Text(
                  'SportPass',
                  style: GoogleFonts.cairo(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: _onSurfaceColor(context),
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 6),
                Text(
                  _signupMode
                      ? context.trd('أنشئ حسابك للبدء', 'Create your account')
                      : context.trd(
                          'سجل الدخول إلى حسابك', 'Sign in to your account'),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: _secondaryColor(context),
                  ),
                ).animate().fadeIn(delay: 220.ms),
                const SizedBox(height: 18),
                _modeSwitch(),
                const SizedBox(height: 22),
                _formCard(),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          _modeButton(
            label: context.trd('تسجيل الدخول', 'Sign in'),
            selected: !_signupMode,
            onTap: () => setState(() => _signupMode = false),
          ),
          _modeButton(
            label: context.trd('إنشاء حساب', 'Sign up'),
            selected: _signupMode,
            onTap: () => setState(() => _signupMode = true),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? C.cyanGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: selected ? C.navy : _secondaryColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_signupMode) ...[
            _fieldLabel(context.trd('الاسم', 'Name')),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
              decoration: InputDecoration(
                hintText: context.trd('اسمك الكامل', 'Your full name'),
                prefixIcon: const Icon(Icons.badge_outlined, color: C.cyan),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _fieldLabel(context.trd('البريد الإلكتروني', 'Email')),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
            decoration: InputDecoration(
              hintText: context.trd(
                'مثال: user@mail.com',
                'Example: user@mail.com',
              ),
              prefixIcon: const Icon(Icons.email_outlined, color: C.cyan),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel(context.trd('كلمة المرور', 'Password')),
          const SizedBox(height: 8),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: C.cyan),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _mutedColor(context),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (!_signupMode) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  context.trd('نسيت كلمة المرور؟', 'Forgot password?'),
                  style: GoogleFonts.cairo(
                    color: C.cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          if (_signupMode) ...[
            const SizedBox(height: 8),
            Text(
              context.trd(
                'سيتم تحديد دورك بعد أول دخول (رياضي أو صاحب نادي).',
                'You will choose your role after first login (Athlete or Gym Owner).',
              ),
              style: GoogleFonts.cairo(
                color: _mutedColor(context),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 22),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (ctx, state) {
              final loading = state is AuthLoading;
              return SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _signupMode
                              ? context.trd('إنشاء الحساب', 'Create account')
                              : context.trd('تسجيل الدخول', 'Sign in'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.06);
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        color: _secondaryColor(context),
        fontSize: 14,
      ),
    );
  }

  Color _onSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  Color _secondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);

  Color _mutedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);

  void _submit() {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.trd('أدخل بريد إلكتروني صالح', 'Enter a valid email'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: C.red,
        ),
      );
      return;
    }

    if (_signupMode) {
      final name = _nameCtrl.text.trim();
      if (name.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trd('الاسم قصير جداً', 'Name is too short'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: C.red,
          ),
        );
        return;
      }
      context.read<AuthCubit>().signUpWithPassword(
            email: email,
            password: password,
            name: name,
          );
      return;
    }

    context.read<AuthCubit>().loginWithPassword(email, password);
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetCtrl = TextEditingController(text: _emailCtrl.text.trim());
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            context.trd('إعادة تعيين كلمة المرور', 'Reset password'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: resetCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              labelText: context.trd('البريد الإلكتروني', 'Email'),
              hintText: 'name@mail.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text(context.trd('إلغاء', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = resetCtrl.text.trim();
                      if (!_isValidEmail(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.trd(
                                'أدخل بريد إلكتروني صالح',
                                'Enter a valid email',
                              ),
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: C.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => sending = true);
                      try {
                        await context
                            .read<AuthCubit>()
                            .sendPasswordResetEmail(email);
                        if (!mounted) return;
                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.trd(
                                'تم إرسال رابط إعادة التعيين إلى بريدك',
                                'Password reset link was sent to your email',
                              ),
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: C.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.trd(
                                'فشل إرسال رابط إعادة التعيين',
                                'Failed to send password reset link',
                              ),
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: C.red,
                          ),
                        );
                        setDialogState(() => sending = false);
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.trd('إرسال', 'Send')),
            ),
          ],
        ),
      ),
    );
    resetCtrl.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value.trim());
  }
}
