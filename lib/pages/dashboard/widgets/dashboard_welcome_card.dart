import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/session.dart';

class DashboardWelcomeCard extends StatefulWidget {
  const DashboardWelcomeCard({super.key});

  @override
  State<DashboardWelcomeCard> createState() => _DashboardWelcomeCardState();
}

class _DashboardWelcomeCardState extends State<DashboardWelcomeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? PaletteDark.primary : PaletteLight.primary;
    final firstName = Session.ownerName.isNotEmpty
        ? Session.ownerName.split(' ').first
        : 'Owner';

    return GestureDetector(
      onTapDown: (_) => _animCtrl.forward(),
      onTapUp: (_) => _animCtrl.reverse(),
      onTapCancel: () => _animCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary,
                isDark
                    ? PaletteDark.primary.withValues(alpha: 0.85)
                    : Color.lerp(primary, Colors.black, 0.15)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                'Hello, $firstName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Session.storeName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
