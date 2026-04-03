import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_flow/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MarketingFlowApp());
    expect(find.text('MarketingFlow'), findsOneWidget);
  });
}
