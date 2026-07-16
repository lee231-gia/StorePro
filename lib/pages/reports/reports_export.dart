part of 'reports_page.dart';

extension _ReportsExport on _ReportsPageState {
  void _showExportOptions({bool preferredPdf = true}) {
    final cs = Theme.of(context).colorScheme;
    final timeframes = <String, bool>{
      'hour': true,
      'today': true,
      'yesterday': false,
      'week': true,
      'month': true,
      'year': false,
      'total': false,
      'custom': true,
    };
    final modules = <String, bool>{
      'financial': true,
      'topProducts': true,
      'payments': true,
      'inventory': true,
      'activity': false,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Text(
                  'Generate Report Copy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                _exportGroupTitle('Timeframes'),
                ...timeframes.entries.map(
                  (entry) => _exportCheckbox(
                    _exportTimeframeLabel(entry.key),
                    entry.value,
                    (value) => setSheet(() => timeframes[entry.key] = value),
                  ),
                ),
                const SizedBox(height: 12),
                _exportGroupTitle('Report Modules'),
                _exportCheckbox(
                  'Financial Summary',
                  modules['financial']!,
                  (value) => setSheet(() => modules['financial'] = value),
                ),
                _exportCheckbox(
                  'Top Products',
                  modules['topProducts']!,
                  (value) => setSheet(() => modules['topProducts'] = value),
                ),
                _exportCheckbox(
                  'Payment Methods Balancing',
                  modules['payments']!,
                  (value) => setSheet(() => modules['payments'] = value),
                ),
                _exportCheckbox(
                  'Inventory & Stock',
                  modules['inventory']!,
                  (value) => setSheet(() => modules['inventory'] = value),
                ),
                _exportCheckbox(
                  'Activity Logs',
                  modules['activity']!,
                  (value) => setSheet(() => modules['activity'] = value),
                ),
                const SizedBox(height: 14),
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
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportPdf(
                            selectedTimeframes: Map<String, bool>.from(
                              timeframes,
                            ),
                            selectedModules: Map<String, bool>.from(modules),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: Text(preferredPdf ? 'Generate' : 'PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Photo export captures the visible report screen. PDF export uses the selected timeframes and modules.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportGroupTitle(String label) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _exportCheckbox(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(label, style: const TextStyle(fontSize: 13)),
    value: value,
    activeColor: Theme.of(context).colorScheme.primary,
    onChanged: (v) => onChanged(v ?? false),
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
    Map<String, bool>? selectedTimeframes,
    Map<String, bool>? selectedModules,
  }) async {
    _update(() => _exporting = true);
    try {
      final timeframes = selectedTimeframes ?? const {'custom': true};
      final modules =
          selectedModules ??
          const {
            'financial': true,
            'topProducts': true,
            'payments': true,
            'inventory': true,
            'activity': false,
          };
      final summaries = _selectedExportSummaries(timeframes);

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(34),
          footer: (_) => pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generated: ${AppHelpers.formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          build: (pw.Context ctx) {
            final blocks = <pw.Widget>[
              pw.Center(
                child: pw.Text(
                  '${Session.storeName} - Store Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Custom range: ${AppHelpers.formatDate(_fmt(_from))} to '
                  '${AppHelpers.formatDate(_fmt(_to))}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 14),
            ];

            for (final entry in summaries.entries) {
              blocks.add(_pdfSectionTitle(_exportTimeframeLabel(entry.key)));
              if (modules['financial'] == true) {
                blocks.addAll(_pdfFinancialBlock(entry.value));
              }
              if (modules['topProducts'] == true) {
                blocks.addAll(_pdfTopProductsBlock(entry.value));
              }
              if (modules['payments'] == true) {
                blocks.addAll(_pdfPaymentBlock(entry.value));
              }
              blocks.add(pw.SizedBox(height: 12));
            }

            if (modules['inventory'] == true) {
              blocks.addAll(_pdfInventoryBlock());
            }
            if (modules['activity'] == true) {
              blocks.addAll(_pdfActivityBlock());
            }
            blocks.addAll(_pdfFormulaBlock());
            return blocks;
          },
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

  Map<String, Map<String, dynamic>> _selectedExportSummaries(
    Map<String, bool> timeframes,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in timeframes.entries) {
      if (!entry.value) continue;
      if (entry.key == 'custom') {
        if (_summary != null) result[entry.key] = _summary!;
      } else {
        final summary = _rangeSummaries[entry.key];
        if (summary != null) result[entry.key] = summary;
      }
    }
    return result;
  }

  List<pw.Widget> _pdfFinancialBlock(Map<String, dynamic> s) {
    final gross = (s['grossRevenue'] as num?)?.toDouble() ?? 0.0;
    final net =
        (s['netRevenue'] as num?)?.toDouble() ??
        (s['totalRevenue'] as num?)?.toDouble() ??
        0.0;
    final discount = (s['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final cogs = (s['cogs'] as num?)?.toDouble() ?? 0.0;
    final profit = (s['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final tx = (s['totalTx'] as num?)?.toInt() ?? 0;
    final margin = net > 0 ? (profit / net) * 100 : 0.0;
    return [
      _pdfSubTitle('Financial Summary'),
      _pdfRow('Gross Revenue', _pdfMoney(gross)),
      _pdfRow('Total Discounts', _pdfMoney(discount)),
      _pdfRow('Net Revenue', _pdfMoney(net)),
      _pdfRow('Cost of Goods (COGS)', _pdfMoney(cogs)),
      _pdfRow('Net Profit', _pdfMoney(profit)),
      _pdfRow('Net Profit Margin', '${margin.toStringAsFixed(1)}%'),
      _pdfRow('Sales Count', '$tx'),
    ];
  }

  List<pw.Widget> _pdfTopProductsBlock(Map<String, dynamic> s) {
    final tops = (s['topProducts'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return [
      pw.SizedBox(height: 8),
      _pdfSubTitle('Top Products'),
      if (tops.isEmpty)
        pw.Text(
          'No sales in this period.',
          style: const pw.TextStyle(fontSize: 10),
        )
      else
        ...tops.take(10).map((item) {
          final variant = (item['variantName'] ?? '').toString();
          final profit = (item['profit'] as num?)?.toDouble() ?? 0.0;
          return _pdfRow(
            '${item['name']}${variant.isEmpty ? '' : ' - $variant'}',
            '${item['qty']} sold | Profit ${_pdfMoney(profit)}',
          );
        }),
    ];
  }

  List<pw.Widget> _pdfPaymentBlock(Map<String, dynamic> s) {
    final cash = (s['cashCollected'] as num?)?.toDouble() ?? 0.0;
    final utangSales = (s['utangTotal'] as num?)?.toDouble() ?? 0.0;
    final openUtang = _utang.where((u) => u.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    return [
      pw.SizedBox(height: 8),
      _pdfSubTitle('Payment Methods Balancing'),
      _pdfRow('Cash', _pdfMoney(cash)),
      _pdfRow('Utang Sales', _pdfMoney(utangSales)),
      if (openUtang.isNotEmpty) ...[
        _pdfRow(
          'Open Utang Balance',
          _pdfMoney(openUtang.fold(0.0, (sum, u) => sum + u.balance)),
        ),
        ...openUtang
            .take(8)
            .map(
              (u) => _pdfRow(
                '${u.customerName}${u.customerPhone.isEmpty ? '' : ' | ${u.customerPhone}'}',
                _pdfMoney(u.balance),
              ),
            ),
      ],
    ];
  }

  List<pw.Widget> _pdfInventoryBlock() {
    final low = <String>[];
    final none = <String>[];
    var value = 0.0;
    for (final product in _products) {
      for (final variant in product.variants) {
        value += variant.totalStock * variant.avgCostPrice;
        final label =
            '${product.name} - ${variant.name} (${variant.totalStock})';
        if (variant.totalStock == 0) none.add(label);
        if (variant.totalStock > 0 && variant.totalStock <= 10) low.add(label);
      }
    }
    return [
      _pdfSectionTitle('Inventory & Stock'),
      _pdfRow('Inventory Value', _pdfMoney(value)),
      _pdfRow('Total Low Stock', '${low.length}'),
      _pdfRow('Total No Stock', '${none.length}'),
      if (low.isNotEmpty) pw.Text('Low stock: ${low.take(12).join(', ')}'),
      if (none.isNotEmpty) pw.Text('No stock: ${none.take(12).join(', ')}'),
    ];
  }

  List<pw.Widget> _pdfActivityBlock() => [
    _pdfSectionTitle('Activity Logs'),
    if (_activityLogs.isEmpty)
      pw.Text('No activity logged.', style: const pw.TextStyle(fontSize: 10))
    else
      ..._activityLogs.take(25).map((log) {
        final action = (log['action'] ?? '').toString().replaceAll('_', ' ');
        final timestamp = DateTime.tryParse(
          (log['timestamp'] ?? '').toString(),
        );
        return pw.Text(
          '[${timestamp == null ? '--:--' : AppHelpers.formatDateTime(timestamp)}] $action',
          style: const pw.TextStyle(fontSize: 10),
        );
      }),
  ];

  List<pw.Widget> _pdfFormulaBlock() => [
    pw.SizedBox(height: 14),
    _pdfSectionTitle('Calculation Notes'),
    pw.Text(
      'Gross Revenue = sale subtotal before discounts\n'
      'Net Revenue = Gross Revenue - Total Discounts\n'
      'COGS = Units Sold x recorded Cost Price\n'
      'Net Profit = Net Revenue - COGS\n'
      'Net Profit Margin = Net Profit / Net Revenue x 100',
      style: const pw.TextStyle(fontSize: 10),
    ),
  ];

  pw.Widget _pdfSectionTitle(String title) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    margin: const pw.EdgeInsets.only(bottom: 6, top: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(width: 0.6)),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
    ),
  );

  pw.Widget _pdfSubTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    ),
  );

  pw.Row _pdfRow(String label, String value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ),
      pw.SizedBox(width: 12),
      pw.Text(
        value,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    ],
  );

  String _pdfMoney(double amount) => 'PHP ${amount.toStringAsFixed(2)}';

  String _exportTimeframeLabel(String key) {
    switch (key) {
      case 'hour':
        return 'Hourly';
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'Week';
      case 'month':
        return 'Month';
      case 'year':
        return 'Year';
      case 'total':
        return 'Total';
      case 'custom':
        return 'Custom (1 date or From/To)';
      default:
        return key;
    }
  }
}
