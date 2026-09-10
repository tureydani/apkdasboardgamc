import 'package:flutter/material.dart';

/// Paleta compartida con arconde-gamc para mantener consistencia visual
/// entre ambas apps (sosapk es un complemento de arconde-gamc).
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F0F8);
  static const Color backgroundTertiary = Color(0xFFEDE6F3);

  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8F4FC);
  static const Color surfaceTertiary = Color(0xFFF0EAF5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF9B6CD3);
  static const Color primaryLight = Color(0xFFB590E0);
  static const Color primaryDark = Color(0xFF7A4BB8);
  static const Color primaryContainer = Color(0xFFF0E8F7);
  static const Color primaryContainerDark = Color(0xFFE5D9F0);

  static const Color secondary = Color(0xFF4BC1EB);
  static const Color secondaryLight = Color(0xFF7AD8F0);
  static const Color secondaryDark = Color(0xFF2AA8D1);
  static const Color secondaryContainer = Color(0xFFE0F6FC);
  static const Color secondaryContainerDark = Color(0xFFCCEDF5);

  static const Color accent = Color(0xFF6844A3);
  static const Color accentLight = Color(0xFF855FC0);
  static const Color accentDark = Color(0xFF4D307A);
  static const Color accentContainer = Color(0xFFEDE6F7);

  static const Color accentSoft = Color(0xFFC98EB3);
  static const Color accentSoftLight = Color(0xFFD8AAC5);
  static const Color accentSoftDark = Color(0xFFB5719A);
  static const Color accentSoftContainer = Color(0xFFFCEFF5);
  static const Color accentSoftContainerDark = Color(0xFFF5E0EB);

  static const Color textPrimary = Color(0xFF1D1E24);
  static const Color textSecondary = Color(0xFF5A5C6A);
  static const Color textTertiary = Color(0xFF8A8C97);
  static const Color textDisabled = Color(0xFFB8B9C0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF1D1E24);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color borderPrimary = Color(0xFFE5E0EB);
  static const Color borderSecondary = Color(0xFFD8D2E0);
  static const Color borderFocus = Color(0xFF9B6CD3);

  static const Color shadowColor = Color(0x1A1D1E24);
  static const Color overlayColor = Color(0xB31D1E24);

  static const Color urgentRed = Color(0xFFE1443F);
  static const Color urgentRedLight = Color(0xFFEF7B77);
  static const Color urgentRedDark = Color(0xFFB93330);
  static const Color urgentRedContainer = Color(0xFFFCEBEA);

  static const Color moderateOrange = Color(0xFFE68A2E);
  static const Color moderateOrangeLight = Color(0xFFF0AE6C);
  static const Color moderateOrangeDark = Color(0xFFBD6E1F);
  static const Color moderateOrangeContainer = Color(0xFFFBEEE0);

  static const Color resolvedGreen = Color(0xFF2AA476);
  static const Color resolvedGreenLight = Color(0xFF63C79E);
  static const Color resolvedGreenDark = Color(0xFF1F7E5A);
  static const Color resolvedGreenContainer = Color(0xFFE3F5EC);

  static const Color success = Color(0xFF2AA476);
  static const Color warning = Color(0xFFE68A2E);
  static const Color error = Color(0xFFE1443F);
  static const Color info = Color(0xFF4BC1EB);

  static const Color divider = Color(0xFFE5E0EB);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientReverse = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentSoftGradient = LinearGradient(
    colors: [accentSoft, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient urgentGradient = LinearGradient(
    colors: [urgentRed, urgentRedLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient moderateGradient = LinearGradient(
    colors: [moderateOrange, moderateOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient resolvedGradient = LinearGradient(
    colors: [resolvedGreen, resolvedGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfacePrimary, surfaceSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, accent, accentSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
