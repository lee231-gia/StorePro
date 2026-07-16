import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/app_palette.dart';
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
      final paymentInfo = _paymentInfo(sale);

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
                pw.Text('Payment: ${paymentInfo.label}'),
                if (paymentInfo.detail.isNotEmpty) pw.Text(paymentInfo.detail),

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sale = widget.sale;
    final paymentInfo = _paymentInfo(sale);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: 'Successful Transaction',
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: cs.onPrimary,
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
                color: cs.onPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.08),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'SUCCESSFUL TRANSACTION',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  if (paymentInfo.detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _paymentBadge(paymentInfo),
                  ],
                  const SizedBox(height: 12),

                  // Receipt number + date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _receiptRow('Transaction #', sale.id),
                        _receiptRow('Date', AppHelpers.formatDate(sale.date)),
                        _receiptRow('Customer', sale.customerName),
                        _receiptRow('Payment', paymentInfo.label),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: cs.outlineVariant),
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
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                AppHelpers.peso(item.subtotal),
                                style: TextStyle(
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
                              style: TextStyle(
                                color: isDark
                                    ? PaletteDark.warning
                                    : PaletteLight.warning,
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
                      color: cs.primaryContainer,
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
                        if (paymentInfo.balance > 0)
                          _receiptRow(
                            'Utang Balance',
                            AppHelpers.peso(paymentInfo.balance),
                            valueColor: isDark
                                ? PaletteDark.warning
                                : PaletteLight.warning,
                          ),
                        _receiptRow('Change', AppHelpers.peso(sale.change)),
                      ],
                    ),
                  ),

                  if (sale.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: ${sale.notes}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Thank you!',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'See you again.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentBadge(_PaymentInfo info) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: info.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: info.color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(info.icon, color: info.color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            info.detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: info.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );

  _PaymentInfo _paymentInfo(SaleModel sale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = sale.paymentType.toLowerCase();
    final balance = (sale.total - sale.amountPaid)
        .clamp(0, double.infinity)
        .toDouble();
    if (type == 'utang') {
      return _PaymentInfo(
        label: 'UTANG',
        detail: 'Utang recorded: ${AppHelpers.peso(balance)} balance',
        balance: balance,
        color: isDark ? PaletteDark.warning : PaletteLight.warning,
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    if (type == 'multi') {
      return _PaymentInfo(
        label: 'MULTI',
        detail:
            'Multi payment: ${AppHelpers.peso(sale.amountPaid)} paid, ${AppHelpers.peso(balance)} utang',
        balance: balance,
        color: balance > 0
            ? (isDark ? PaletteDark.warning : PaletteLight.warning)
            : (isDark ? PaletteDark.success : PaletteLight.success),
        icon: Icons.payments_outlined,
      );
    }
    return _PaymentInfo(
      label: 'CASH',
      detail: '',
      balance: 0,
      color: isDark ? PaletteDark.success : PaletteLight.success,
      icon: Icons.payments_outlined,
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
              fontSize: bold ? 15 : 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInfo {
  final String label;
  final String detail;
  final double balance;
  final Color color;
  final IconData icon;

  const _PaymentInfo({
    required this.label,
    required this.detail,
    required this.balance,
    required this.color,
    required this.icon,
  });
}
