import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

// ── PRIMARY BRAND ─────────────────────────────────────────────
const kRed = Color(0xFF8B1A1A);
const kRedDark = Color(0xFF6A1313);
const kRedLight = Color(0xFFFFEBEE);

// ── BACKGROUND & SURFACE ──────────────────────────────────────
const kBg = Color(0xFFF5F5F5);
const kCard = Colors.white;
const kInputFill = Color(0xFFEEEEEE);

// ── TEXT ──────────────────────────────────────────────────────
const kDark = Color(0xFF1A1A1A);
const kGrey = Color(0xFF888888);

// ── STATUS ────────────────────────────────────────────────────
const kGreen = Color(0xFF2E7D32);
const kOrange = Color(0xFFE65100);

// ── CATEGORY COLOR OPTIONS ────────────────────────────────────
const List<Color> kCategoryColors = [
  Color(0xFF1565C0),
  Color(0xFFE65100),
  Color(0xFF6A1E8A),
  Color(0xFF2E7D32),
  Color(0xFF00695C),
  Color(0xFF8B1A1A),
  Color(0xFF4E342E),
  Color(0xFF37474F),
  Color(0xFFC62828),
  Color(0xFF558B2F),
];

// ── AVATAR COLOR OPTIONS ──────────────────────────────────────
const List<Color> kAvatarColors = [
  Color(0xFF8B1A1A),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFF6A1E8A),
  Color(0xFFE65100),
  Color(0xFF00695C),
  Color(0xFF4E342E),
  Color(0xFF37474F),
];

// ── PALETTE ALIASES (backward-compat, reference new palette) ──
const kPrimaryLight = PaletteLight.primary;
const kPrimaryDark = PaletteDark.primary;
const kAccentLight = PaletteLight.accent;
const kAccentDark = PaletteDark.accent;
const kSurfaceLight = PaletteLight.surface;
const kSurfaceDark = PaletteDark.surface;
const kBackgroundLight = PaletteLight.background;
const kBackgroundDark = PaletteDark.background;
const kOnSurfaceLight = PaletteLight.onSurface;
const kOnSurfaceDark = PaletteDark.onSurface;
const kOnSurfaceDimLight = PaletteLight.onSurfaceDim;
const kOnSurfaceDimDark = PaletteDark.onSurfaceDim;
const kBorderLight = PaletteLight.border;
const kBorderDark = PaletteDark.border;
const kSuccessLight = PaletteLight.success;
const kSuccessDark = PaletteDark.success;
const kErrorLight = PaletteLight.error;
const kErrorDark = PaletteDark.error;
const kWarningLight = PaletteLight.warning;
const kWarningDark = PaletteDark.warning;
