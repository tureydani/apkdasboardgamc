import 'package:flutter_test/flutter_test.dart';

import 'package:sosapk/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SosApp());
    expect(find.byType(SosApp), findsOneWidget);
  });
}
