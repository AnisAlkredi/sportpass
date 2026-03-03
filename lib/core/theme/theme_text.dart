import 'package:flutter/material.dart';

import 'colors.dart';

Color appTextPrimary(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return C.textPrimary;
  }
  return const Color(0xFF10233D);
}

Color appTextSecondary(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return C.textSecondary;
  }
  return const Color(0xFF4E6580);
}

Color appTextMuted(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return C.textMuted;
  }
  return const Color(0xFF6D8199);
}
