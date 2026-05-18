part of 'reports_page.dart';

extension _ReportsExport on _ReportsPageState {
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
      if (mounted) {
        showSnack(context, 'Export failed.', isError: true);
      }
    } finally {
      if (mounted) _update(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    _update(() => _exporting = true);
    try {
      final s = _summary!;
      final revenue = (s['totalRevenue'] as num).toDouble();
      final profit = (s['totalProfit'] as num).toDouble();
      final txCount = s['totalTx'] as int;
      final tops = s['topProducts'] as List<Map<String, dynamic>>;
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
      final cogs = revenue - profit;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '${Session.storeName} — SALES REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${AppHelpers.formatDate(_fmt(_from))}'
                  '  →  '
                  '${AppHelpers.formatDate(_fmt(_to))}',
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),

              _pdfRow('Total Revenue', AppHelpers.peso(revenue)),
              _pdfRow('COGS', AppHelpers.peso(cogs)),
              _pdfRow('Net Profit', AppHelpers.peso(profit)),
              _pdfRow('Profit Margin', '${margin.toStringAsFixed(1)}%'),
              _pdfRow('Transactions', '$txCount'),

              pw.SizedBox(height: 12),
              pw.Divider(),

              pw.Text(
                'TOP PRODUCTS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),

              ...tops.asMap().entries.map(
                (e) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${e.key + 1}. ${e.value['name']}'),
                    pw.Text('${e.value['qty']} sold'),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(),

              pw.Text(
                'PROFIT FORMULA',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Revenue = Units Sold × Price\n'
                'COGS = Units Sold × Cost\n'
                'Profit = Revenue − COGS\n'
                'Margin % = Profit ÷ Revenue × 100',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Generated: ${AppHelpers.formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
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
      if (mounted) {
        showSnack(context, 'PDF export failed.', isError: true);
      }
    } finally {
      if (mounted) _update(() => _exporting = false);
    }
  }

  pw.Row _pdfRow(String label, String value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ],
  );
}
