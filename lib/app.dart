import 'dart:async';

import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/services/alert_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/sqlite_service.dart';
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

  const StorePro({super.key, this.localBootstrapped = false});

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
      if (online) SyncService.flushInBackground();
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
    SyncService.flushInBackground();
    Future<void>.delayed(const Duration(seconds: 2), () {
      AlertService.runAll().ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) return const _StoreProBootScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StorePro',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: kRed),
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? kRed : Colors.white,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? kRedLight
                : Colors.grey.shade300,
          ),
        ),
      ),
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
        colorScheme: ColorScheme.fromSeed(seedColor: kRed),
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
      ),
      home: const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: kRed, strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN NAV PAGE
// The bottom navigation shell for all 11 main pages.
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

  Widget _buildPageStack() {
    _pageFor(_index);
    return Stack(
      children: _pageCache.entries.map((entry) {
        final active = entry.key == _index;
        return Offstage(
          offstage: !active,
          child: TickerMode(enabled: active, child: entry.value),
        );
      }).toList(),
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
      child: Scaffold(
        body: _buildPageStack(),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  // Bottom nav shows the 5 most-used tabs.
  // Rest accessible from the drawer.
  BottomNavigationBar _buildNavBar() {
    // Map bottom nav positions to page indices
    const navMap = [0, 1, 4, 6, 7]; // dash, products, sales, notes, categories
    final navIndex = navMap.contains(_index) ? navMap.indexOf(_index) : 0;

    return BottomNavigationBar(
      currentIndex: navIndex,
      onTap: (i) => _changeTab(navMap[i]),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kRed,
      unselectedItemColor: kGrey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      iconSize: 22,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Sales',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sticky_note_2_outlined),
          activeIcon: Icon(Icons.sticky_note_2),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category),
          label: 'Categories',
        ),
      ],
    );
  }
}
