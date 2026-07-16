import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/session.dart';

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
          _buildHeader(context),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  minLeadingWidth: 30,
                  horizontalTitleGap: 12,
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: Icon(
                    Icons.settings_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 42, 18, 16),
      color: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
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
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'STOREPRO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Session.storeName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext ctx, IconData icon, String title, int tabIndex) {
    final active = currentIndex == tabIndex;
    final colorScheme = Theme.of(ctx).colorScheme;
    return ListTile(
      minLeadingWidth: 30,
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: active ? colorScheme.primary : colorScheme.onSurface, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      tileColor: active ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(ctx);
        changeTab(tabIndex);
      },
    );
  }
}
