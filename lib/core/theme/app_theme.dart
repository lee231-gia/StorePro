import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PaletteLight.primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PaletteLight.background,
      appBarTheme: AppBarTheme(
        backgroundColor: PaletteLight.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: PaletteLight.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaletteLight.surface,
        hintStyle: TextStyle(color: PaletteLight.onSurfaceDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteLight.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteLight.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteLight.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteLight.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteLight.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletteLight.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PaletteLight.primary,
          side: BorderSide(color: PaletteLight.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: PaletteLight.onSurface),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PaletteLight.onSurface),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: PaletteLight.onSurface),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: PaletteLight.onSurface),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PaletteLight.onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: PaletteLight.onSurface),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: PaletteLight.onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: PaletteLight.onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: PaletteLight.onSurfaceDim),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletteLight.onSurface),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: PaletteLight.onSurface),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: PaletteLight.onSurfaceDim),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: PaletteLight.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PaletteLight.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaletteLight.primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaletteLight.primary.withValues(alpha: 0.5);
          return PaletteLight.border;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PaletteLight.surface,
        selectedColor: PaletteLight.primaryContainer,
        labelStyle: TextStyle(color: PaletteLight.onSurface),
        secondaryLabelStyle: TextStyle(color: PaletteLight.onSurfaceDim),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: PaletteLight.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaletteLight.surface,
        indicatorColor: PaletteLight.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: PaletteLight.primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return TextStyle(color: PaletteLight.onSurfaceDim, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: PaletteLight.primary, size: 24);
          }
          return IconThemeData(color: PaletteLight.onSurfaceDim, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PaletteLight.surface,
        indicatorColor: PaletteLight.primaryContainer,
        selectedLabelTextStyle: TextStyle(color: PaletteLight.primary, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: PaletteLight.onSurfaceDim, fontSize: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: PaletteLight.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PaletteLight.onSurface,
        contentTextStyle: TextStyle(color: PaletteLight.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PaletteDark.primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PaletteDark.background,
      appBarTheme: AppBarTheme(
        backgroundColor: PaletteDark.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: PaletteDark.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaletteDark.surface,
        hintStyle: TextStyle(color: PaletteDark.onSurfaceDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteDark.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaletteDark.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletteDark.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PaletteDark.primary,
          side: BorderSide(color: PaletteDark.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: PaletteDark.onSurface),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PaletteDark.onSurface),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: PaletteDark.onSurface),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: PaletteDark.onSurface),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: PaletteDark.onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: PaletteDark.onSurface),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: PaletteDark.onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: PaletteDark.onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: PaletteDark.onSurfaceDim),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaletteDark.onSurface),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: PaletteDark.onSurface),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: PaletteDark.onSurfaceDim),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: PaletteDark.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PaletteDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaletteDark.primary;
          return PaletteDark.onSurfaceDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return PaletteDark.primary.withValues(alpha: 0.5);
          return PaletteDark.border;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PaletteDark.surface,
        selectedColor: PaletteDark.primaryContainer,
        labelStyle: TextStyle(color: PaletteDark.onSurface),
        secondaryLabelStyle: TextStyle(color: PaletteDark.onSurfaceDim),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: PaletteDark.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PaletteDark.surface,
        indicatorColor: PaletteDark.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: PaletteDark.primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return TextStyle(color: PaletteDark.onSurfaceDim, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: PaletteDark.primary, size: 24);
          }
          return IconThemeData(color: PaletteDark.onSurfaceDim, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PaletteDark.surface,
        indicatorColor: PaletteDark.primaryContainer,
        selectedLabelTextStyle: TextStyle(color: PaletteDark.primary, fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: PaletteDark.onSurfaceDim, fontSize: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: PaletteDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PaletteDark.onSurface,
        contentTextStyle: TextStyle(color: PaletteDark.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
