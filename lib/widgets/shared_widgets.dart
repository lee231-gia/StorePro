import 'package:flutter/material.dart';

// ── APP BAR ───────────────────────────────────────────────────
PreferredSizeWidget buildAppBar({
  required String title,
  required BuildContext context,
  List<Widget>? actions,
  bool showMenu = true,
  PreferredSizeWidget? bottom,
  bool showBack = false,
}) {
  final cs = Theme.of(context).colorScheme;
  return AppBar(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),
    actions: actions,
    bottom: bottom,
  );
}

// ── INPUT DECORATION ──────────────────────────────────────────
class AppInput {
  AppInput._();

  static InputDecoration field(
    BuildContext context,
    String hint, {
    IconData? icon,
    Widget? suffix,
    double radius = 12,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: textTheme.bodySmall,
      prefixIcon:
          icon != null ? Icon(icon, color: cs.onSurfaceVariant, size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static InputDecoration dialog(BuildContext context, String hint) =>
      field(context, hint, radius: 10).copyWith(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: cs.onPrimary,
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
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary, width: 1.5),
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
      child: Builder(
        builder: (context) => Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );

// ── FIELD LABEL ───────────────────────────────────────────────
Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Builder(
        builder: (context) => Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );

// ── SNACK BAR ─────────────────────────────────────────────────
void showSnack(BuildContext context, String msg, {bool isError = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: TextStyle(color: isError ? cs.onError : cs.onPrimary),
      ),
      backgroundColor: isError ? cs.error : cs.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ── INFO ROW (for detail pages — Kotatsu style) ───────────────
Widget infoRow(String label, String value, {IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: cs.onSurfaceVariant, size: 18),
                const SizedBox(width: 10),
              ],
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

// ── CARD CONTAINER ────────────────────────────────────────────
Widget appCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(14),
  EdgeInsets margin = const EdgeInsets.only(bottom: 12),
  double radius = 14,
  Color? color,
}) {
  return Builder(
    builder: (context) {
      final cardColor = color ??
          Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface;
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: child,
      );
    },
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
