import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  vietnamese('vi', 'Vietnamese');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);
}

final appLanguageProvider = NotifierProvider<AppLanguageController, AppLanguage>(
  AppLanguageController.new,
);

class AppLanguageController extends Notifier<AppLanguage> {
  static const _languageKey = 'app_language';

  @override
  AppLanguage build() {
    _restoreLanguage();
    return AppLanguage.english;
  }

  Future<void> _restoreLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);

    if (savedCode == null || savedCode.isEmpty) {
      return;
    }

    state = AppLanguage.values.firstWhere(
      (language) => language.code == savedCode,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) {
      return;
    }

    state = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }
}
