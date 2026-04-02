import 'package:flutter_test/flutter_test.dart';

import 'package:visabrru/app.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PoemsApp());
    await tester.pump();

    expect(find.text('Visabrru'), findsWidgets);
  });
}
