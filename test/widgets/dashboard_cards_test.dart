import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/widgets/dashboard_cards.dart';

void main() {
  group('DashboardWelcomeCard', () {
    testWidgets('displays first name and store name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DashboardWelcomeCard(firstName: 'Juan', storeName: 'Juan\'s Store'))),
      );
      expect(find.text('~WELCOME~'), findsOneWidget);
      expect(find.text('Hello, Juan'), findsOneWidget);
      expect(find.text('Juan\'s Store'), findsOneWidget);
    });
  });

  group('DashboardOverviewCard', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Row(children: [child])));

    testWidgets('displays value, label, and icon', (tester) async {
      await tester.pumpWidget(wrap(
        DashboardOverviewCard(
          value: '₱12,500',
          label: 'Today\'s Revenue',
          icon: Icons.trending_up,
          onTap: () {},
        ),
      ));
      expect(find.text('₱12,500'), findsOneWidget);
      expect(find.text('Today\'s Revenue'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('applies custom value color', (tester) async {
      await tester.pumpWidget(wrap(
        DashboardOverviewCard(
          value: '₱0',
          label: 'Profit',
          icon: Icons.monetization_on,
          onTap: () {},
          valueColor: Colors.red,
        ),
      ));
      expect(find.text('₱0'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrap(
        DashboardOverviewCard(
          value: '50', label: 'Products', icon: Icons.inventory, onTap: () => tapCount++,
        ),
      ));
      await tester.tap(find.text('50'));
      expect(tapCount, equals(1));
    });
  });

  group('DashboardActionBtn', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Row(children: [child])));

    testWidgets('displays icon and label', (tester) async {
      await tester.pumpWidget(wrap(
        DashboardActionBtn(icon: Icons.add, label: 'New Sale', onTap: () {}),
      ));
      expect(find.text('New Sale'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(wrap(
        DashboardActionBtn(icon: Icons.add, label: 'New Sale', onTap: () => tapCount++),
      ));
      await tester.tap(find.text('New Sale'));
      expect(tapCount, equals(1));
    });
  });

  group('DashboardExpiryRow', () {
    testWidgets('displays product name and expiry date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardExpiryRow(
              item: {
                'productName': 'Coca-Cola',
                'variantName': '1L',
                'expiry': '2026-07-15',
                'status': 'good',
              },
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Coca-Cola'), findsOneWidget);
      expect(find.textContaining('1L'), findsOneWidget);
      expect(find.textContaining('Jul 15, 2026'), findsOneWidget);
    });

    testWidgets('shows EXPIRED badge when status is expired', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardExpiryRow(
              item: {
                'productName': 'Milk',
                'variantName': '1L',
                'expiry': '2025-01-01',
                'status': 'expired',
              },
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('EXPIRED'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardExpiryRow(
              item: {'productName': 'Test', 'variantName': 'V', 'expiry': '2026-07-01', 'status': 'good'},
              onTap: () => tapCount++,
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('Test'));
      expect(tapCount, equals(1));
    });
  });

  group('DashboardLowStockRow', () {
    testWidgets('displays product name, variant, and stock', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardLowStockRow(
              item: {'productName': 'Mountain Dew', 'variantName': '1L', 'stock': 5},
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Mountain Dew'), findsOneWidget);
      expect(find.textContaining('1L'), findsOneWidget);
      expect(find.text('5 pcs'), findsOneWidget);
    });

    testWidgets('shows "No Stock" when stock is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardLowStockRow(
              item: {'productName': 'Piatos', 'variantName': 'Regular', 'stock': 0},
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('No Stock'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardLowStockRow(
              item: {'productName': 'Test', 'variantName': 'V', 'stock': 3},
              onTap: () => tapCount++,
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('Test'));
      expect(tapCount, equals(1));
    });
  });

  group('DashboardActivityRow', () {
    Finder richTextContaining(String text) => find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText().contains(text),
    );

    testWidgets('displays action text and employee name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardActivityRow(log: {
              'action': 'new_sale',
              'employeeName': 'Maria Santos',
              'targetName': 'Sale #001',
              'timestamp': '2026-06-15T14:30:00',
            }),
          ),
        ),
      );
      expect(richTextContaining('Maria Santos'), findsOneWidget);
      expect(richTextContaining('new sale'), findsOneWidget);
      expect(richTextContaining('Sale #001'), findsOneWidget);
    });

    testWidgets('handles missing fields gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardActivityRow(log: {
              'timestamp': '2026-06-15T14:30:00',
            }),
          ),
        ),
      );
      expect(richTextContaining('System'), findsOneWidget);
    });
  });
}
