import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/app.dart';

void main() {
  testWidgets('StorePro app widget can be constructed', (tester) async {
    expect(const StorePro(), isA<StorePro>());
  });
}
