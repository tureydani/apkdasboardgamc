import 'package:flutter/material.dart';

/// Paleta institucional SIRAD: blanco + azul navy, acorde al logo.
/// Azul (#2563EB): botones, selección, elementos activos.
/// Navy (#0F172A / #172554): navegación, encabezados, acentos estructurales.
/// Blanco: contenido y tarjetas (fondo de la app).
/// Rojo/Verde/Ámbar: estado de incidentes (crítico / resuelto-disponible / pendiente).
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color backgroundTertiary = Color(0xFFF1F5F9);

  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8FAFC);
  static const Color surfaceTertiary = Color(0xFFF1F5F9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color primaryContainerDark = Color(0xFFBFDBFE);

  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0284C7);
  static const Color secondaryContainer = Color(0xFFE0F2FE);
  static const Color secondaryContainerDark = Color(0xFFBAE6FD);

  static const Color accent = Color(0xFF172554);
  static const Color accentLight = Color(0xFF1E3A8A);
  static const Color accentDark = Color(0xFF0F172A);
  static const Color accentContainer = Color(0xFFE2E8F0);

  static const Color accentSoft = Color(0xFF64748B);
  static const Color accentSoftLight = Color(0xFF94A3B8);
  static const Color accentSoftDark = Color(0xFF334155);
  static const Color accentSoftContainer = Color(0xFFF1F5F9);
  static const Color accentSoftContainerDark = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF0F172A);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color borderPrimary = Color(0xFFE2E8F0);
  static const Color borderSecondary = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF2563EB);

  static const Color shadowColor = Color(0x1A0F172A);
  static const Color overlayColor = Color(0xB30F172A);

  static const Color urgentRed = Color(0xFFEF4444);
  static const Color urgentRedLight = Color(0xFFF87171);
  static const Color urgentRedDark = Color(0xFFB91C1C);
  static const Color urgentRedContainer = Color(0xFFFEE2E2);

  static const Color moderateOrange = Color(0xFFF59E0B);
  static const Color moderateOrangeLight = Color(0xFFFBBF24);
  static const Color moderateOrangeDark = Color(0xFFB45309);
  static const Color moderateOrangeContainer = Color(0xFFFEF3C7);

  static const Color resolvedGreen = Color(0xFF16A34A);
  static const Color resolvedGreenLight = Color(0xFF4ADE80);
  static const Color resolvedGreenDark = Color(0xFF15803D);
  static const Color resolvedGreenContainer = Color(0xFFDCFCE7);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  static const Color divider = Color(0xFFE2E8F0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ---- Tema oscuro (opcional, activable desde "Más") ----
  // Mismo navy institucional del logo, ahora como fondo en vez de acento.
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF243044);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);

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
    colors: [accentDark, accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
