import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_assistant/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Helper: create provider and wait for async _loadSettings to complete
  Future<SettingsProvider> makeProvider() async {
    final p = SettingsProvider();
    await Future<void>.delayed(Duration.zero);
    return p;
  }

  group('SettingsProvider', () {
    // ── Initial / loaded defaults ─────────────────────────────────────────
    group('Initial defaults (empty prefs)', () {
      test('themeMode defaults to system', () async {
        final p = await makeProvider();
        expect(p.themeMode, ThemeMode.system);
      });

      test('locale defaults to Turkish', () async {
        final p = await makeProvider();
        expect(p.locale.languageCode, 'tr');
      });

      test('userName is null initially', () async {
        final p = await makeProvider();
        expect(p.userName, isNull);
      });

      test('hasAskedForName is false initially', () async {
        final p = await makeProvider();
        expect(p.hasAskedForName, false);
      });

      test('lastConversationId is null initially', () async {
        final p = await makeProvider();
        expect(p.lastConversationId, isNull);
      });

      test('isLoaded is true after init', () async {
        final p = await makeProvider();
        expect(p.isLoaded, true);
      });
    });

    // ── Loads persisted values ─────────────────────────────────────────────
    group('Loads persisted values from prefs', () {
      test('loads saved theme mode', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': ThemeMode.dark.index,
        });
        final p = await makeProvider();
        expect(p.themeMode, ThemeMode.dark);
      });

      test('loads saved locale', () async {
        SharedPreferences.setMockInitialValues({'locale': 'en'});
        final p = await makeProvider();
        expect(p.locale.languageCode, 'en');
      });

      test('loads saved user name', () async {
        SharedPreferences.setMockInitialValues({'user_name': 'Ahmet'});
        final p = await makeProvider();
        expect(p.userName, 'Ahmet');
      });

      test('loads saved hasAskedForName = true', () async {
        SharedPreferences.setMockInitialValues({'has_asked_for_name': true});
        final p = await makeProvider();
        expect(p.hasAskedForName, true);
      });

      test('loads saved last conversation id', () async {
        SharedPreferences.setMockInitialValues({
          'last_conversation_id': 'conv-123',
        });
        final p = await makeProvider();
        expect(p.lastConversationId, 'conv-123');
      });

      test('corrupted theme_mode index clamped to valid range', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': 999, // out of range
        });
        final p = await makeProvider();
        // Should not throw; value clamped to valid ThemeMode
        expect(ThemeMode.values.contains(p.themeMode), true);
      });
    });

    // ── setThemeMode ──────────────────────────────────────────────────────
    group('setThemeMode()', () {
      test('updates themeMode in memory', () async {
        final p = await makeProvider();
        await p.setThemeMode(ThemeMode.dark);
        expect(p.themeMode, ThemeMode.dark);
      });

      test('persists themeMode to prefs', () async {
        final p = await makeProvider();
        await p.setThemeMode(ThemeMode.light);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
      });

      test('can set all ThemeMode values', () async {
        final p = await makeProvider();
        for (final mode in ThemeMode.values) {
          await p.setThemeMode(mode);
          expect(p.themeMode, mode);
        }
      });
    });

    // ── setLocale ─────────────────────────────────────────────────────────
    group('setLocale()', () {
      test('updates locale in memory', () async {
        final p = await makeProvider();
        await p.setLocale(const Locale('en', ''));
        expect(p.locale.languageCode, 'en');
      });

      test('persists locale to prefs', () async {
        final p = await makeProvider();
        await p.setLocale(const Locale('en', ''));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('locale'), 'en');
      });

      test('switching back to Turkish works', () async {
        final p = await makeProvider();
        await p.setLocale(const Locale('en', ''));
        await p.setLocale(const Locale('tr', ''));
        expect(p.locale.languageCode, 'tr');
      });
    });

    // ── setUserName ───────────────────────────────────────────────────────
    group('setUserName()', () {
      test('updates userName in memory', () async {
        final p = await makeProvider();
        await p.setUserName('Zeynep');
        expect(p.userName, 'Zeynep');
      });

      test('sets hasAskedForName = true automatically', () async {
        final p = await makeProvider();
        expect(p.hasAskedForName, false);
        await p.setUserName('Zeynep');
        expect(p.hasAskedForName, true);
      });

      test('persists userName to prefs', () async {
        final p = await makeProvider();
        await p.setUserName('Ali');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_name'), 'Ali');
      });

      test('persists hasAskedForName = true to prefs', () async {
        final p = await makeProvider();
        await p.setUserName('Ali');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_asked_for_name'), true);
      });
    });

    // ── setHasAskedForName ────────────────────────────────────────────────
    group('setHasAskedForName()', () {
      test('updates flag in memory', () async {
        final p = await makeProvider();
        await p.setHasAskedForName(true);
        expect(p.hasAskedForName, true);
      });

      test('can reset flag to false', () async {
        final p = await makeProvider();
        await p.setHasAskedForName(true);
        await p.setHasAskedForName(false);
        expect(p.hasAskedForName, false);
      });

      test('persists to prefs', () async {
        final p = await makeProvider();
        await p.setHasAskedForName(true);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_asked_for_name'), true);
      });
    });

    // ── setLastConversationId ─────────────────────────────────────────────
    group('setLastConversationId()', () {
      test('sets conversation id in memory', () async {
        final p = await makeProvider();
        await p.setLastConversationId('conv-abc');
        expect(p.lastConversationId, 'conv-abc');
      });

      test('persists to prefs', () async {
        final p = await makeProvider();
        await p.setLastConversationId('conv-abc');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_conversation_id'), 'conv-abc');
      });

      test('setting null removes from prefs', () async {
        final p = await makeProvider();
        await p.setLastConversationId('conv-abc');
        await p.setLastConversationId(null);
        expect(p.lastConversationId, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_conversation_id'), isNull);
      });
    });

    // ── getThemeModeLabel ─────────────────────────────────────────────────
    group('getThemeModeLabel()', () {
      test('Turkish labels are correct', () async {
        final p = await makeProvider();
        expect(p.getThemeModeLabel(ThemeMode.system, true), 'Sistem');
        expect(p.getThemeModeLabel(ThemeMode.light, true), 'Aydınlık');
        expect(p.getThemeModeLabel(ThemeMode.dark, true), 'Karanlık');
      });

      test('English labels are correct', () async {
        final p = await makeProvider();
        expect(p.getThemeModeLabel(ThemeMode.system, false), 'System');
        expect(p.getThemeModeLabel(ThemeMode.light, false), 'Light');
        expect(p.getThemeModeLabel(ThemeMode.dark, false), 'Dark');
      });
    });
  });
}
