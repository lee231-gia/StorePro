import 'dart:async';

import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';
import 'core/services/alert_service.dart';
import 'core/services/data_sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/sqlite_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'widgets/app_drawer.dart';
import 'core/utils/session.dart';
import 'repositories/auth_repository.dart';
import 'pages/auth/welcome_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/products/products_page.dart';
import 'pages/inventory/inventory_page.dart';
import 'pages/expiry/expiry_page.dart';
import 'pages/sales/sales_page.dart';
import 'pages/utang/utang_page.dart';
import 'pages/notes/notes_page.dart';
import 'pages/categories/categories_page.dart';
import 'pages/customers/customers_page.dart';
import 'pages/reports/reports_page.dart';

class StorePro extends StatefulWidget {
  final bool localBootstrapped;
  final ThemeProvider themeProvider;

  const StorePro({
    super.key,
    this.localBootstrapped = false,
    required this.themeProvider,
  });

  @override
  State<StorePro> createState() => _StoreProState();
}

class _StoreProState extends State<StorePro> {
  StreamSubscription<bool>? _onlineSub;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrapped = widget.localBootstrapped;
    if (!_bootstrapped) _bootstrapLocalApp();
    _onlineSub = SyncService.onlineStream.listen((online) {
      Session.isOnline = online;
      if (online) DataSyncService.syncAllInBackground();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpServices();
    });
  }

  Future<void> _bootstrapLocalApp() async {
    try {
      await SQLiteService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
      await AuthRepository.restoreLocalSession().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _bootstrapped = true);
    }
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    super.dispose();
  }

  void _warmUpServices() {
    SQLiteService.warmUp();
    NotificationService.init().ignore();
    DataSyncService.syncAllInBackground();
    Future<void>.delayed(const Duration(seconds: 2), () {
      AlertService.runAll().ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) return const _StoreProBootScreen();

    return ListenableBuilder(
      listenable: widget.themeProvider,
      builder: (context, _) {
        final theme = widget.themeProvider;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StorePro',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.themeMode,
          initialRoute: Session.storeId.isEmpty
              ? AppRoutes.welcome
              : AppRoutes.home,
          routes: {
            AppRoutes.welcome: (_) =>
                Session.storeId.isEmpty ? const WelcomePage() : const MainNavPage(),
            AppRoutes.login: (_) =>
                Session.storeId.isEmpty ? const LoginPage() : const MainNavPage(),
            AppRoutes.signup: (_) =>
                Session.storeId.isEmpty ? const SignupPage() : const MainNavPage(),
            AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
            AppRoutes.settings: (_) => const SettingsPage(),
            AppRoutes.home: (_) => const MainNavPage(),
          },
        );
      },
    );
  }
}

class _StoreProBootScreen extends StatelessWidget {
  const _StoreProBootScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1A1A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN NAV PAGE
// Drawer-driven shell for all main pages.
// ══════════════════════════════════════════════════════════════
class MainNavPage extends StatefulWidget {
  const MainNavPage({super.key});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int _index = 0;
  final Map<int, Widget> _pageCache = {};

  void _changeTab(int i) => setState(() => _index = i);

  // All 11 pages — index must match AppDrawer nav items
  Widget _pageFor(int index) {
    return _pageCache.putIfAbsent(index, () {
      switch (index) {
        case 1:
          return ProductsPage(changeTab: _changeTab, currentIndex: index);
        case 2:
          return InventoryPage(changeTab: _changeTab, currentIndex: index);
        case 3:
          return ExpiryPage(changeTab: _changeTab, currentIndex: index);
        case 4:
          return SalesPage(changeTab: _changeTab, currentIndex: index);
        case 5:
          return UtangPage(changeTab: _changeTab, currentIndex: index);
        case 6:
          return NotesPage(changeTab: _changeTab, currentIndex: index);
        case 7:
          return CategoriesPage(changeTab: _changeTab, currentIndex: index);
        case 8:
          return CustomersPage(changeTab: _changeTab, currentIndex: index);
        case 9:
          return ReportsPage(changeTab: _changeTab, currentIndex: index);
        case 0:
        default:
          return DashboardPage(changeTab: _changeTab, currentIndex: index);
      }
    });
  }

  Widget _buildPageContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_index),
        child: _pageFor(_index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_index != 0) {
          _changeTab(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return Scaffold(body: _buildWideLayout());
          }
          return Scaffold(
            drawer: AppDrawer(changeTab: _changeTab, currentIndex: _index),
            body: _buildPageContent(),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _changeTab,
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storefront_outlined, color: colorScheme.onPrimary, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'StorePro',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.primary),
                ),
              ],
            ),
          ),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), label: Text('Products')),
            NavigationRailDestination(icon: Icon(Icons.warehouse_outlined), label: Text('Inventory')),
            NavigationRailDestination(icon: Icon(Icons.event_busy_outlined), label: Text('Expiry')),
            NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), label: Text('Sales')),
            NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: Text('Utang')),
            NavigationRailDestination(icon: Icon(Icons.sticky_note_2_outlined), label: Text('Notes')),
            NavigationRailDestination(icon: Icon(Icons.category_outlined), label: Text('Categories')),
            NavigationRailDestination(icon: Icon(Icons.people_outline), label: Text('Customers')),
            NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), label: Text('Reports')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildPageContent()),
      ],
    );
  }
}
