import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restoreThemeMode();
    return ThemeMode.light;
  }

  static const _themeModeKey = 'theme_mode';

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);

    if (savedThemeMode == null) {
      return;
    }

    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedThemeMode,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    final nextMode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (nextMode == state) {
      return;
    }

    state = nextMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, nextMode.name);
  }
}
