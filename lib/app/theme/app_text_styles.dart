import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.libreBaskerville(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.14,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.libreBaskerville(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.18,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.libreBaskerville(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => GoogleFonts.libreBaskerville(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.26,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.libreBaskerville(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.libreBaskerville(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.libreBaskerville(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.lindenHill(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.lindenHill(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelLarge => GoogleFonts.lindenHill(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.lindenHill(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.lindenHill(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.ovo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.55,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.ovo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.ovo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayLargeOnPrimary => displayLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get displayMediumOnPrimary => displayMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get displaySmallOnPrimary => displaySmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineLargeOnPrimary => headlineLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineMediumOnPrimary => headlineMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineSmallOnPrimary => headlineSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleLargeOnPrimary => titleLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleMediumOnPrimary => titleMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleSmallOnPrimary => titleSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelLargeOnPrimary => labelLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelMediumOnPrimary => labelMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelSmallOnPrimary => labelSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodyLargeOnPrimary => bodyLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodyMediumOnPrimary => bodyMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodySmallOnPrimary => bodySmall.copyWith(color: AppColors.textOnPrimary);

  static TextStyle get displayLargeSecondary => displayLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get displayMediumSecondary => displayMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get displaySmallSecondary => displaySmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineLargeSecondary => headlineLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineMediumSecondary => headlineMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineSmallSecondary => headlineSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleLargeSecondary => titleLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleMediumSecondary => titleMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleSmallSecondary => titleSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelLargeSecondary => labelLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelMediumSecondary => labelMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelSmallSecondary => labelSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodyLargeSecondary => bodyLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodyMediumSecondary => bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodySmallSecondary => bodySmall.copyWith(color: AppColors.textSecondary);

  static TextStyle get displayLargeTertiary => displayLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get displayMediumTertiary => displayMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get displaySmallTertiary => displaySmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineLargeTertiary => headlineLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineMediumTertiary => headlineMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineSmallTertiary => headlineSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleLargeTertiary => titleLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleMediumTertiary => titleMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleSmallTertiary => titleSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelLargeTertiary => labelLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelMediumTertiary => labelMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelSmallTertiary => labelSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodyLargeTertiary => bodyLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodyMediumTertiary => bodyMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodySmallTertiary => bodySmall.copyWith(color: AppColors.textTertiary);
}
