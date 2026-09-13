import 'package:flutter/material.dart';

/// ============================================================
/// SMART FARM VISUAL DESIGN SYSTEM
/// Dark ag-tech theme used across all Shamba Smart screens.
/// Centralizing colors here means the whole app can be re-skinned
/// by editing only this file.
/// ============================================================
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color obsidian = Color(0xFF0B130E); // Scaffold background
  static const Color forestSurface = Color(0xFF16251D); // Elevated cards (dark)
  static const Color lightCard = Color(0xFFF4F9F5); // Light accent cards (dynamic elements)

  // Branding
  static const Color primaryGreen = Color(0xFF0F4A1E); // Deep agritech green

  // Status
  static const Color mintGreen = Color(0xFF2ECC71); // Active / success
  static const Color solarYellow = Color(0xFFF1C40F); // Warning / attention
  static const Color dangerRed = Color(0xFFE74C3C);
  static const Color infoBlue = Color(0xFF3498DB);

  // Text
  static const Color textLight = Color(0xFFEAF3EC); // on dark containers
  static const Color textLightMuted = Color(0xFFA9BDB0);
  static const Color textDark = Color(0xFF10201A); // on light cards
  static const Color textDarkMuted = Color(0xFF52685C);

  static const Color divider = Color(0xFF23342A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.mintGreen,
        secondary: AppColors.solarYellow,
        surface: AppColors.forestSurface,
        error: AppColors.dangerRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.obsidian,
        elevation: 0,
        foregroundColor: AppColors.textLight,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.forestSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.textLight,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.forestSurface,
        selectedItemColor: AppColors.mintGreen,
        unselectedItemColor: AppColors.textLightMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.mintGreen : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.mintGreen.withValues(alpha: 0.4)
              : Colors.white24,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.forestSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textLightMuted),
      ),
    );
  }
}
