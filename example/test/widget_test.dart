import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Marktag Example'), findsWidgets);
    expect(find.text('Log Login'), findsOneWidget);
  });
}
