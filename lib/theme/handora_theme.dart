import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

ThemeData lightTheme() {
  final text = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    textTheme: text,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saffron600,
      brightness: Brightness.light,
    ),
  );
}

ThemeData darkTheme() {
  final text = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.ink950,
    textTheme: text,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saffron600,
      brightness: Brightness.dark,
    ),
  );
}

/// Quick helper for Hindi text that needs Noto Sans Devanagari.
TextStyle devaStyle([TextStyle? base]) =>
    GoogleFonts.notoSansDevanagari(textStyle: base);
