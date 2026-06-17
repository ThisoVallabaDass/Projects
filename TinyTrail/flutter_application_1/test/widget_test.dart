import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytrail_flutter/src/shared.dart';

void main() {
  testWidgets('firebase setup screen renders guidance text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FirebaseSetupScreen(),
      ),
    );

    expect(find.text('Firebase setup needed'), findsOneWidget);
    expect(find.textContaining('Create a Firebase project.'), findsOneWidget);
  });
}
