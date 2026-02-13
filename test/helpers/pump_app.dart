import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_assistant/l10n/app_localizations.dart';
import 'package:smart_assistant/providers/settings_provider.dart';
import 'package:smart_assistant/theme/app_theme.dart';

/// Helper function to pump a widget with all necessary providers and localizations
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<ChangeNotifierProvider>? providers,
  ThemeMode? themeMode,
  Locale? locale,
}) async {
  final settingsProvider = SettingsProvider();

  await tester.pumpWidget(
    MultiProvider(
      providers: providers ??
          [
            ChangeNotifierProvider.value(value: settingsProvider),
          ],
      child: MaterialApp(
        home: widget,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode ?? ThemeMode.light,
        locale: locale ?? const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('tr'),
        ],
      ),
    ),
  );
}

/// Helper function to pump a widget without MaterialApp wrapper
Future<void> pumpWidget(
  WidgetTester tester,
  Widget widget, {
  List<ChangeNotifierProvider>? providers,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: providers ?? [],
      child: widget,
    ),
  );
}

/// Helper to find widgets by type
Finder findWidgetByType<T>() => find.byType(T);

/// Helper to find widgets by key
Finder findWidgetByKey(Key key) => find.byKey(key);

/// Helper to find widgets by text
Finder findWidgetByText(String text) => find.text(text);

/// Helper to find widgets by icon
Finder findWidgetByIcon(IconData icon) => find.byIcon(icon);

/// Helper to tap a widget
Future<void> tapWidget(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper to enter text into a text field
Future<void> enterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper to scroll until a widget is visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Finder scrollable, {
  double delta = 100,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();
}

/// Helper to verify widget exists
void expectWidgetExists(Finder finder) {
  expect(finder, findsOneWidget);
}

/// Helper to verify widget does not exist
void expectWidgetNotExists(Finder finder) {
  expect(finder, findsNothing);
}

/// Helper to verify multiple widgets exist
void expectWidgetsExist(Finder finder, int count) {
  expect(finder, findsNWidgets(count));
}
