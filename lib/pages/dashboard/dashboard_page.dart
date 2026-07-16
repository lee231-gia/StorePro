import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/alert_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_widgets.dart';
import '../products/add_product_page.dart';
import '../products/product_detail_page.dart';
import '../reports/reports_page.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_activity_section.dart';
import 'widgets/dashboard_expiry_section.dart';
import 'widgets/dashboard_low_stock_section.dart';
import 'widgets/dashboard_overview_section.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_store_overview.dart';
import 'widgets/dashboard_today_sales.dart';
import 'widgets/dashboard_welcome_card.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const DashboardPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: buildAppBar(
        title: '',
        context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await AlertService.runAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Alerts refreshed.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
            ).then((_) => _controller.load()),
          ),
        ],
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: _controller.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardWelcomeCard(),
                  const SizedBox(height: 12),
                  DashboardStoreOverview(controller: _controller),
                  const SizedBox(height: 20),
                  DashboardTodaySales(controller: _controller),
                  const SizedBox(height: 20),
                  DashboardOverviewSection(
                    controller: _controller,
                    changeTab: widget.changeTab,
                  ),
                  const SizedBox(height: 20),
                  DashboardQuickActions(
                    controller: _controller,
                    changeTab: widget.changeTab,
                    onAddProduct: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductPage(),
                        ),
                      ).then((_) => _controller.load());
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_controller.expiryAlerts.isNotEmpty)
                    DashboardExpirySection(
                      controller: _controller,
                      openProductDetail: _openProductDetail,
                      onSeeAll: () => widget.changeTab(3),
                    ),
                  if (_controller.lowStockCount > 0)
                    DashboardLowStockSection(
                      controller: _controller,
                      openProductDetail: _openProductDetail,
                      onSeeAll: () => widget.changeTab(2),
                    ),
                  DashboardActivitySection(
                    controller: _controller,
                    onSeeAll: () {
                      ReportsPage.pendingTab = 3;
                      widget.changeTab(9);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openProductDetail(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: productId),
      ),
    ).then((_) => _controller.load());
  }
}
