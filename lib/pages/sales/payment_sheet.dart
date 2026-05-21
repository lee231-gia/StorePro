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
  final customerFocus = FocusNode();
  String paymentError = '';
  final selectedCustomer = customers.where(
    (customer) =>
        customer.name.toLowerCase() == customerCtrl.text.trim().toLowerCase(),
  );
  if (selectedCustomer.isNotEmpty) {
    cPhoneCtrl.text = selectedCustomer.first.phone;
    cAddrCtrl.text = selectedCustomer.first.address;
  }
  double change = 0.0;
  var submitting = false;
  Map<String, Object?>? pendingPayment;

  final sheet = showModalBottomSheet(
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
                          onTap: () => setP(() {
                            payType = t;
                            paymentError = '';
                          }),
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
                  decoration: AppInput.field('0.00'),
                  onChanged: (v) {
                    final paid = double.tryParse(v) ?? 0;
                    setP(() {
                      change = paid - total;
                      paymentError = '';
                    });
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
                if (paymentError.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    paymentError,
                    style: const TextStyle(
                      color: kRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                  focusNode: customerFocus,
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
                label: submitting ? 'Saving Payment...' : 'Confirm Payment',
                isLoading: submitting,
                onTap: submitting
                    ? null
                    : () {
                        final paid = payType == 'utang'
                            ? 0.0
                            : (double.tryParse(cashCtrl.text) ?? 0.0);
                        if (payType == 'cash' && paid < total) {
                          setP(() {
                            paymentError =
                                'Amount received must be at least the grand total.';
                          });
                          return;
                        }
                        if (payType == 'multi' && paid <= 0) {
                          setP(() {
                            paymentError = 'Enter the amount received.';
                          });
                          return;
                        }
                        if ((payType == 'utang' || payType == 'multi') &&
                            customerCtrl.text.trim().isEmpty) {
                          setP(() {
                            paymentError =
                                'Customer name is required for utang.';
                          });
                          return;
                        }
                        final customerName = customerCtrl.text.trim();
                        pendingPayment = {
                          'paymentType': payType,
                          'amountPaid': paid,
                          'change': change < 0 ? 0.0 : change,
                          'customerId': '',
                          'customerName': customerName,
                          'customerPhone': cPhoneCtrl.text.trim(),
                          'customerAddress': cAddrCtrl.text.trim(),
                        };
                        setP(() => submitting = true);
                        Navigator.pop(ctx);
                      },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
  sheet.whenComplete(() {
    final payment = pendingPayment;
    cashCtrl.dispose();
    cPhoneCtrl.dispose();
    cAddrCtrl.dispose();
    customerFocus.dispose();
    if (payment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        customerCtrl.text = (payment['customerName'] as String?) ?? '';
        onPay(
          paymentType: payment['paymentType'] as String,
          amountPaid: payment['amountPaid'] as double,
          change: payment['change'] as double,
          customerId: payment['customerId'] as String,
          customerPhone: payment['customerPhone'] as String,
          customerAddress: payment['customerAddress'] as String,
        );
      });
    }
  });
}

// Extension for capitalize
extension StringExt on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
