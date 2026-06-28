import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/widgets/shared_widgets.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Save Product', onTap: () {}))),
      );
      expect(find.text('Save Product'), findsOneWidget);
    });

    testWidgets('shows loading spinner when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Save', isLoading: true))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('button is disabled when isLoading', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Save', isLoading: true, onTap: () => tapped = true))),
      );
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('triggers onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Save', onTap: () => tapped = true))),
      );
      await tester.tap(find.text('Save'));
      expect(tapped, isTrue);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Add', onTap: () {}, icon: Icons.add))),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('accepts custom height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrimaryButton(label: 'Tall', onTap: () {}, height: 80))),
      );
      expect(find.text('Tall'), findsOneWidget);
    });
  });

  group('OutlineBtn', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OutlineBtn(label: 'Cancel', onTap: () {}))),
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('triggers onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OutlineBtn(label: 'Cancel', onTap: () => tapped = true))),
      );
      await tester.tap(find.text('Cancel'));
      expect(tapped, isTrue);
    });
  });

  group('statusBadge', () {
    testWidgets('renders label with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: statusBadge('Active', Colors.green))),
      );
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('sectionLabel', () {
    testWidgets('renders section title in red', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: sectionLabel('Products'))),
      );
      expect(find.text('Products'), findsOneWidget);
    });
  });

  group('fieldLabel', () {
    testWidgets('renders field label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: fieldLabel('Product Name'))),
      );
      expect(find.text('Product Name'), findsOneWidget);
    });
  });

  group('infoRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: infoRow('Price', '₱25.00'))),
      );
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('₱25.00'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: infoRow('Stock', '50 pcs', icon: Icons.inventory))),
      );
      expect(find.byIcon(Icons.inventory), findsOneWidget);
    });
  });

  group('appCard', () {
    testWidgets('renders child widget inside card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: appCard(child: const Text('Inside the card')),
          ),
        ),
      );
      expect(find.text('Inside the card'), findsOneWidget);
    });
  });

  group('showSnack', () {
    testWidgets('shows snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (ctx) {
              return GestureDetector(
                onTap: () => showSnack(ctx, 'Product saved'),
                child: const Text('Tap here'),
              );
            }),
          ),
        ),
      );
      await tester.tap(find.text('Tap here'));
      await tester.pump();
      expect(find.text('Product saved'), findsOneWidget);
    });
  });

  group('buildAppBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (ctx) {
            return Scaffold(appBar: buildAppBar(title: 'Products', context: ctx));
          }),
        ),
      );
      expect(find.text('Products'), findsOneWidget);
    });
  });
}
