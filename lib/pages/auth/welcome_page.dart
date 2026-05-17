import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/shared_widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── LOGO ──────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 28),

                // ── APP NAME ───────────────────────────────
                const Text(
                  'welcome to',
                  style: TextStyle(
                    color: kRed,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Text(
                  'STOREPRO',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Store Management Made Easy',
                  style: TextStyle(color: kGrey, fontSize: 13),
                ),

                const SizedBox(height: 20),

                // ── DIVIDER ────────────────────────────────
                Row(
                  children: [
                    Container(width: 10, height: 10, color: kRed),
                    Expanded(child: Container(height: 1.5, color: kRed)),
                    Container(width: 10, height: 10, color: kRed),
                  ],
                ),

                const SizedBox(height: 36),

                // ── BUTTONS ────────────────────────────────
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
