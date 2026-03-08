import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// System now stores and displays the new Syrian Pound units directly.
/// Keep this as a constant for one-place control if policy changes.
const double kSypRedenominationFactor = 1.0;

double sypStorageToDisplay(num storageAmount) =>
    storageAmount / kSypRedenominationFactor;

double sypDisplayToStorage(num displayAmount) =>
    displayAmount * kSypRedenominationFactor;

double? parseSypDisplayInput(String raw) {
  final normalized = raw.replaceAll(',', '').trim();
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String normalizeLegacySypText(String input) {
  final pattern = RegExp(r'(\d[\d,]*(?:\.\d+)?)\s*(ل\.س|SYP)');
  return input.replaceAllMapped(pattern, (match) {
    final raw = (match.group(1) ?? '').replaceAll(',', '');
    final unit = match.group(2) ?? 'ل.س';
    final legacy = double.tryParse(raw);
    if (legacy == null) {
      return match.group(0) ?? input;
    }
    final display = sypStorageToDisplay(legacy);
    final formatted = formatAmount(display, valueIsStorage: false);
    return '$formatted $unit';
  });
}

/// Formats numbers with separators.
/// If [valueIsStorage] is true, value is converted from storage to display.
String formatAmount(
  num amount, {
  bool valueIsStorage = true,
}) {
  final value = valueIsStorage ? sypStorageToDisplay(amount) : amount;
  return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

String formatSYP(num amount) {
  return '${formatAmount(amount)} ل.س جديدة';
}

String currencyLabel(BuildContext context) {
  return AppLocalizations.of(context).isEnglish ? 'SYP (new)' : 'ل.س جديدة';
}

String formatCurrency(
  BuildContext context,
  num amount, {
  bool includeCurrency = true,
  bool valueIsStorage = true,
}) {
  final value = formatAmount(
    amount,
    valueIsStorage: valueIsStorage,
  );
  if (!includeCurrency) {
    return value;
  }
  return '$value ${currencyLabel(context)}';
}

/// Shimmer loading placeholder
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: C.surfaceAlt,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Gradient text
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

/// Animated counter for wallet balance
class AnimatedBalance extends StatelessWidget {
  final double balance;
  final TextStyle? style;
  final Duration duration;
  final bool includeCurrency;

  const AnimatedBalance({
    super.key,
    required this.balance,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.includeCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: balance),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final formatted = includeCurrency
            ? formatCurrency(context, value)
            : formatCurrency(context, value, includeCurrency: false);
        return Text(
          formatted,
          style: style ??
              GoogleFonts.cairo(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: C.textPrimary,
              ),
        );
      },
    );
  }
}
