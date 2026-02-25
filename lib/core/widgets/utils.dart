import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// Formats Syrian Pounds with proper formatting
String formatAmount(num amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

String formatSYP(num amount) {
  return '${formatAmount(amount)} ل.س';
}

String currencyLabel(BuildContext context) {
  return AppLocalizations.of(context).isEnglish ? 'SYP' : 'ل.س';
}

String formatCurrency(
  BuildContext context,
  num amount, {
  bool includeCurrency = true,
}) {
  final value = formatAmount(amount);
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
