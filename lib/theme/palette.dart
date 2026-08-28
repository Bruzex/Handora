import 'package:flutter/material.dart';

/// Handora brand colors, matching the Tailwind config.
///
/// Saffron is the primary accent. Ink is the neutral surface scale.
/// Named [AppColors] to avoid any clashes with framework types.
abstract final class AppColors {
  // Saffron primary scale
  static const saffron50  = Color(0xFFFFF4EC);
  static const saffron100 = Color(0xFFFFE3CC);
  static const saffron200 = Color(0xFFFFC79A);
  static const saffron500 = Color(0xFFF57C00);
  static const saffron600 = Color(0xFFE65100);
  static const saffron700 = Color(0xFFBF4400);

  // Ink / neutral surface scale
  static const ink950  = Color(0xFF0F1115);
  static const ink900  = Color(0xFF1A1614);
  static const ink800  = Color(0xFF1F2937);
  static const ink700  = Color(0xFF3D3733);
  static const ink500  = Color(0xFF6B625C);
  static const ink200  = Color(0xFFE4DFDA);

  // Status colors used in badges, order tags, etc.
  static const green50  = Color(0xFFF0FDF4);
  static const green600 = Color(0xFF16A34A);
  static const green800 = Color(0xFF166534);

  static const amber100 = Color(0xFFFEF3C7);
  static const amber400 = Color(0xFFFBBF24);
  static const amber600 = Color(0xFFD97706);

  static const red500   = Color(0xFFEF4444);
  static const red600   = Color(0xFFDC2626);
}
