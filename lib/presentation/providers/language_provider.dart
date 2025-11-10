import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class LanguageProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  Locale _locale = const Locale('en', 'US');

  LanguageProvider(this._prefs) {
    _loadLanguage();
  }

  Locale get locale => _locale;

  void _loadLanguage() {
    final languageCode = _prefs.getString(AppConstants.keyLanguageCode) ?? 'en';
    final countryCode = _prefs.getString(AppConstants.keyCountryCode) ?? 'US';
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString(AppConstants.keyLanguageCode, locale.languageCode);
    await _prefs.setString(AppConstants.keyCountryCode, locale.countryCode ?? 'US');
    notifyListeners();
  }
}

