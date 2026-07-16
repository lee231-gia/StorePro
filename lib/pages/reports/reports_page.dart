import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/services/sync_service.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/utang_repository.dart';
import '../../models/product_model.dart';
import '../../models/utang_model.dart';
import '../../models/inventory_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/app_skeleton.dart';
import '../../core/theme/app_palette.dart';
import '../products/product_detail_page.dart';

part 'reports_filters.dart';
part 'reports_sales.dart';
part 'reports_inventory.dart';
part 'reports_profit.dart';
part 'reports_export.dart';
part 'reports_activity.dart';

class ReportsPage extends StatefulWidget {
  static int? pendingTab;

  final Function(int) changeTab;
  final int currentIndex;

  const ReportsPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  String _range = 'today';
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  Map<String, dynamic>? _summary;
  Map<String, Map<String, dynamic>> _rangeSummaries = {};
  List<ProductModel> _products = [];
  List<UtangModel> _utang = [];
  List<Map<String, dynamic>> _activityLogs = [];
  bool _loading = false;
  bool _exporting = false;
  bool _activityDetailed = false;
  StreamSubscription<String>? _syncSub;

  final _reportKey = GlobalKey();

  void _update(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _syncSub = SyncService.changes.listen((collection) {
      if (!mounted) return;
      if (collection == 'sales' ||
          collection == 'products' ||
          collection == 'utang' ||
          collection == 'activity_logs' ||
          collection == 'inventory_logs' ||
          collection == 'customers' ||
          collection == 'categories' ||
          collection == 'notes') {
        _generate();
      }
    });
    _setRange('today');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _syncSub?.cancel();
    super.dispose();
  }

  void _setRange(String range) {
    final now = DateTime.now();
    setState(() => _range = range);
    switch (range) {
      case 'hour':
        _from = now.subtract(const Duration(hours: 1));
        _to = now;
        break;
      case 'today':
        _from = DateTime(now.year, now.month, now.day);
        _to = now;
        break;
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        _from = DateTime(y.year, y.month, y.day);
        _to = DateTime(y.year, y.month, y.day, 23, 59);
        break;
      case 'week':
        _from = now.subtract(const Duration(days: 7));
        _to = now;
        break;
      case 'month':
        _from = DateTime(now.year, now.month, 1);
        _to = now;
        break;
      case 'year':
        _from = DateTime(now.year, 1, 1);
        _to = now;
        break;
      case 'total':
        _from = DateTime(2020, 1, 1);
        _to = now;
        break;
    }
    if (range != 'custom') _generate();
  }

  String _fmt(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _generate() async {
    setState(() => _loading = true);
    Map<String, dynamic>? summary;
    Map<String, Map<String, dynamic>> rangeSummaries = {};
    var products = <ProductModel>[];
    var utang = <UtangModel>[];
    var activityLogs = <Map<String, dynamic>>[];
    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future.timeout(const Duration(seconds: 10));
      } catch (_) {
        return fallback;
      }
    }

    summary = await safe(
      ReportRepository.getSummary(_fmt(_from), _fmt(_to)),
      _summary ?? <String, dynamic>{},
    );
    products = await safe(ProductRepository.getAll(), _products);
    utang = await safe(UtangRepository.getAll(), _utang);
    rangeSummaries = await safe(
      ReportRepository.getPresetSummaries(),
      _rangeSummaries,
    );
    activityLogs = await safe(
      ReportRepository.getActivityLogs(limit: 500),
      _activityLogs,
    );
    if (mounted) {
      setState(() {
        _summary = summary;
        _rangeSummaries = rangeSummaries;
        _products = products;
        _utang = utang;
        _activityLogs = activityLogs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pendingTab = ReportsPage.pendingTab;
    if (pendingTab != null && pendingTab >= 0 && pendingTab < _tabCtrl.length) {
      ReportsPage.pendingTab = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabCtrl.animateTo(pendingTab);
      });
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: 'Reports',
        context: context,
        actions: [
          if (_summary != null && !_loading) ...[
            if (_exporting)
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: cs.onPrimary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Save Image',
                onPressed: () => _showExportOptions(preferredPdf: false),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Save PDF',
                onPressed: () => _showExportOptions(preferredPdf: true),
              ),
            ],
          ],
        ],
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          AppLoadingLine(visible: _loading),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSalesTab(),
                _buildInventoryTab(),
                _buildProfitTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
