import 'package:flutter_test/flutter_test.dart';
import 'package:cyberfly_mobile_node/main.dart';
import 'package:cyberfly_mobile_node/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberflyNodeApp());
    await tester.pumpAndSettle();
    // Basic check that app launched
    expect(find.byType(CyberflyNodeApp), findsOneWidget);
  });
}
