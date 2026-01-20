import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _userNameKey = 'user_name';
  static const String _localeKey = 'locale';
  static const String _hasAskedForNameKey = 'has_asked_for_name';
  static const String _lastConversationIdKey = 'last_conversation_id';
  
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('tr', '');
  String? _userName;
  bool _hasAskedForName = false;
  String? _lastConversationId;
  bool _isLoaded = false;
  
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String? get userName => _userName;
  bool get hasAskedForName => _hasAskedForName;
  String? get lastConversationId => _lastConversationId;
  bool get isLoaded => _isLoaded;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    // Load locale
    final localeCode = prefs.getString(_localeKey) ?? 'tr';
    _locale = Locale(localeCode, '');
    
    // Load user name
    _userName = prefs.getString(_userNameKey);
    
    // Load has asked for name flag
    _hasAskedForName = prefs.getBool(_hasAskedForNameKey) ?? false;
    
    // Load last conversation ID
    _lastConversationId = prefs.getString(_lastConversationIdKey);
    
    _isLoaded = true;
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
  
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    _hasAskedForName = true; // Once we have a name, we've asked
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setBool(_hasAskedForNameKey, true);
  }
  
  Future<void> setHasAskedForName(bool value) async {
    _hasAskedForName = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAskedForNameKey, value);
  }
  
  Future<void> setLastConversationId(String? id) async {
    _lastConversationId = id;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_lastConversationIdKey, id);
    } else {
      await prefs.remove(_lastConversationIdKey);
    }
  }
  
  String getThemeModeLabel(ThemeMode mode, bool isTurkish) {
    switch (mode) {
      case ThemeMode.system:
        return isTurkish ? 'Sistem' : 'System';
      case ThemeMode.light:
        return isTurkish ? 'Aydınlık' : 'Light';
      case ThemeMode.dark:
        return isTurkish ? 'Karanlık' : 'Dark';
    }
  }
}
