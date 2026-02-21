import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('renders amplify auth sample shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Amplify Gen 2 Auth Sample'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
