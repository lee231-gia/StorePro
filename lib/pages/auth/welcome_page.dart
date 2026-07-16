import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/shared_widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.storefront,
                    color: cs.onPrimary,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'welcome to',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'STOREPRO',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Store Management Made Easy',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(width: 10, height: 10, color: cs.primary),
                    Expanded(child: Container(height: 1.5, color: cs.primary)),
                    Container(width: 10, height: 10, color: cs.primary),
                  ],
                ),

                const SizedBox(height: 36),

                PrimaryButton(
                  label: 'Login',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                ),
                const SizedBox(height: 12),
                OutlineBtn(
                  label: 'Sign Up',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
