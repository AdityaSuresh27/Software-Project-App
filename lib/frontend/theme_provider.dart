///**
/// ThemeProvider - Theme Mode Management
/// 
/// ChangeNotifier for managing light/dark/system theme modes across the app.
/// Persists theme preference to SharedPreferences for retention across sessions.
/// 
/// Provides:
/// - Theme mode getter/setter (light/dark/system)
/// - Boolean flags for quick mode checking (isDarkMode, isLightMode, etc.)
/// - Automatic persistence and retrieval of user's theme preference
/// - Notification to all listeners when theme changes
/// 
/// Usage: Wrap app with Consumer<ThemeProvider> to react to theme changes.
///

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Changed default to light
  String _backgroundTheme = 'minimalistic'; // 'minimalistic' | 'space'

  ThemeMode get themeMode => _themeMode;
  String get backgroundTheme => _backgroundTheme;
  bool get isSpaceTheme => _backgroundTheme == 'space';
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'light'; // Changed default
    _backgroundTheme = prefs.getString('backgroundTheme') ?? 'minimalistic';
    
    switch (themeModeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.light; // Changed default
    }
    
    notifyListeners();
  }

  Future<void> setBackgroundTheme(String theme) async {
    _backgroundTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backgroundTheme', theme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await prefs.setString('themeMode', themeModeString);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}