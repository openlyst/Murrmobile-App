import 'package:flutter/material.dart';
import '../utils/app_preferences.dart';
import '../theme/app_theme.dart';
import '../services/murrtube_api.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'auto';
  String? _cachedMurrtubeTheme;

  ThemeMode get themeMode {
    if (_theme == 'auto') {
      return ThemeMode.system;
    }
    if (_theme == 'murrtube') {
      final effectiveTheme = _cachedMurrtubeTheme ?? 'dark';
      switch (effectiveTheme) {
        case 'light':
          return ThemeMode.light;
        case 'amoled':
          return ThemeMode.dark;
        default:
          return ThemeMode.dark;
      }
    }
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
    if (_theme == 'auto') {
      // For system theme, we need to check the platform brightness
      // This is handled by MaterialApp's themeMode, so we return dark as base
      return AppTheme.dark;
    }
    if (_theme == 'murrtube') {
      final effectiveTheme = _cachedMurrtubeTheme ?? 'dark';
      switch (effectiveTheme) {
        case 'light':
          return AppTheme.light;
        case 'amoled':
          return AppTheme.amoled;
        default:
          return AppTheme.dark;
      }
    }
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
    if (_theme == 'murrtube' && MurrtubeApi.isAuthenticated) {
      await _fetchMurrtubeTheme();
    }
    notifyListeners();
  }

  Future<void> _fetchMurrtubeTheme() async {
    if (!MurrtubeApi.isAuthenticated) return;
    try {
      final settings = await MurrtubeApi.getSettings();
      final user = settings['user'] as Map<String, dynamic>?;
      if (user != null) {
        final murrtubeTheme = user['theme'] as String?;
        if (murrtubeTheme != null) {
          _cachedMurrtubeTheme = murrtubeTheme;
        }
      }
    } catch (e) {
      // If we can't fetch from murrtube, just use dark as fallback
      _cachedMurrtubeTheme = 'dark';
    }
  }

  Future<void> setTheme(String theme) async {
    if (_theme == theme) return;
    _theme = theme;
    await AppPreferences.setTheme(theme);
    if (_theme == 'murrtube') {
      await _fetchMurrtubeTheme();
    }
    notifyListeners();
  }

  Future<void> refreshMurrtubeTheme() async {
    if (_theme == 'murrtube') {
      await _fetchMurrtubeTheme();
      notifyListeners();
    }
  }
}
