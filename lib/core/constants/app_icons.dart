import 'package:flutter/material.dart';

// Central icon + unit reference used across products and categories.
// Referenced by index so data stays lightweight (just store an int).

class AppIcons {
  AppIcons._();

  // ── PRODUCT / CATEGORY ICONS ──────────────────────────────
  static const List<IconData> icons = [
    Icons.inventory_2_outlined, // 0
    Icons.local_drink_outlined, // 1
    Icons.fastfood_outlined, // 2
    Icons.dining_outlined, // 3
    Icons.egg_outlined, // 4
    Icons.spa_outlined, // 5
    Icons.medication_outlined, // 6
    Icons.rice_bowl_outlined, // 7
    Icons.coffee_outlined, // 8
    Icons.kitchen_outlined, // 9
    Icons.icecream_outlined, // 10
    Icons.local_pizza_outlined, // 11
    Icons.soap_outlined, // 12
    Icons.child_care_outlined, // 13
    Icons.pets_outlined, // 14
    Icons.local_grocery_store_outlined, // 15
    Icons.bakery_dining_outlined, // 16
    Icons.liquor_outlined, // 17
    Icons.cleaning_services_outlined, // 18
    Icons.shopping_bag_outlined, // 19
  ];

  static IconData get(int index) => icons[index.clamp(0, icons.length - 1)];

  // ── UNIT OPTIONS ──────────────────────────────────────────
  // unit name → default pcs per unit
  static const Map<String, int> unitDefaults = {
    'piece': 1,
    'bottle': 1,
    'case': 24,
    'dozen': 12,
    'sachet': 1,
    'box': 10,
    'pack': 6,
    'kg': 1,
    'liter': 1,
    'meter': 1,
  };

  static List<String> get unitOptions => unitDefaults.keys.toList();

  static int defaultPcs(String unit) => unitDefaults[unit] ?? 1;
}
