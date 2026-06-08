import 'package:flutter/material.dart';
import '../utils/app_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'dark';

  ThemeMode get themeMode {
    switch (_theme) {
      case 'light':
        return ThemeMode.light;
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  ThemeData get themeData {
    switch (_theme) {
      case 'light':
        return AppTheme.light;
      case 'amoled':
        return AppTheme.amoled;
      default:
        return AppTheme.dark;
    }
  }

  String get currentTheme => _theme;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    _theme = await AppPreferences.getTheme();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    if (_theme == theme) return;
    _theme = theme;
    await AppPreferences.setTheme(theme);
    notifyListeners();
  }
}
