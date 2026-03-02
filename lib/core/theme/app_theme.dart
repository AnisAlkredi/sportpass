import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return _themeFromBase(base, Brightness.dark);
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return _themeFromBase(base, Brightness.light);
  }

  static ThemeData _themeFromBase(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? C.surface : const Color(0xFFFFFFFF);
    final surfaceAlt = isDark ? C.surfaceAlt : const Color(0xFFF3F6FA);
    final onSurface = isDark ? C.textPrimary : const Color(0xFF10233D);
    final muted = isDark ? C.textMuted : const Color(0xFF60748D);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      brightness: brightness,
      primaryColor: C.cyan,
      scaffoldBackgroundColor: isDark ? C.bg : const Color(0xFFF5F7FA),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: C.cyan,
        onPrimary: C.navy,
        secondary: C.green,
        onSecondary: Colors.white,
        error: C.red,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.4),
        bodySmall: textTheme.bodySmall?.copyWith(height: 1.4),
        labelLarge: textTheme.labelLarge?.copyWith(height: 1.35),
        labelMedium: textTheme.labelMedium?.copyWith(height: 1.35),
        titleMedium: textTheme.titleMedium?.copyWith(height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.cairo(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: isDark ? C.card : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: C.border.withValues(alpha: isDark ? 0.55 : 0.35)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.cyan,
          foregroundColor: C.navy,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.cyan,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: C.cyan.withValues(alpha: 0.45), width: 1.5),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.cairo(color: muted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: C.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: C.red),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: C.cyan.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
              color: C.cyan,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.cairo(color: muted, fontSize: 11.5, height: 1.35);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: C.cyan, size: 24);
          }
          return IconThemeData(color: muted, size: 24);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: GoogleFonts.cairo(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
