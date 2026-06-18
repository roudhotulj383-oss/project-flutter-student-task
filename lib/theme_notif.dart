import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengontrol tema global. MaterialApp di main.dart mendengarkan
/// [themeMode], dan SettingsScreen memanggil [setDarkMode] saat
/// switch "Mode Gelap" ditoggle. Nilainya juga disimpan secara
/// lokal supaya tetap diingat walau aplikasi ditutup dan dibuka lagi.
class ThemeNotifier {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static const String _prefKey = 'isDarkMode';

  /// Panggil sekali di main() sebelum runApp(), supaya tema yang
  /// tersimpan langsung dipakai sejak frame pertama.
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Dipanggil dari Settings saat switch "Mode Gelap" ditoggle.
  static Future<void> setDarkMode(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isDark);
  }

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;
}