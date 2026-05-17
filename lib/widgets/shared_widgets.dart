import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// ── APP BAR ───────────────────────────────────────────────────
PreferredSizeWidget buildAppBar({
  required String title,
  required BuildContext context,
  List<Widget>? actions,
  bool showMenu = true,
  PreferredSizeWidget? bottom,
  bool showBack = false,
}) {
  return AppBar(
    backgroundColor: kRed,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          )
        : showMenu
        ? Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
    ),
    actions: actions,
    bottom: bottom,
  );
}

// ── INPUT DECORATION ──────────────────────────────────────────
class AppInput {
  AppInput._();

  static InputDecoration field(
    String hint, {
    IconData? icon,
    Widget? suffix,
    double radius = 12,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kGrey, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: kGrey, size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: kInputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: kRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: kRed, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static InputDecoration dialog(String hint) =>
      field(hint, radius: 10).copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      );
}

// ── PRIMARY BUTTON ────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── OUTLINE BUTTON ────────────────────────────────────────────
class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;

  const OutlineBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: kRed,
          side: const BorderSide(color: kRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── SECTION LABEL ─────────────────────────────────────────────
Widget sectionLabel(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: kRed,
    ),
  ),
);

// ── FIELD LABEL ───────────────────────────────────────────────
Widget fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: kDark,
    ),
  ),
);

// ── SNACK BAR ─────────────────────────────────────────────────
void showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ── INFO ROW (for detail pages — Kotatsu style) ───────────────
// label | value, like a table row
Widget infoRow(String label, String value, {IconData? icon}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, color: kGrey, size: 18),
        const SizedBox(width: 10),
      ],
      SizedBox(
        width: 120,
        child: Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: kDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

// ── CARD CONTAINER ────────────────────────────────────────────
Widget appCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(14),
  EdgeInsets margin = const EdgeInsets.only(bottom: 12),
  double radius = 14,
  Color color = kCard,
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
      ],
    ),
    child: child,
  );
}

// ── STATUS BADGE ──────────────────────────────────────────────
Widget statusBadge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    label,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
  ),
);
