import 'package:flutter/material.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import '../sales_controller.dart';
import '../receipt_page.dart';
import 'edit_sale_dialog.dart';

class HistoryView extends StatelessWidget {
  final SalesController controller;

  const HistoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sales = controller.historySales;

    if (controller.sales.isEmpty) {
      return Center(
        child: Text(
          'No sales yet.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () => controller.load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sales.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _historyFilterBar(context, sales.length);
          final sale = sales[i - 1];
          return SalesHistoryCard(
            sale: sale,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)),
            ),
            onEdit: sale.status == 'refunded'
                ? null
                : () async {
                    final edited = await showEditSaleDialog(context, sale);
                    if (edited != null && context.mounted) {
                      await controller.load();
                    }
                  },
            onRefund: sale.status == 'refunded'
                ? null
                : () => controller.confirmRefund(context, sale),
            onDelete: () => controller.confirmDelete(context, sale),
          );
        },
      ),
    );
  }

  Widget _historyFilterBar(BuildContext context, int count) {
    final cs = Theme.of(context).colorScheme;
    final chips = {
      'all': 'All',
      'today': 'Today',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'custom': 'Custom',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.entries.map((entry) {
                  final active = controller.historyRange == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () async {
                        if (entry.key == 'custom') {
                          final now = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                            initialDateRange:
                                controller.historyCustomRange ??
                                DateTimeRange(start: now, end: now),
                          );
                          if (picked == null) return;
                          controller.setHistoryCustomRange(picked);
                          return;
                        }
                        controller.setHistoryRange(entry.key);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active ? cs.primary : cs.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? cs.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: active
                                ? cs.onPrimary
                                : cs.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
