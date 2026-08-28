import 'package:flutter/material.dart';

/// Reusable box shadows matching the Tailwind config's `shadow-lift` and
/// `shadow-card` tokens.
final kLiftShadow = <BoxShadow>[
  BoxShadow(
    color: const Color(0xFFE65100).withAlpha(89),
    blurRadius: 40,
    offset: const Offset(0, 18),
    spreadRadius: -18,
  ),
];

final kCardShadow = <BoxShadow>[
  BoxShadow(
    color: const Color(0xFF1A1614).withAlpha(31),
    blurRadius: 10,
    offset: const Offset(0, 2),
    spreadRadius: -4,
  ),
];
