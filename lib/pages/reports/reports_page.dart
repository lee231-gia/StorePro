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
import '../../models/product_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';

part 'reports_filters.dart';
part 'reports_sales.dart';
part 'reports_inventory.dart';
part 'reports_profit.dart';
part 'reports_export.dart';

class ReportsPage extends StatefulWidget {
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
  List<ProductModel> _products = [];
  bool _loading = false;
  bool _exporting = false;

  final _reportKey = GlobalKey();

  void _update(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
    var products = <ProductModel>[];
    try {
      final results = await Future.wait([
        ReportRepository.getSummary(_fmt(_from), _fmt(_to)),
        ProductRepository.getAll(),
      ]).timeout(const Duration(seconds: 3));
      summary = results[0] as Map<String, dynamic>;
      products = results[1] as List<ProductModel>;
    } catch (_) {
      summary = _summary;
    }
    if (mounted) {
      setState(() {
        _summary = summary;
        _products = products;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _exportImage,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Save PDF',
                onPressed: _exportPdf,
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
          _buildRangeSelector(),
          _buildTabBar(),
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSalesTab(),
                _buildInventoryTab(),
                _buildProfitTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── RANGE SELECTOR ────────────────────────────────────────
}
