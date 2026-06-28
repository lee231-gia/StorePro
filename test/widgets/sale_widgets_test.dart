import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/widgets/sale_widgets.dart';
import 'package:storepro/models/sale_model.dart';

void main() {
  group('CartItem', () {
    test('key combines productId, variantId, and conditionName', () {
      final item = CartItem(
        productId: 'p-1',
        variantId: 'v-1',
        productName: 'Coke',
        variantName: '1.5L',
        conditionName: 'Cold',
        price: 65.0,
      );
      expect(item.key, equals('p-1|v-1|Cold'));
    });

    test('key handles empty conditionName', () {
      final item = CartItem(
        productId: 'p-1', variantId: 'v-1',
        productName: 'Coke', variantName: '1.5L',
        price: 65.0,
      );
      expect(item.key, equals('p-1|v-1|'));
    });

    test('subtotal computes price * qty minus discount', () {
      final item = CartItem(
        productId: 'p-1', variantId: 'v-1',
        productName: 'Coke', variantName: '1.5L',
        price: 65.0, qty: 3, itemDiscount: 15.0,
      );
      expect(item.subtotal, equals(180.0));
    });

    test('subtotal clamps to 0 minimum', () {
      final item = CartItem(
        productId: 'p-1', variantId: 'v-1',
        productName: 'Coke', variantName: '1.5L',
        price: 10.0, qty: 1, itemDiscount: 100.0,
      );
      expect(item.subtotal, equals(0.0));
    });

    test('profit computes (price - costPrice) * qty - discount', () {
      final item = CartItem(
        productId: 'p-1', variantId: 'v-1',
        productName: 'Coke', variantName: '1.5L',
        price: 65.0, qty: 3, costPrice: 52.0, itemDiscount: 15.0,
      );
      expect(item.profit, equals((65 - 52) * 3 - 15));
    });

    test('fields are mutable', () {
      final item = CartItem(
        productId: 'p-1', variantId: 'v-1',
        productName: 'Coke', variantName: '1.5L',
        price: 65.0, qty: 1, itemDiscount: 0.0,
      );
      item.price = 70.0;
      item.qty = 5;
      item.itemDiscount = 20.0;
      expect(item.price, equals(70.0));
      expect(item.qty, equals(5));
      expect(item.itemDiscount, equals(20.0));
      expect(item.subtotal, equals(70.0 * 5 - 20));
    });
  });

  group('SalesTabButton', () {
    Widget buildTab(String label, {bool isActive = false, VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SalesTabButton(label: label, isActive: isActive, onTap: onTap ?? () {}),
            ],
          ),
        ),
      );
    }

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildTab('New Sale'));
      expect(find.text('New Sale'), findsOneWidget);
    });

    testWidgets('active state applies white text and bold', (tester) async {
      await tester.pumpWidget(buildTab('History', isActive: true));
      final text = tester.widget<Text>(find.text('History'));
      expect(text.style?.color, equals(Colors.white));
      expect(text.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('inactive state applies dimmed text', (tester) async {
      await tester.pumpWidget(buildTab('History', isActive: false));
      final text = tester.widget<Text>(find.text('History'));
      expect(text.style?.color, equals(Colors.white60));
    });

    testWidgets('triggers onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTab('Sales', onTap: () => tapped = true));
      await tester.tap(find.text('Sales'));
      expect(tapped, isTrue);
    });
  });

  group('SalesHistoryCard', () {
    SaleModel _sampleSale({
      String status = 'completed',
      bool hasEditHistory = false,
    }) {
      return SaleModel(
        id: 'sale-1',
        storeId: 'store-1',
        customerName: 'Juan dela Cruz',
        items: [
          SaleItemModel(
            productId: 'p-1', productName: 'Coca-Cola',
            variantId: 'v-1', variantName: '1.5L',
            qty: 2, price: 65.0, costPrice: 52.0,
          ),
          SaleItemModel(
            productId: 'p-2', productName: 'Skyflakes',
            variantId: 'v-2', variantName: '200g',
            qty: 1, price: 25.0, costPrice: 20.0,
            discount: 5.0,
          ),
        ],
        subtotal: 155.0,
        totalDiscount: 5.0,
        total: 150.0,
        amountPaid: 150.0,
        paymentType: 'cash',
        status: status,
        date: '2026-06-28',
        timestamp: '2026-06-28T10:30:00',
        updatedAt: '2026-06-28T10:30:00',
        editHistory: hasEditHistory ? [{'at': '2026-06-28T11:00:00', 'employee': 'Cashier'}] : [],
      );
    }

    Widget buildCard(SaleModel sale, {
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onRefund,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SalesHistoryCard(
              sale: sale,
              onTap: onTap ?? () {},
              onEdit: onEdit,
              onRefund: onRefund,
              onDelete: onDelete ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('displays customer name and total', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale()));
      expect(find.text('Juan dela Cruz'), findsOneWidget);
      expect(find.text('₱150.00'), findsOneWidget);
    });

    testWidgets('displays sale date formatted', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale()));
      expect(find.textContaining('Jun 28, 2026'), findsOneWidget);
    });

    testWidgets('shows status badge as completed', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale(status: 'completed')));
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('shows status badge as refunded', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale(status: 'refunded')));
      expect(find.text('REFUNDED'), findsOneWidget);
    });

    testWidgets('lists items with variant, qty, price', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale()));
      expect(find.textContaining('Coca-Cola'), findsOneWidget);
      expect(find.textContaining('1.5L'), findsOneWidget);
      expect(find.textContaining('x 2'), findsOneWidget);
      expect(find.textContaining('@ ₱65.00'), findsOneWidget);
      expect(find.textContaining('Skyflakes'), findsOneWidget);
    });

    testWidgets('shows discount line for discounted items', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale()));
      expect(find.textContaining('Discount'), findsOneWidget);
      expect(find.textContaining('-₱5.00'), findsOneWidget);
    });

    testWidgets('shows edit history badge when present', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale(hasEditHistory: true)));
      expect(find.text('1 change'), findsOneWidget);
    });

    testWidgets('shows items subtotals', (tester) async {
      await tester.pumpWidget(buildCard(_sampleSale()));
      expect(find.text('₱130.00'), findsOneWidget);
      expect(find.text('₱20.00'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCard(_sampleSale(), onTap: () => tapped = true));
      await tester.tap(find.text('Juan dela Cruz'));
      expect(tapped, isTrue);
    });
  });
}
