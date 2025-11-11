import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'theme_provider.dart';

class LanguageNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) : super(const Locale('en', 'US')) {
    _loadLanguage();
  }

  void _loadLanguage() {
    final languageCode = _prefs.getString(AppConstants.keyLanguageCode) ?? 'en';
    final countryCode = _prefs.getString(AppConstants.keyCountryCode) ?? 'US';
    state = Locale(languageCode, countryCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(AppConstants.keyLanguageCode, locale.languageCode);
    await _prefs.setString(AppConstants.keyCountryCode, locale.countryCode ?? 'US');
  }
}

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});
