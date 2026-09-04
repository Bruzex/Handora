import 'package:flutter/material.dart';

/// Handora brand colors, matching the Tailwind config and Gramin Modernism Design System.
///
/// Saffron is the primary accent. Ink & Ivory are the neutral surface scales.
/// Named [AppColors] to avoid any clashes with framework types.
abstract final class AppColors {
  // Gramin Modernism Brand & Surfaces
  static const Color surfaceIvory = Color(0xFFFFF8F1);
  static const Color surface = Color(0xFFFDF8F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F2F2);
  static const Color surfaceContainer = Color(0xFFF1EDEC);
  static const Color surfaceContainerHigh = Color(0xFFECE7E7);
  static const Color surfaceContainerHighest = Color(0xFFE6E1E1);
  static const Color surfaceDim = Color(0xFFDDD9D8);

  // Primaries (Saffron Orange & Burnt Ochre)
  static const Color primary = Color(0xFF9F4200); // Deep Burnt Saffron for high-contrast CTAs
  static const Color primaryContainer = Color(0xFFFF7722); // Vibrant Saffron Orange
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF5E2400);
  static const Color primaryFixed = Color(0xFFFFDBCB);
  static const Color primaryFixedDim = Color(0xFFFFB692);

  // Content & Typography
  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color onSurfaceVariant = Color(0xFF594237);
  static const Color outline = Color(0xFF8C7165);
  static const Color outlineVariant = Color(0xFFE0C0B1);

  // Secondary & Trust Tones (WhatsApp Green / Deep Teal)
  static const Color secondary = Color(0xFF006D2F);
  static const Color secondaryContainer = Color(0xFF5DFD8A);
  static const Color tertiary = Color(0xFF006B5F);

  // Shadows
  static const Color shadowColor = Color(0x0A000000); // 4% soft shadow

  // Saffron primary scale (Classic)
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

/// Gramin Modernism Spacing & Dimensions
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double marginMobile = 16.0;
  static const double minTouchTarget = 48.0;
}
