part of 'reports_page.dart';

extension _ReportsExport on _ReportsPageState {
  void _showExportOptions() {
    var includeOverview = true;
    var includeTopProducts = true;
    var includeInventory = true;
    var includeActivity = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get Report Copy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _exportToggle(
                  'Sales overview',
                  includeOverview,
                  (v) => setSheet(() => includeOverview = v),
                ),
                _exportToggle(
                  'Top products',
                  includeTopProducts,
                  (v) => setSheet(() => includeTopProducts = v),
                ),
                _exportToggle(
                  'Inventory risk',
                  includeInventory,
                  (v) => setSheet(() => includeInventory = v),
                ),
                _exportToggle(
                  'Recent activity',
                  includeActivity,
                  (v) => setSheet(() => includeActivity = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportImage();
                        },
                        icon: const Icon(Icons.image_outlined, size: 16),
                        label: const Text('Photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportPdf(
                            includeOverview: includeOverview,
                            includeTopProducts: includeTopProducts,
                            includeInventory: includeInventory,
                            includeActivity: includeActivity,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 13)),
    value: value,
    activeThumbColor: kRed,
    onChanged: onChanged,
  );

  Future<void> _exportImage() async {
    _update(() => _exporting = true);
    try {
      final boundary =
          _reportKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'StorePro Report'),
      );
    } catch (_) {
      if (mounted) showSnack(context, 'Export failed.', isError: true);
    } finally {
      if (mounted) _update(() => _exporting = false);
    }
  }

  Future<void> _exportPdf({
    bool includeOverview = true,
    bool includeTopProducts = true,
    bool includeInventory = true,
    bool includeActivity = false,
  }) async {
    _update(() => _exporting = true);
    try {
      final s = _summary!;
      final revenue = (s['totalRevenue'] as num).toDouble();
      final profit = (s['totalProfit'] as num).toDouble();
      final txCount = (s['totalTx'] as num).toInt();
      final tops = (s['topProducts'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
      final cogs = revenue - profit;

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          footer: (_) => pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generated: ${AppHelpers.formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          build: (pw.Context ctx) => [
            pw.Center(
              child: pw.Text(
                '${Session.storeName} - Sales Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                '${AppHelpers.formatDate(_fmt(_from))} to '
                '${AppHelpers.formatDate(_fmt(_to))}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 14),
            if (includeOverview) ...[
              _pdfSectionTitle('Sales Overview'),
              _pdfRow('Total revenue', _pdfMoney(revenue)),
              _pdfRow('COGS', _pdfMoney(cogs)),
              _pdfRow('Net profit', _pdfMoney(profit)),
              _pdfRow('Profit margin', '${margin.toStringAsFixed(1)}%'),
              _pdfRow('Transactions', '$txCount'),
            ],
            if (includeTopProducts) ...[
              pw.SizedBox(height: 14),
              _pdfSectionTitle('Top Products'),
              if (tops.isEmpty)
                pw.Text('No sales in this period.')
              else
                ...tops.asMap().entries.map((entry) {
                  final item = entry.value;
                  final variant = (item['variantName'] ?? '').toString();
                  return _pdfRow(
                    '${entry.key + 1}. ${item['name']}'
                        '${variant.isEmpty ? '' : ' - $variant'}',
                    '${item['qty']} sold',
                  );
                }),
            ],
            if (includeInventory) ...[
              pw.SizedBox(height: 14),
              _pdfSectionTitle('Inventory Snapshot'),
              _pdfRow('Products', '${_products.length}'),
              _pdfRow(
                'Stock on hand',
                '${_products.fold(0, (s, p) => s + p.totalStock)} pcs',
              ),
            ],
            if (includeActivity) ...[
              pw.SizedBox(height: 14),
              _pdfSectionTitle('Recent Activity'),
              if (_activityLogs.isEmpty)
                pw.Text('No activity logged.')
              else
                ..._activityLogs.take(20).map((log) {
                  final action = (log['action'] ?? '').toString().replaceAll(
                    '_',
                    ' ',
                  );
                  final employee = (log['employeeName'] ?? 'System').toString();
                  final target = (log['targetName'] ?? '').toString();
                  return pw.Text(
                    '$employee - $action${target.isEmpty ? '' : ': $target'}',
                    style: const pw.TextStyle(fontSize: 10),
                  );
                }),
            ],
            pw.SizedBox(height: 14),
            _pdfSectionTitle('Profit Formula'),
            pw.Text(
              'Revenue = Units Sold x Price\n'
              'COGS = Units Sold x Cost\n'
              'Profit = Revenue - COGS\n'
              'Margin % = Profit / Revenue x 100',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'StorePro Report PDF'),
      );
    } catch (_) {
      if (mounted) showSnack(context, 'PDF export failed.', isError: true);
    } finally {
      if (mounted) _update(() => _exporting = false);
    }
  }

  pw.Widget _pdfSectionTitle(String title) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    margin: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(width: 0.6)),
    ),
    child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );

  pw.Row _pdfRow(String label, String value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: pw.Text(label)),
      pw.SizedBox(width: 12),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ],
  );

  String _pdfMoney(double amount) => 'PHP ${amount.toStringAsFixed(2)}';
}
