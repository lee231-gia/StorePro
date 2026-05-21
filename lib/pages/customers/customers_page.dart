import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/customer_model.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/sale_repository.dart';
import '../../repositories/utang_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';

class CustomersPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const CustomersPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<CustomerModel> _customers = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    var list = _customers;
    try {
      // Instant SQLite
      list = await CustomerRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <CustomerModel>[],
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _customers = list;
        _loading = false;
      });
    }

    // Background sync
    CustomerRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _customers = fresh);
    });
  }

  List<CustomerModel> get _filtered {
    if (_search.isEmpty) return _customers;
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(_search.toLowerCase()) ||
              c.phone.contains(_search),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(title: 'Customers', context: context),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'customers_add_fab',
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: AppInput.field(
                'Search customers...',
                icon: Icons.search,
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} customer'
                '${_filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // List
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No customers yet.',
                      style: TextStyle(color: kGrey),
                    ),
                  )
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _customerCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── CUSTOMER CARD ─────────────────────────────────────────
  Widget _customerCard(CustomerModel c) {
    return GestureDetector(
      onTap: () => _showDetail(c),
      onLongPress: () => _showForm(existing: c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            // Avatar circle with first letter
            CircleAvatar(
              radius: 22,
              backgroundColor: kRedLight,
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: kRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kDark,
                    ),
                  ),
                  if (c.phone.isNotEmpty)
                    Text(
                      c.phone,
                      style: const TextStyle(color: kGrey, fontSize: 12),
                    ),
                  if (c.address.isNotEmpty)
                    Text(
                      c.address,
                      style: const TextStyle(color: kGrey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppHelpers.peso(c.totalPurchases),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: kRed,
                  ),
                ),
                const Text(
                  'total purchases',
                  style: TextStyle(fontSize: 10, color: kGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── DETAIL SHEET ──────────────────────────────────────────
  void _showDetail(CustomerModel c) async {
    final sales = await SaleRepository.getAll();
    final utangs = await UtangRepository.getAll();

    // Filter by customer
    final custSales = sales
        .where((s) => s.customerId == c.id || s.customerName == c.name)
        .toList();
    final custUtangs = utangs.where((u) => u.customerId == c.id).toList();
    final openDebt = custUtangs.fold(0.0, (s, u) => s + u.balance);

    if (!mounted) return;

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
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: kRedLight,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: kRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: kDark,
                              ),
                            ),
                            if (c.phone.isNotEmpty)
                              Text(
                                c.phone,
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: kGrey),
                        onPressed: () {
                          Navigator.pop(context);
                          _showForm(existing: c);
                        },
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: kRed),
                        onPressed: () => _confirmDelete(c),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info table (Kotatsu style)
                  appCard(
                    child: Column(
                      children: [
                        infoRow(
                          'Total Purchases',
                          AppHelpers.peso(c.totalPurchases),
                          icon: Icons.shopping_bag_outlined,
                        ),
                        const Divider(height: 1),
                        infoRow(
                          'Open Debt',
                          AppHelpers.peso(openDebt),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const Divider(height: 1),
                        infoRow(
                          'Transactions',
                          '${custSales.length}',
                          icon: Icons.receipt_long_outlined,
                        ),
                        if (c.address.isNotEmpty) ...[
                          const Divider(height: 1),
                          infoRow(
                            'Address',
                            c.address,
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                        if (c.notes.isNotEmpty) ...[
                          const Divider(height: 1),
                          infoRow('Notes', c.notes, icon: Icons.note_outlined),
                        ],
                      ],
                    ),
                  ),

                  // Purchase history
                  if (custSales.isNotEmpty) ...[
                    const Text(
                      'Purchase History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...custSales
                        .take(10)
                        .map(
                          (s) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppHelpers.formatDate(s.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      AppHelpers.peso(s.total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: kRed,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...s.items
                                    .take(4)
                                    .map(
                                      (i) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${i.productName} - ${i.variantName}'
                                                '${i.conditionName.isNotEmpty ? ' / ${i.conditionName}' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: kDark,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'x${i.qty} @ ${AppHelpers.peso(i.price)}',
                                              style: const TextStyle(
                                                color: kGrey,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                if (s.items.length > 4)
                                  Text(
                                    '+${s.items.length - 4} more item'
                                    '${s.items.length - 4 == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: kGrey,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

  // ── ADD / EDIT FORM ───────────────────────────────────────
  void _showForm({CustomerModel? existing}) {
    final isEdit = existing != null;
    final namCtrl = TextEditingController(text: existing?.name ?? '');
    final phCtrl = TextEditingController(text: existing?.phone ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final notCtrl = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Customer' : 'Add Customer',
          style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fld(namCtrl, 'Name *', Icons.person_outline),
              const SizedBox(height: 10),
              _fld(
                phCtrl,
                'Phone',
                Icons.phone_outlined,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _fld(addrCtrl, 'Address', Icons.location_on_outlined),
              const SizedBox(height: 10),
              TextField(
                controller: notCtrl,
                maxLines: 3,
                decoration: AppInput.dialog('Notes (optional)'),
              ),
              if (isEdit) ...[
                const SizedBox(height: 10),
                _formInfoRow(
                  label: 'Created',
                  value: _formatMaybeDateTime(existing.createdAt),
                ),
                const SizedBox(height: 8),
                _formInfoRow(
                  label: 'Modified',
                  value: _formatMaybeDateTime(existing.updatedAt),
                ),
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
              if (namCtrl.text.trim().isEmpty) return;
              await CustomerRepository.save(
                CustomerModel(
                  id: existing?.id ?? '',
                  storeId: '',
                  name: namCtrl.text.trim(),
                  phone: phCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  notes: notCtrl.text.trim(),
                  totalPurchases: existing?.totalPurchases ?? 0.0,
                  createdAt: existing?.createdAt ?? '',
                  updatedAt: AppHelpers.nowStr(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    Navigator.pop(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Remove "${c.name}"? This cannot be undone.'),
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
      await CustomerRepository.delete(c.id);
      _load();
    }
  }

  Widget _fld(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: type,
    decoration: AppInput.dialog(hint),
  );

  Widget _formInfoRow({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kInputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kGrey, fontSize: 10)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMaybeDateTime(String value) {
    final dt = DateTime.tryParse(value);
    if (dt == null) return value.isEmpty ? 'Not recorded' : value;
    return AppHelpers.formatDateTime(dt);
  }
}
