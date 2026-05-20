part of 'sales_sheets.dart';

void showPaymentSheet({
  required BuildContext context,
  required double total,
  required TextEditingController customerCtrl,
  List<CustomerModel> customers = const [],
  required void Function({
    required String paymentType,
    required double amountPaid,
    required double change,
    required String customerId,
    required String customerPhone,
    required String customerAddress,
  })
  onPay,
}) {
  String payType = 'cash';
  final cashCtrl = TextEditingController();
  final cPhoneCtrl = TextEditingController();
  final cAddrCtrl = TextEditingController();
  final selectedCustomer = customers.where(
    (customer) =>
        customer.name.toLowerCase() == customerCtrl.text.trim().toLowerCase(),
  );
  if (selectedCustomer.isNotEmpty) {
    cPhoneCtrl.text = selectedCustomer.first.phone;
    cAddrCtrl.text = selectedCustomer.first.address;
  }
  double change = 0.0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (ctx, setP) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const Text(
                'Payment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${AppHelpers.peso(total)}',
                style: const TextStyle(
                  color: kRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // Payment type buttons
              Row(
                children: [
                  for (final t in ['cash', 'utang', 'multi'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setP(() => payType = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: payType == t ? kRed : kInputFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t == 'multi' ? 'Multi' : t.capitalize(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: payType == t ? Colors.white : kGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              if (payType == 'cash' || payType == 'multi') ...[
                fieldLabel('Amount Received'),
                TextField(
                  controller: cashCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: AppInput.field(
                    '0.00',
                  ),
                  onChanged: (v) {
                    final paid = double.tryParse(v) ?? 0;
                    setP(() => change = paid - total);
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: change >= 0
                        ? kGreen.withValues(alpha: 0.1)
                        : kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        AppHelpers.peso(change < 0 ? 0 : change),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: change >= 0 ? kGreen : kRed,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Customer info for utang
              if (payType == 'utang' || payType == 'multi') ...[
                const SizedBox(height: 12),
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 8),
                _customerSelector(
                  controller: customerCtrl,
                  customers: customers,
                  hint: 'Customer name *',
                  phoneController: cPhoneCtrl,
                  addressController: cAddrCtrl,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cPhoneCtrl,
                  decoration: AppInput.field(
                    'Phone (optional)',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cAddrCtrl,
                  decoration: AppInput.field(
                    'Address (optional)',
                    icon: Icons.location_on_outlined,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              PrimaryButton(
                label: 'Confirm Payment',
                onTap: () {
                  if ((payType == 'utang' || payType == 'multi') &&
                      customerCtrl.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  final paid = payType == 'utang'
                      ? 0.0
                      : (double.tryParse(cashCtrl.text) ?? total);
                  onPay(
                    paymentType: payType,
                    amountPaid: paid,
                    change: change < 0 ? 0 : change,
                    customerId: '',
                    customerPhone: cPhoneCtrl.text.trim(),
                    customerAddress: cAddrCtrl.text.trim(),
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

// Extension for capitalize
extension StringExt on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
