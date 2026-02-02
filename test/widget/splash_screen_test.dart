import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_assistant/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders correctly', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Verify that the title text is found
    expect(find.text('PulseAssist'), findsOneWidget);

    // Verify that the loading indicator is found
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify that the loading indicator is found
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Dispose the widget to prevent navigation logic from running when the timer completes
    await tester.pumpWidget(const SizedBox());

    // Fast-forward time to let the pending timer invoke its callback (which will see !mounted and return)
    await tester.pump(const Duration(seconds: 2));
  });
}
