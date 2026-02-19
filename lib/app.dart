import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/partners/presentation/cubit/partners_cubit.dart';
import 'features/checkin/presentation/cubit/checkin_cubit.dart';
import 'features/activity/presentation/cubit/activity_cubit.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';
import 'features/wallet/presentation/cubit/wallet_cubit.dart';

abstract class SportPassAppController {
  Locale? get currentLocale;
  ThemeMode get currentThemeMode;
  void setLocale(Locale? locale);
  void setThemeMode(ThemeMode mode);
}

class SportPassApp extends StatefulWidget {
  const SportPassApp({super.key});

  static SportPassAppController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_SportPassAppState>();
  }

  @override
  State<SportPassApp> createState() => _SportPassAppState();
}

class _SportPassAppState extends State<SportPassApp>
    implements SportPassAppController {
  static const _localePrefKey = 'app_locale_override';
  static const _themePrefKey = 'app_theme_override';
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    final theme = prefs.getString(_themePrefKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _locale = (code == null || code == 'system') ? null : Locale(code);
      _themeMode = switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  @override
  Locale? get currentLocale => _locale;

  @override
  ThemeMode get currentThemeMode => _themeMode;

  @override
  void setLocale(Locale? locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_localePrefKey, locale?.languageCode ?? 'system');
    });
  }

  @override
  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    SharedPreferences.getInstance().then((prefs) {
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      prefs.setString(_themePrefKey, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()..checkAuth()),
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()),
        BlocProvider<PartnersCubit>(create: (_) => sl<PartnersCubit>()),
        BlocProvider<CheckinCubit>(create: (_) => sl<CheckinCubit>()),
        BlocProvider<ActivityCubit>(create: (_) => sl<ActivityCubit>()),
        BlocProvider<AdminCubit>(create: (_) => sl<AdminCubit>()),
        BlocProvider<WalletCubit>(create: (_) => sl<WalletCubit>()),
      ],
      child: MaterialApp.router(
        title: 'SportPass',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        locale: _locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: AppRouter.router,
      ),
    );
  }
}
