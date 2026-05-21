import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_colors.dart';
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

  // ── RANGE ─────────────────────────────────────────────────
  String _range = 'today';
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  // ── DATA ──────────────────────────────────────────────────
  Map<String, dynamic>? _summary;
  Map<String, Map<String, dynamic>> _rangeSummaries = {};
  List<ProductModel> _products = [];
  List<UtangModel> _utang = [];
  List<Map<String, dynamic>> _activityLogs = [];
  bool _loading = false;
  bool _exporting = false;
  bool _activityDetailed = false;

  final _reportKey = GlobalKey();

  void _update(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _setRange('today');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── DATE RANGE ────────────────────────────────────────────
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

  // ── GENERATE ──────────────────────────────────────────────
  Future<void> _generate() async {
    setState(() => _loading = true);
    Map<String, dynamic>? summary;
    Map<String, Map<String, dynamic>> rangeSummaries = {};
    var products = <ProductModel>[];
    var utang = <UtangModel>[];
    var activityLogs = <Map<String, dynamic>>[];
    try {
      final results = await Future.wait([
        ReportRepository.getSummary(_fmt(_from), _fmt(_to)),
        ProductRepository.getAll(),
        UtangRepository.getAll(),
        ReportRepository.getPresetSummaries(),
        ReportRepository.getActivityLogs(limit: 500),
      ]).timeout(const Duration(seconds: 3));
      summary = results[0] as Map<String, dynamic>;
      products = results[1] as List<ProductModel>;
      utang = results[2] as List<UtangModel>;
      rangeSummaries = results[3] as Map<String, Map<String, dynamic>>;
      activityLogs = results[4] as List<Map<String, dynamic>>;
    } catch (_) {
      summary = _summary;
      rangeSummaries = _rangeSummaries;
      products = _products;
      utang = _utang;
      activityLogs = _activityLogs;
    }
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
    final pendingTab = ReportsPage.pendingTab;
    if (pendingTab != null && pendingTab >= 0 && pendingTab < _tabCtrl.length) {
      ReportsPage.pendingTab = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabCtrl.animateTo(pendingTab);
      });
    }
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Reports',
        context: context,
        actions: [
          if (_summary != null && !_loading) ...[
            if (_exporting)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
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
          if (_loading) const LinearProgressIndicator(color: kRed),
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

  // ── RANGE SELECTOR ────────────────────────────────────────
}
