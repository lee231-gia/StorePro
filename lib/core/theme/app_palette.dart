import 'package:flutter/material.dart';

abstract final class PaletteLight {
  PaletteLight._();
  static const Color primary = Color(0xFF1A5C5C);
  static const Color primaryContainer = Color(0xFFE0F2F1);
  static const Color accent = Color(0xFFC9A84C);
  static const Color surface = Color(0xFFFAF8F5);
  static const Color background = Color(0xFFF0EDE8);
  static const Color onSurface = Color(0xFF1A1D1F);
  static const Color onSurfaceDim = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E2DC);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
}

abstract final class PaletteDark {
  PaletteDark._();
  static const Color primary = Color(0xFF4DB6AC);
  static const Color primaryContainer = Color(0xFF1A3A3A);
  static const Color accent = Color(0xFFD4B85A);
  static const Color surface = Color(0xFF121416);
  static const Color background = Color(0xFF0D0F10);
  static const Color onSurface = Color(0xFFE8E6E1);
  static const Color onSurfaceDim = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF2A2D30);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF7043);
}
