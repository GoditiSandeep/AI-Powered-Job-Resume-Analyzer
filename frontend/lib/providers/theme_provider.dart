import 'package:flutter/material.dart';
import '../core/storage/secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService storageService;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this.storageService) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final modeStr = storageService.getThemeMode();
    if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    await storageService.saveThemeMode(dark ? 'dark' : 'light');
    notifyListeners();
  }
}
