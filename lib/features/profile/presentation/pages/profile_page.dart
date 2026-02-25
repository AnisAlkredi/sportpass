import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/glass_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;
  final _nameCtrl = TextEditingController();
  String? _role;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      return;
    }
    try {
      final p =
          await sb.from('profiles').select().eq('user_id', uid).maybeSingle();
      setState(() {
        _profile = p;
        _nameCtrl.text = p?['name'] ?? '';
        _role = p?['role'] ?? 'athlete';
        _email = sb.auth.currentUser?.email;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().length < 2) {
      return;
    }
    setState(() => _saving = true);
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    try {
      await sb
          .from('profiles')
          .update({'name': _nameCtrl.text.trim()}).eq('user_id', uid!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trd('تم تحديث الاسم', 'Name updated'),
                style: GoogleFonts.cairo()),
            backgroundColor: C.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trd('خطأ: $e', 'Error: $e'),
                style: GoogleFonts.cairo()),
            backgroundColor: C.red,
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(
          context.trd('تسجيل الخروج', 'Logout'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: C.textPrimary,
          ),
        ),
        content: Text(
          context.trd(
              'هل تريد تسجيل الخروج من حسابك؟', 'Do you want to sign out?'),
          style: GoogleFonts.cairo(color: C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.trd('إلغاء', 'Cancel'),
                style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: C.red),
            child: Text(context.trd('تسجيل الخروج', 'Logout'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  void _setLanguage(String? languageCode) {
    final appState = SportPassApp.maybeOf(context);
    if (appState == null) {
      return;
    }
    appState.setLocale(languageCode == null ? null : Locale(languageCode));
  }

  void _setThemeMode(ThemeMode mode) {
    final appState = SportPassApp.maybeOf(context);
    if (appState == null) {
      return;
    }
    appState.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _role == 'admin'
        ? C.purple
        : _role == 'gym_owner' || _role == 'gym_owner_pending'
            ? C.gold
            : C.cyan;
    final roleLabel = _role == 'admin'
        ? context.trd('مدير', 'Admin')
        : _role == 'gym_owner'
            ? context.trd('صاحب نادي', 'Gym owner')
            : _role == 'gym_owner_pending'
                ? context.trd(
                    'صاحب نادي (بانتظار الموافقة)', 'Gym owner (pending)')
                : context.trd('رياضي', 'Athlete');

    final appState = SportPassApp.maybeOf(context);
    final selectedLocale = appState?.currentLocale;
    final selectedTheme = appState?.currentThemeMode ?? ThemeMode.system;
    final langCode = selectedLocale?.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.trd('الملف الشخصي', 'Profile'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.cyan))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              roleColor,
                              roleColor.withValues(alpha: 0.5)
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: roleColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (_profile?['name'] ?? '?')[0].toUpperCase(),
                            style: GoogleFonts.cairo(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel,
                          style: GoogleFonts.cairo(
                              color: roleColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 28),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trd('الاسم', 'Name'),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameCtrl,
                        style: GoogleFonts.cairo(
                            color: C.textPrimary, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: C.cyan),
                          ),
                          prefixIcon:
                              const Icon(Icons.person, color: C.textMuted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveName,
                          style:
                              ElevatedButton.styleFrom(backgroundColor: C.cyan),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.trd('حفظ', 'Save'),
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: C.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.trd('البريد الإلكتروني', 'Email'),
                              style: GoogleFonts.cairo(
                                  color: C.textMuted, fontSize: 12),
                            ),
                            Text(
                              _email ?? _profile?['phone'] ?? '-',
                              style: GoogleFonts.cairo(
                                color: C.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: C.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.trd('للقراءة فقط', 'Read only'),
                          style: GoogleFonts.cairo(
                              color: C.textMuted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trd('اللغة', 'Language'),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _choiceButton(
                              label:
                                  context.trd('تلقائي (لغة الجهاز)', 'System'),
                              selected: selectedLocale == null,
                              onTap: () => _setLanguage(null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _choiceButton(
                              label: context.trd('العربية', 'Arabic'),
                              selected: langCode == 'ar',
                              onTap: () => _setLanguage('ar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _choiceButton(
                              label: 'English',
                              selected: langCode == 'en',
                              onTap: () => _setLanguage('en'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trd('المظهر', 'Theme'),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _choiceButton(
                              label: context.trd('تلقائي', 'System'),
                              selected: selectedTheme == ThemeMode.system,
                              onTap: () => _setThemeMode(ThemeMode.system),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _choiceButton(
                              label: context.trd('فاتح', 'Light'),
                              selected: selectedTheme == ThemeMode.light,
                              onTap: () => _setThemeMode(ThemeMode.light),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _choiceButton(
                              label: context.trd('داكن', 'Dark'),
                              selected: selectedTheme == ThemeMode.dark,
                              onTap: () => _setThemeMode(ThemeMode.dark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: C.red),
                    label: Text(
                      context.trd('تسجيل الخروج', 'Logout'),
                      style: GoogleFonts.cairo(
                        color: C.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: C.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bgColor = Theme.of(context).colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? C.cyan.withValues(alpha: 0.16) : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? C.cyan : C.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: selected ? C.cyan : C.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
