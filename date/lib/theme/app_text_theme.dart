import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme build(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final headlineTheme = GoogleFonts.poppinsTextTheme(base);
    final bodyTheme = GoogleFonts.interTextTheme(base);

    return bodyTheme.copyWith(
      displayLarge: headlineTheme.displayLarge,
      displayMedium: headlineTheme.displayMedium,
      displaySmall: headlineTheme.displaySmall,
      headlineLarge: headlineTheme.headlineLarge,
      headlineMedium: headlineTheme.headlineMedium,
      headlineSmall: headlineTheme.headlineSmall,
      titleLarge: headlineTheme.titleLarge,
      titleMedium: headlineTheme.titleMedium,
      titleSmall: headlineTheme.titleSmall,
    );
  }
}
