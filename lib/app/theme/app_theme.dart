import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textOnPrimary,
        tertiaryContainer: AppColors.accentContainer,
        onTertiaryContainer: AppColors.accentDark,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        errorContainer: AppColors.urgentRedContainer,
        onErrorContainer: AppColors.urgentRedDark,
        surface: AppColors.surfacePrimary,
        onSurface: AppColors.textOnSurface,
        surfaceContainerHighest: AppColors.surfaceTertiary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderPrimary,
        outlineVariant: AppColors.borderSecondary,
        shadow: AppColors.shadowColor,
        scrim: AppColors.overlayColor,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.surfacePrimary,
        inversePrimary: AppColors.primaryLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surfacePrimary,
      dividerColor: AppColors.divider,
      shadowColor: AppColors.shadowColor,
      focusColor: AppColors.borderFocus,
      hoverColor: AppColors.surfaceSecondary,
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationNone,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        toolbarHeight: AppSpacing.appBarHeight,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconMd,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSpacing.iconMd,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationSm,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600);
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: AppSpacing.iconMd);
          }
          return const IconThemeData(color: AppColors.textTertiary, size: AppSpacing.iconMd);
        }),
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimary,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppSpacing.elevationSm,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppSpacing.elevationSm,
        focusElevation: AppSpacing.elevationMd,
        hoverElevation: AppSpacing.elevationMd,
        highlightElevation: AppSpacing.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
        extendedIconLabelSpacing: AppSpacing.sm,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationSm,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          side: const BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationLg,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
        alignment: Alignment.center,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationLg,
        shadowColor: AppColors.shadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.borderRadiusXl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnPrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          side: const BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
        side: const BorderSide(color: AppColors.borderPrimary, width: 1),
        brightness: Brightness.light,
        elevation: AppSpacing.elevationNone,
        pressElevation: AppSpacing.elevationSm,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: AppColors.borderSecondary, width: 1),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
        floatingLabelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        helperStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.primary,
        disabledColor: AppColors.surfaceTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        textTheme: ButtonTextTheme.primary,
        height: 48,
        minWidth: 88,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.surfaceTertiary,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: AppSpacing.elevationSm,
          shadowColor: AppColors.shadowColor,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.surfaceTertiary,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: AppSpacing.elevationSm,
          shadowColor: AppColors.shadowColor,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(64, 40),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.transparent,
          hoverColor: AppColors.surfaceSecondary,
          focusColor: AppColors.surfaceSecondary,
          highlightColor: AppColors.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(AppSpacing.sm),
          iconSize: AppSpacing.iconMd,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfacePrimary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.borderSecondary;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.borderPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.borderSecondary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.borderSecondary,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.1),
        valueIndicatorColor: AppColors.primaryDark,
        valueIndicatorTextStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textOnPrimary),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderPrimary,
        circularTrackColor: AppColors.borderPrimary,
        refreshBackgroundColor: AppColors.surfacePrimary,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppSpacing.md,
        indent: 0,
        endIndent: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmallSecondary,
        iconColor: AppColors.textTertiary,
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.primaryDark,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        dense: false,
        visualDensity: VisualDensity.standard,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.surfacePrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        verticalOffset: 24,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.surfacePrimary),
        actionTextColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppSpacing.elevationMd,
        showCloseIcon: true,
        closeIconColor: AppColors.surfaceTertiary,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
