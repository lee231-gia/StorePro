import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/session.dart';
import '../repositories/auth_repository.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const AppDrawer({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── HEADER ────────────────────────────────────────
          _buildHeader(),
          const SizedBox(height: 6),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _navItem(context, Icons.dashboard_outlined, 'Dashboard', 0),
                _navItem(context, Icons.inventory_2_outlined, 'Products', 1),
                _navItem(context, Icons.warehouse_outlined, 'Inventory', 2),
                _navItem(context, Icons.event_busy_outlined, 'Expiry', 3),
                _navItem(context, Icons.point_of_sale_outlined, 'Sales', 4),
                _navItem(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Utang',
                  5,
                ),
                _navItem(context, Icons.sticky_note_2_outlined, 'Notes', 6),
                _navItem(context, Icons.category_outlined, 'Categories', 7),
                _navItem(context, Icons.people_outline, 'Customers', 8),
                _navItem(context, Icons.bar_chart_outlined, 'Reports', 9),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: kDark,
                    size: 22,
                  ),
                  title: const Text('Settings', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
              ],
            ),
          ),

          // ── LOGOUT ────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout, color: kRed),
            title: const Text(
              'Log out',
              style: TextStyle(color: kRed, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              await AuthRepository.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.welcome,
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      color: kRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'STOREPRO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Session.storeName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── NAV ITEM ──────────────────────────────────────────────
  Widget _navItem(BuildContext ctx, IconData icon, String title, int tabIndex) {
    final active = currentIndex == tabIndex;
    return ListTile(
      leading: Icon(icon, color: active ? kRed : kDark, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? kRed : kDark,
        ),
      ),
      tileColor: active ? kRedLight : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(ctx);
        changeTab(tabIndex);
      },
    );
  }
}
