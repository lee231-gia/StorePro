import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../models/utang_model.dart';
import '../../repositories/utang_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';

class UtangPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const UtangPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<UtangPage> createState() => _UtangPageState();
}

class _UtangPageState extends State<UtangPage> {
  List<UtangModel> _utangs = [];
  bool _loading = true;
  String _filter = 'all'; // all|pending|partial|paid

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    var list = _utangs;
    try {
      // Instant SQLite
      list = await UtangRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <UtangModel>[],
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _utangs = list;
        _loading = false;
      });
    }

    // Background sync
    UtangRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _utangs = fresh);
    });
  }

  List<UtangModel> get _filtered {
    if (_filter == 'all') return _utangs;
    return _utangs.where((u) => u.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalUnpaid = _utangs.fold(0.0, (s, u) => s + u.balance);

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(title: 'Utang (Debt)', context: context),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'utang_add_fab',
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        onPressed: () => _showUtangForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          // ── SUMMARY CARD ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kRed, kRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Unpaid Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    AppHelpers.peso(totalUnpaid),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    '${_utangs.where((u) => u.status != 'paid').length}'
                    ' active debt'
                    '${_utangs.where((u) => u.status != 'paid').length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // ── FILTER CHIPS ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['all', 'pending', 'partial', 'paid'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _filter == f ? kRed : kCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _filter == f ? kRed : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: TextStyle(
                              color: _filter == f ? Colors.white : kGrey,
                              fontSize: 12,
                              fontWeight: _filter == f
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── UTANG LIST ────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(color: kGrey),
                    ),
                  )
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _utangCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── UTANG CARD ────────────────────────────────────────────
  Widget _utangCard(UtangModel u) {
    final statusColor = u.status == 'paid'
        ? kGreen
        : u.status == 'partial'
        ? kOrange
        : kRed;

    return GestureDetector(
      onTap: () => _showDetail(u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Since ${AppHelpers.formatDate(u.startDate)}'
                        '${u.dueDate.isNotEmpty ? '  ·  Due ${AppHelpers.formatDate(u.dueDate)}' : ''}',
                        style: const TextStyle(color: kGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppHelpers.peso(u.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kDark,
                      ),
                    ),
                    statusBadge(u.status.toUpperCase(), statusColor),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: u.totalAmount > 0
                    ? (u.amountPaid / u.totalAmount).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: Colors.grey.shade200,
                color: statusColor,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ${AppHelpers.peso(u.amountPaid)}',
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
                Text(
                  'Balance: ${AppHelpers.peso(u.balance)}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── DETAIL BOTTOM SHEET ───────────────────────────────────
  void _showDetail(UtangModel u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer info
                  Text(
                    u.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kDark,
                    ),
                  ),
                  if (u.customerPhone.isNotEmpty)
                    Text(
                      u.customerPhone,
                      style: const TextStyle(color: kGrey, fontSize: 13),
                    ),

                  const SizedBox(height: 12),

                  // Summary card
                  appCard(
                    color: kRedLight,
                    child: Column(
                      children: [
                        infoRow('Total', AppHelpers.peso(u.totalAmount)),
                        infoRow('Paid', AppHelpers.peso(u.amountPaid)),
                        infoRow('Balance', AppHelpers.peso(u.balance)),
                        infoRow('Status', u.status.toUpperCase()),
                        infoRow(
                          'Start Date',
                          AppHelpers.formatDate(u.startDate),
                        ),
                        if (u.dueDate.isNotEmpty)
                          infoRow('Due Date', AppHelpers.formatDate(u.dueDate)),
                      ],
                    ),
                  ),

                  // Items
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kDark),
                  ),
                  const SizedBox(height: 6),
                  ...u.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _utangItemName(item),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item['qty']} × ${AppHelpers.peso((item['price'] as num?)?.toDouble() ?? 0.0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppHelpers.peso(
                              ((item['price'] as num?)?.toDouble() ?? 0.0) *
                                  ((item['qty'] as num?)?.toInt() ?? 0),
                            ),
                            style: const TextStyle(fontSize: 13, color: kGrey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Payments history
                  if (u.payments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...u.payments.map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _paymentDateTime(p.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kDark,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              AppHelpers.peso(p.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kGreen,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showUtangForm(existing: u);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRed,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(u);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (u.status != 'paid') ...[
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Record Payment',
                      icon: Icons.payments_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        _showPaymentDialog(u);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUtangForm({UtangModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.customerName ?? '');
    final phoneCtrl = TextEditingController(
      text: existing?.customerPhone ?? '',
    );
    final totalCtrl = TextEditingController(
      text: existing?.totalAmount.toStringAsFixed(2) ?? '',
    );
    final paidCtrl = TextEditingController(
      text: existing?.amountPaid.toStringAsFixed(2) ?? '0.00',
    );
    final dueCtrl = TextEditingController(text: existing?.dueDate ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    const validStatuses = {'pending', 'partial', 'paid'};
    final existingStatus = existing?.status ?? 'pending';
    var status = validStatuses.contains(existingStatus)
        ? existingStatus
        : ((existing?.amountPaid ?? 0) > 0 ? 'partial' : 'pending');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(existing == null ? 'Add Utang' : 'Edit Utang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: AppInput.dialog('Customer name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: AppInput.dialog('Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog('Total amount *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: AppInput.dialog('Amount paid'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dueCtrl,
                  decoration: AppInput.dialog('Due date (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: AppInput.dialog('Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  ],
                  onChanged: (value) {
                    if (value != null) setD(() => status = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: AppInput.dialog('Notes'),
                ),
                const SizedBox(height: 10),
                _editIndicatorRow(
                  existing == null ? 'Date and time' : 'Date modified',
                  existing == null
                      ? AppHelpers.formatDateTime(DateTime.now())
                      : _paymentDateTime(existing.updatedAt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
                final paid = double.tryParse(paidCtrl.text.trim()) ?? 0;
                if (name.isEmpty || total <= 0) return;

                final inferredStatus = paid >= total
                    ? 'paid'
                    : paid > 0
                    ? 'partial'
                    : status;
                await UtangRepository.save(
                  UtangModel(
                    id: existing?.id ?? '',
                    storeId: Session.storeId,
                    customerId: existing?.customerId ?? '',
                    customerName: name,
                    customerPhone: phoneCtrl.text.trim(),
                    saleId: existing?.saleId ?? '',
                    items: existing?.items ?? const [],
                    totalAmount: total,
                    amountPaid: paid.clamp(0, total).toDouble(),
                    startDate: existing?.startDate ?? AppHelpers.todayStr(),
                    dueDate: dueCtrl.text.trim(),
                    status: inferredStatus,
                    payments: existing?.payments ?? const [],
                    notes: notesCtrl.text.trim(),
                    updatedAt: AppHelpers.nowStr(),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UtangModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Utang?'),
        content: Text('Remove ${u.customerName} debt record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await UtangRepository.delete(u.id);
      _load();
    }
  }

  // ── PAYMENT DIALOG ────────────────────────────────────────
  void _showPaymentDialog(UtangModel u) {
    String payMode = 'full'; // 'full' | 'partial' | 'item'
    final amtCtrl = TextEditingController(text: u.balance.toStringAsFixed(2));
    String? selectedItemKey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pay — ${u.customerName}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance: ${AppHelpers.peso(u.balance)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kRed,
                  ),
                ),
                const SizedBox(height: 12),

                // Payment mode
                const Text(
                  'Payment Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final m in ['full', 'partial', 'item'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => setD(() => payMode = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: payMode == m ? kRed : kInputFill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m[0].toUpperCase() + m.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: payMode == m ? Colors.white : kGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (payMode == 'partial') ...[
                  fieldLabel('Amount to Pay'),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppInput.dialog('0.00'),
                  ),
                ],

                if (payMode == 'item') ...[
                  const Text(
                    'Select Item to Pay Off',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...u.items.map((item) {
                    final key = '${item['variantId']}';
                    final price =
                        ((item['price'] as num?)?.toDouble() ?? 0.0) *
                        ((item['qty'] as num?)?.toInt() ?? 0);
                    return GestureDetector(
                      onTap: () => setD(() => selectedItemKey = key),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedItemKey == key ? kRedLight : kBg,
                          border: Border.all(
                            color: selectedItemKey == key
                                ? kRed
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_utangItemName(item)} ×${item['qty']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              AppHelpers.peso(price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                double payAmount = 0;
                String paidItemId = '';
                String paidItemName = '';
                int paidQty = 0;

                if (payMode == 'full') {
                  payAmount = u.balance;
                } else if (payMode == 'partial') {
                  payAmount = double.tryParse(amtCtrl.text) ?? 0;
                } else if (payMode == 'item' && selectedItemKey != null) {
                  final item = u.items.firstWhere(
                    (i) => i['variantId'] == selectedItemKey,
                    orElse: () => {},
                  );
                  if (item.isNotEmpty) {
                    paidItemId = item['variantId'] ?? '';
                    paidItemName = _utangItemName(item);
                    paidQty = (item['qty'] as num?)?.toInt() ?? 0;
                    payAmount =
                        ((item['price'] as num?)?.toDouble() ?? 0.0) * paidQty;
                  }
                }

                if (payAmount <= 0) return;

                final payment = UtangPaymentModel(
                  id: AppHelpers.newId(),
                  amount: payAmount,
                  method: payMode == 'item' ? 'item' : 'cash',
                  paidItemId: paidItemId,
                  paidItemName: paidItemName,
                  paidQty: paidQty,
                  date: AppHelpers.nowStr(),
                );

                await UtangRepository.addPayment(u, payment);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  String _utangItemName(Map<String, dynamic> item) {
    final product = '${item['productName'] ?? ''}'.trim();
    final variant = '${item['variantName'] ?? ''}'.trim();
    if (variant.isEmpty || variant == product) return product;
    return '$product - $variant';
  }

  Widget _editIndicatorRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kInputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_outlined, size: 16, color: kGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: kGrey)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _paymentDateTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return AppHelpers.formatDate(iso);
    return AppHelpers.formatDateTime(dt);
  }
}
