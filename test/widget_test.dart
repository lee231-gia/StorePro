import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/app.dart';
import 'package:storepro/core/theme/theme_provider.dart';

void main() {
  testWidgets('StorePro app widget can be constructed', (tester) async {
    final provider = ThemeProvider();
    expect(StorePro(themeProvider: provider), isA<StorePro>());
  });
}
