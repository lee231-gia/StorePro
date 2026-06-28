import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/core/utils/session.dart';
import 'package:storepro/widgets/app_drawer.dart';

void main() {
  setUp(() {
    Session.clear();
  });

  Widget buildDrawer({int currentIndex = 0}) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test')),
        drawer: AppDrawer(
          changeTab: (index) {},
          currentIndex: currentIndex,
        ),
        body: const Text('Home'),
      ),
    );
  }

  group('AppDrawer', () {
    testWidgets('displays STOREPRO header with store name', (tester) async {
      Session.storeName = 'Juan\'s Sari-Sari Store';
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('STOREPRO'), findsOneWidget);
      expect(find.text('Juan\'s Sari-Sari Store'), findsOneWidget);
    });

    testWidgets('renders first 6 navigation items (visible without scroll)', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Expiry'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Utang'), findsOneWidget);
    });

    testWidgets('renders Settings link (scrolled into view)', (tester) async {
      await tester.pumpWidget(buildDrawer());
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Drawer), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('highlights active tab', (tester) async {
      await tester.pumpWidget(buildDrawer(currentIndex: 4));
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      final salesTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Sales'));
      expect(salesTile.tileColor, isNotNull);
    });
  });
}
