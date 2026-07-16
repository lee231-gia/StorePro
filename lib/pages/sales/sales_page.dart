import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import 'package:storepro/shared/widgets/state_views.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import 'sales_controller.dart';
import 'views/new_sale_view.dart';
import 'views/history_view.dart';

class SalesPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const SalesPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final controller = SalesController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChanged);
    controller.init();
    controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildAppBar(
        title: 'Sales',
        context: context,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            children: [
              SalesTabButton(
                label: 'New Sale',
                isActive: controller.tab == 0,
                onTap: () => setState(() => controller.tab = 0),
              ),
              SalesTabButton(
                label: 'History',
                isActive: controller.tab == 1,
                onTap: () => setState(() => controller.tab = 1),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: controller.tab == 1
          ? FloatingActionButton.small(
              heroTag: 'sales_add_fab',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => setState(() => controller.tab = 0),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppLoadingLine(visible: controller.loading),
          Expanded(
            child: [
              NewSaleView(controller: controller),
              HistoryView(controller: controller),
            ][controller.tab],
          ),
        ],
      ),
    );
  }
}
