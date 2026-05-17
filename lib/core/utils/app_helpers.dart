import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class AppHelpers {
  AppHelpers._();

  // ── DATE FORMATTING ───────────────────────────────────────
  static String formatDate(String iso) {
    if (iso.isEmpty) return 'No date';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy  h:mm a').format(dt);
  }

  static String todayStr() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String nowStr() {
    return DateTime.now().toIso8601String();
  }

  // ── CURRENCY ──────────────────────────────────────────────
  static String peso(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  // ── DAYS LEFT ─────────────────────────────────────────────
  static int daysLeft(String expiry) {
    if (expiry.isEmpty) return 999;
    try {
      return DateTime.parse(expiry).difference(DateTime.now()).inDays;
    } catch (_) {
      return 999;
    }
  }

  static String expiryStatus(String expiry) {
    if (expiry.isEmpty) return 'good';
    final d = daysLeft(expiry);
    if (d < 0) return 'expired';
    if (d <= 30) return 'expiring';
    return 'good';
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'expired':
        return const Color(0xFF8B1A1A);
      case 'expiring':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  // ── PASSWORD HASHING ──────────────────────────────────────
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── OTP GENERATOR ─────────────────────────────────────────
  static String generateOtp({int length = 6}) {
    final rand = Random.secure();
    return List.generate(length, (_) => rand.nextInt(10)).join();
  }

  // ── ID GENERATOR ──────────────────────────────────────────
  static String newId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ── STOCK STATUS ──────────────────────────────────────────
  static String stockStatus(int qty) {
    if (qty == 0) return 'no_stock';
    if (qty <= 10) return 'low';
    return 'good';
  }

  static Color stockColor(int qty) {
    if (qty == 0) return const Color(0xFF8B1A1A);
    if (qty <= 10) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  // ── PROFIT ────────────────────────────────────────────────
  // profit = (selling price - cost price) x qty sold
  static double calcProfit(double sellPrice, double costPrice, int qty) {
    return (sellPrice - costPrice) * qty;
  }

  // ── VALIDATORS ────────────────────────────────────────────
  static String? validateNotEmpty(String? val, String field) {
    if (val == null || val.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
