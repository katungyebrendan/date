import 'package:flutter/material.dart';
import 'app_text_theme.dart';

const veloSeedColor = Color(0xFFFF4D6D);
const veloPrimary = Color(0xFFFF4D6D);
const veloPrimaryDark = Color(0xFFE6395A);
const veloSecondary = Color(0xFF8B5CF6);
const veloAccent = Color(0xFF4CC9F0);
const veloSuccess = Color(0xFF22C55E);
const veloWarning = Color(0xFFF59E0B);
const veloError = Color(0xFFEF4444);
const veloBackground = Color(0xFFFAFAFC);
const veloCardBackground = Color(0xFFFFFFFF);
const veloBorder = Color(0xFFE5E7EB);
const veloPrimaryText = Color(0xFF1F2937);
const veloSecondaryText = Color(0xFF6B7280);

const veloAccentGradient = LinearGradient(
  colors: [veloPrimary, veloSecondary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: veloPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: veloPrimary,
      primaryContainer: const Color(0xFFFFD9E0),
      secondary: veloSecondary,
      secondaryContainer: const Color(0xFFE9DEFF),
      tertiary: veloAccent,
      tertiaryContainer: const Color(0xFFD7F4FB),
      error: veloError,
      surface: veloCardBackground,
      surfaceTint: veloPrimary,
      onSurface: veloPrimaryText,
      onSurfaceVariant: veloSecondaryText,
      outline: veloBorder,
      outlineVariant: veloBorder,
      surfaceContainerHighest: const Color(0xFFF4F5F8),
    );
    return _themeFrom(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: veloPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFFF7790),
      primaryContainer: const Color(0xFF6D2034),
      secondary: const Color(0xFFC2A4FF),
      secondaryContainer: const Color(0xFF3D2A66),
      tertiary: const Color(0xFF76DAF2),
      tertiaryContainer: const Color(0xFF163845),
      error: const Color(0xFFFF6B6B),
      surface: const Color(0xFF191622),
      surfaceTint: const Color(0xFFFF4D6D),
      onSurface: const Color(0xFFF5F3F8),
      onSurfaceVariant: const Color(0xFFB5AEC2),
      outline: const Color(0xFF5B5470),
      outlineVariant: const Color(0xFF332E43),
      surfaceContainerHighest: const Color(0xFF241E31),
    );
    return _themeFrom(colorScheme);
  }

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final textTheme = AppTextTheme.build(colorScheme.brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
