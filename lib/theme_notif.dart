import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// [themeMode],  [setDarkMode] .
class ThemeNotifier {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static const String _prefKey = 'isDarkMode';

  
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  
  static Future<void> setDarkMode(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isDark);
  }

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;
}