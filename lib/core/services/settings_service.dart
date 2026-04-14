import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';

  SharedPreferences? _prefs;

  final themeMode = 'dark'.obs;
  final locale = 'ar'.obs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode.value = _prefs?.getString(_keyThemeMode) ?? 'dark';
    locale.value = _prefs?.getString(_keyLocale) ?? 'ar';
    return this;
  }

  bool get isDarkMode => themeMode.value == 'dark';

  ThemeMode get themeModeValue =>
      themeMode.value == 'dark' ? ThemeMode.dark : ThemeMode.light;

  void setThemeMode(bool isDark) {
    themeMode.value = isDark ? 'dark' : 'light';
    _prefs?.setString(_keyThemeMode, themeMode.value);
  }

  void setLocale(String lang) {
    if (lang != 'ar' && lang != 'en') return;
    locale.value = lang;
    _prefs?.setString(_keyLocale, lang);
    Get.updateLocale(Locale(lang));
  }

  void toggleTheme() {
    setThemeMode(!isDarkMode);
  }

  void toggleLocale() {
    setLocale(locale.value == 'ar' ? 'en' : 'ar');
  }
}
