import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

/// Global language notifier.
/// Listen to this from the root widget to hot-swap the whole app's language.
class LanguageProvider extends ValueNotifier<String> {
  static const _key = 'app_language';

  LanguageProvider._internal(super.value);

  static final LanguageProvider instance = LanguageProvider._internal('ar');

  /// Load saved language from SharedPreferences (call once at startup).
  /// On first launch (no saved value), auto-detects the device locale:
  ///   • Arabic device  → 'ar'
  ///   • Any other      → 'en'
  /// Once the user manually changes the language via the toggle button,
  /// that choice is persisted and this auto-detection never runs again.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      // User has an explicit saved preference — respect it always.
      instance.value = saved;
    } else {
      // First launch: detect device locale. Arabic → 'ar', else → 'en'.
      final deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode;
      final detected = (deviceLocale == 'ar') ? 'ar' : 'en';
      instance.value = detected;
      // Persist so future launches stay consistent until manually toggled.
      await prefs.setString(_key, detected);
    }
  }

  /// Toggle between Arabic ('ar') and English ('en') and persist the choice.
  Future<void> toggle() async {
    value = value == 'ar' ? 'en' : 'ar';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  bool get isArabic => value == 'ar';
}
