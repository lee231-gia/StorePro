import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/sale_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/utils/session.dart';

class ReceiptPage extends StatefulWidget {
  final SaleModel sale;
  const ReceiptPage({super.key, required this.sale});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final _receiptKey = GlobalKey();
  bool _saving = false;

  // ── SHARE AS IMAGE ─────────────────────────────────────────
  Future<void> _shareImage() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/transaction_${widget.sale.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Successful transaction - ${widget.sale.customerName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Failed to share image.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── SHARE AS PDF ───────────────────────────────────────────
  Future<void> _sharePdf() async {
    setState(() => _saving = true);
    try {
      final pdf = pw.Document();
      final sale = widget.sale;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    Session.storeName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'SUCCESSFUL TRANSACTION',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),

                // Info
                pw.Text('Customer: ${sale.customerName}'),
                pw.Text('Date: ${AppHelpers.formatDate(sale.date)}'),
                pw.Text('Payment: ${sale.paymentType.toUpperCase()}'),

                pw.Divider(),

                // Items
                ...sale.items.map(
                  (item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.productName} '
                          '(${item.variantName}'
                          '${item.conditionName.isNotEmpty ? '/${item.conditionName}' : ''}'
                          ') x${item.qty} @ ${AppHelpers.peso(item.price)}',
                        ),
                      ),
                      pw.Text(AppHelpers.peso(item.subtotal)),
                    ],
                  ),
                ),

                pw.Divider(),

                if (sale.totalDiscount > 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Discount:'),
                      pw.Text('- ${AppHelpers.peso(sale.totalDiscount)}'),
                    ],
                  ),
                ],

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      AppHelpers.peso(sale.total),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Amount Paid:'),
                    pw.Text(AppHelpers.peso(sale.amountPaid)),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change:'),
                    pw.Text(AppHelpers.peso(sale.change)),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text(
                    'Thank you!',
                    style: const pw.TextStyle(fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/transaction_${sale.id}.pdf');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Transaction summary - ${sale.customerName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Failed to export PDF.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Successful Transaction',
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Share as Image',
              onPressed: _shareImage,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Share as PDF',
              onPressed: _sharePdf,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: RepaintBoundary(
            key: _receiptKey,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store name
                  Text(
                    Session.storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'SUCCESSFUL TRANSACTION',
                    style: TextStyle(color: kGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Receipt number + date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _receiptRow('Transaction #', sale.id),
                        _receiptRow('Date', AppHelpers.formatDate(sale.date)),
                        _receiptRow('Customer', sale.customerName),
                        _receiptRow('Payment', sale.paymentType.toUpperCase()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Items
                  ...sale.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.variantName}'
                                '${item.conditionName.isNotEmpty ? ' / ${item.conditionName}' : ''}'
                                ' x ${item.qty} @ ${AppHelpers.peso(item.price)}',
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                AppHelpers.peso(item.subtotal),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (item.discount > 0)
                            Text(
                              'Discount: -'
                              '${AppHelpers.peso(item.discount)}',
                              style: const TextStyle(
                                color: kOrange,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRedLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (sale.totalDiscount > 0) ...[
                          _receiptRow(
                            'Discount',
                            '- ${AppHelpers.peso(sale.totalDiscount)}',
                          ),
                        ],
                        _receiptRow(
                          'TOTAL',
                          AppHelpers.peso(sale.total),
                          bold: true,
                        ),
                        _receiptRow(
                          'Amount Paid',
                          AppHelpers.peso(sale.amountPaid),
                        ),
                        _receiptRow('Change', AppHelpers.peso(sale.change)),
                      ],
                    ),
                  ),

                  if (sale.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: ${sale.notes}',
                      style: const TextStyle(color: kGrey, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Thank you!',
                    style: TextStyle(
                      color: kRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'See you again.',
                    style: TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: kGrey,
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: kDark,
                fontSize: bold ? 15 : 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}
