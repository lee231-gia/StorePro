// part of 'sales_page.dart';

// extension _SalesHistoryView on _SalesPageState {
//   // â”€â”€ HISTORY VIEW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   Widget _buildHistory() {
//     if (_sales.isEmpty) {
//       return const Center(
//         child: Text('No sales yet.', style: TextStyle(color: kGrey)),
//       );
//     }

//     return RefreshIndicator(
//       color: kRed,
//       onRefresh: _load,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _sales.length,
//         itemBuilder: (_, i) {
//           final sale = _sales[i];
//           return SalesHistoryCard(
//             sale: sale,
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => ReceiptPage(sale: sale)),
//             ),
//             onEdit: sale.status == 'refunded' ? null : () => _editSale(sale),
//             onDelete: () => _confirmRefund(i),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _confirmRefund(int index) async {
//     final reasonCtrl = TextEditingController(text: 'Customer refund');
//     final reason = await showDialog<String>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Refund Sale?'),
//         content: TextField(
//           controller: reasonCtrl,
//           decoration: AppInput.dialog('Refund reason'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
//             child: const Text('Refund', style: TextStyle(color: kRed)),
//           ),
//         ],
//       ),
//     );
//     reasonCtrl.dispose();
//     if (reason != null && reason.isNotEmpty && mounted) {
//       final sale = _sales[index];
//       await SaleOperationsService.refundSale(sale, reason: reason);
//       _load();
//     }
//   }

//   Future<void> _editSale(SaleModel sale) async {
//     final customerCtrl = TextEditingController(text: sale.customerName);
//     final paidCtrl = TextEditingController(text: sale.amountPaid.toString());
//     final notesCtrl = TextEditingController(text: sale.notes);
//     final reasonCtrl = TextEditingController(text: 'Sale correction');
//     final edited = await showDialog<SaleModel>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Edit Sale'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: customerCtrl,
//                 decoration: AppInput.dialog('Customer name'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: paidCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: AppInput.dialog('Amount paid'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: notesCtrl,
//                 maxLines: 2,
//                 decoration: AppInput.dialog('Notes'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: reasonCtrl,
//                 decoration: AppInput.dialog('Edit reason'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               final amountPaid =
//                   double.tryParse(paidCtrl.text.trim()) ?? sale.amountPaid;
//               Navigator.pop(
//                 context,
//                 sale.copyWith(
//                   customerName: customerCtrl.text.trim().isEmpty
//                       ? 'Walk-in'
//                       : customerCtrl.text.trim(),
//                   amountPaid: amountPaid,
//                   change: amountPaid > sale.total ? amountPaid - sale.total : 0,
//                   notes: notesCtrl.text.trim(),
//                 ),
//               );
//             },
//             child: const Text('Save', style: TextStyle(color: kRed)),
//           ),
//         ],
//       ),
//     );
//     final reason = reasonCtrl.text.trim().isEmpty
//         ? 'Sale correction'
//         : reasonCtrl.text.trim();
//     customerCtrl.dispose();
//     paidCtrl.dispose();
//     notesCtrl.dispose();
//     reasonCtrl.dispose();
//     if (edited == null || !mounted) return;
//     await SaleOperationsService.editSale(
//       original: sale,
//       edited: edited,
//       reason: reason,
//     );
//     await _load();
//   }
// }
