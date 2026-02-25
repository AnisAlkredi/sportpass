import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0; // 0=welcome, 1=name, 2=role
  String? _selectedRole;
  final _nameCtrl = TextEditingController();
  final _gymNameCtrl = TextEditingController();
  final _gymCityCtrl = TextEditingController();
  final _gymAddressCtrl = TextEditingController();
  final _branchesCtrl = TextEditingController(text: '1');
  final Set<String> _selectedGymCategories = {'gym'};
  String _tr(String ar, String en) => context.trd(ar, en);

  static const List<String> _gymCategories = [
    'gym',
    'women_only',
    'pool',
    'martial_arts',
    'studio',
  ];

  String _gymCategoryLabel(String key) => switch (key) {
        'gym' => _tr('نادي رياضي', 'Gym'),
        'women_only' => _tr('نادي نسائي', 'Women only gym'),
        'pool' => _tr('مسبح', 'Pool'),
        'martial_arts' => _tr('فنون قتالية', 'Martial arts'),
        'studio' => _tr('استوديو لياقة', 'Fitness studio'),
        _ => key,
      };

  Future<void> _complete() async {
    if (_nameCtrl.text.trim().length < 2 || _selectedRole == null) return;
    Map<String, dynamic>? ownerDetails;
    if (_selectedRole == 'gym_owner') {
      final branches = int.tryParse(_branchesCtrl.text.trim()) ?? 1;
      ownerDetails = {
        'gym_name': _gymNameCtrl.text.trim(),
        'gym_city': _gymCityCtrl.text.trim(),
        'gym_address': _gymAddressCtrl.text.trim(),
        'branches_count': branches < 1 ? 1 : branches,
        'gym_category': _selectedGymCategories.join(','),
      };
    }
    context.read<AuthCubit>().submitRoleSelection(
          name: _nameCtrl.text.trim(),
          selectedRole: _selectedRole!,
          gymOwnerDetails: ownerDetails,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRouter.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.cairo()),
              backgroundColor: C.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final saving = state is AuthLoading;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress
                  Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i <= _step
                                ? C.cyan
                                : Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0
                          ? _buildWelcome()
                          : _step == 1
                              ? _buildNameStep()
                              : _buildRoleStep(),
                    ),
                  ),

                  // Bottom button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (saving || !_canProceed()) ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.cyan,
                        disabledBackgroundColor: C.surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _step < 2
                                  ? _tr('متابعة', 'Continue')
                                  : _selectedRole == 'gym_owner'
                                      ? _tr('إرسال طلب المراجعة',
                                          'Submit for review')
                                      : _tr('حفظ الدور', 'Save role'),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canProceed() {
    if (_step == 0) return true;
    if (_step == 1) return _nameCtrl.text.trim().length >= 2;
    if (_step == 2) {
      if (_selectedRole == null) {
        return false;
      }
      if (_selectedRole != 'gym_owner') {
        return true;
      }
      final branchCount = int.tryParse(_branchesCtrl.text.trim()) ?? 0;
      return _gymNameCtrl.text.trim().length >= 2 &&
          _gymCityCtrl.text.trim().length >= 2 &&
          _gymAddressCtrl.text.trim().length >= 5 &&
          branchCount >= 1 &&
          _selectedGymCategories.isNotEmpty;
    }
    return false;
  }

  void _onNext() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _complete();
    }
  }

  Widget _buildWelcome() {
    return Column(
      key: const ValueKey('welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: C.cyanGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: C.cyan.withValues(alpha: 0.3), blurRadius: 30)
            ],
          ),
          child: const Icon(Icons.sports_gymnastics,
              size: 64, color: Colors.white),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text(_tr('مرحباً بك في SportPass', 'Welcome to SportPass'),
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _onSurfaceColor(context)))
            .animate()
            .fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          _tr(
            'شبكة الأندية الرياضية الأولى في سوريا\nادخل أي نادي — امسح QR — تمرّن',
            'The first smart fitness network in Syria\nEnter any gym — scan QR — train',
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: _secondaryColor(context),
            fontSize: 15,
            height: 1.6,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _featurePill(Icons.qr_code_scanner, _tr('امسح QR', 'Scan QR')),
            const SizedBox(width: 12),
            _featurePill(Icons.account_balance_wallet,
                _tr('محفظة رقمية', 'Digital wallet')),
            const SizedBox(width: 12),
            _featurePill(
                Icons.fitness_center, _tr('أندية متعددة', 'Multiple gyms')),
          ],
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: C.cyan),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.cairo(
                  color: _secondaryColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_outline, size: 64, color: C.cyan)
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(_tr('ما اسمك؟', 'What is your name?'),
                style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _onSurfaceColor(context)))
            .animate()
            .fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
                _tr('سيظهر اسمك للمراكز الرياضية عند تسجيل الدخول',
                    'Your name will appear to gyms during check-in'),
                style: GoogleFonts.cairo(
                    color: _secondaryColor(context), fontSize: 14))
            .animate()
            .fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        TextField(
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: _onSurfaceColor(context),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: _tr('اكتب اسمك هنا', 'Write your name here'),
            hintStyle:
                GoogleFonts.cairo(color: _mutedColor(context), fontSize: 18),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: C.cyan, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildRoleStep() {
    return SingleChildScrollView(
      key: const ValueKey('role'),
      child: Column(
        children: [
          Text(_tr('ما هو دورك؟', 'What is your role?'),
                  style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _onSurfaceColor(context)))
              .animate()
              .fadeIn(),
          const SizedBox(height: 8),
          Text(
            _selectedRole == 'gym_owner'
                ? _tr(
                    'أدخل بيانات ناديك لتصل إلى الإدارة للمراجعة',
                    'Enter your gym details to send them for admin review',
                  )
                : _tr('يمكنك تغيير هذا لاحقاً', 'You can change this later'),
            style: GoogleFonts.cairo(
                color: _secondaryColor(context), fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          _roleCard(
            'athlete',
            Icons.sports_gymnastics,
            _tr('رياضي', 'Athlete'),
            _tr('أريد التمرن في مراكز رياضية متعددة',
                'I want to train in multiple gyms'),
            C.cyan,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          const SizedBox(height: 14),
          _roleCard(
            'gym_owner',
            Icons.store,
            _tr('صاحب نادي', 'Gym owner'),
            _tr('أمتلك ناديًا وسأنتظر موافقة الإدارة قبل التفعيل',
                'I own a gym and will wait for admin approval before activation'),
            C.gold,
          ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.1),
          if (_selectedRole == 'gym_owner') ...[
            const SizedBox(height: 16),
            _buildGymOwnerDetailsCard()
                .animate()
                .fadeIn(delay: 380.ms)
                .slideY(begin: 0.06),
          ],
        ],
      ),
    );
  }

  Widget _buildGymOwnerDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('بيانات النادي للموافقة', 'Gym details for approval'),
            style: GoogleFonts.cairo(
              color: _onSurfaceColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _gymNameCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
            decoration: InputDecoration(
              labelText: _tr('اسم النادي', 'Gym name'),
              hintText: _tr('مثال: نادي المالكي الرياضي',
                  'Example: Al-Malki Sports Club'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gymCityCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
                  decoration: InputDecoration(
                    labelText: _tr('المدينة', 'City'),
                    hintText: _tr('دمشق', 'Damascus'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _branchesCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
                  decoration: InputDecoration(
                    labelText:
                        _tr('عدد الفروع المبدئي', 'Initial branches count'),
                    hintText: '1',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _gymAddressCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.cairo(color: _onSurfaceColor(context)),
            decoration: InputDecoration(
              labelText: _tr('العنوان', 'Address'),
              hintText: _tr('المنطقة - الشارع', 'Area - Street'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _tr('نوع النشاط (يمكن اختيار أكثر من نوع)',
                'Activity type (you can select more than one)'),
            style: GoogleFonts.cairo(
              color: _secondaryColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gymCategories.map((categoryKey) {
              final selected = _selectedGymCategories.contains(categoryKey);
              return FilterChip(
                label: Text(
                  _gymCategoryLabel(categoryKey),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedGymCategories.add(categoryKey);
                      return;
                    }
                    if (_selectedGymCategories.length > 1) {
                      _selectedGymCategories.remove(categoryKey);
                    }
                  });
                },
                selectedColor: C.gold.withValues(alpha: 0.24),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.8),
                labelStyle: TextStyle(
                  color: selected ? C.gold : _secondaryColor(context),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(
      String role, IconData icon, String title, String subtitle, Color color) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : C.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.15), blurRadius: 20)
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _onSurfaceColor(context))),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          color: _secondaryColor(context), fontSize: 13)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                    color: selected
                        ? color
                        : _mutedColor(context).withValues(alpha: 0.3),
                    width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gymNameCtrl.dispose();
    _gymCityCtrl.dispose();
    _gymAddressCtrl.dispose();
    _branchesCtrl.dispose();
    super.dispose();
  }

  Color _onSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  Color _secondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);

  Color _mutedColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
}
