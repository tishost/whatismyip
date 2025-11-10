import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'What Is My IP',
      'home': 'Home',
      'tools': 'Tools',
      'settings': 'Settings',
      'public_ip': 'Public IP Address',
      'private_ip': 'Private IP Address',
      'copy_ip': 'Copy IP',
      'view_details': 'View Details',
      'location': 'Location',
      'isp': 'ISP',
      'vpn_proxy': 'VPN/Proxy',
      'refresh': 'Refresh',
      'whois_lookup': 'WHOIS Lookup',
      'dns_lookup': 'DNS Lookup',
      'ping_test': 'Ping Test',
      'speed_test': 'Speed Test',
      'ip_details': 'IP Details',
      'copy': 'Copy',
      'share': 'Share',
      'theme': 'Theme',
      'language': 'Language',
      'about': 'About',
    },
    'bn': {
      'app_title': 'আমার আইপি কি',
      'home': 'হোম',
      'tools': 'টুলস',
      'settings': 'সেটিংস',
      'public_ip': 'পাবলিক আইপি ঠিকানা',
      'private_ip': 'প্রাইভেট আইপি ঠিকানা',
      'copy_ip': 'আইপি কপি করুন',
      'view_details': 'বিস্তারিত দেখুন',
      'location': 'অবস্থান',
      'isp': 'আইএসপি',
      'vpn_proxy': 'ভিপিএন/প্রক্সি',
      'refresh': 'রিফ্রেশ',
      'whois_lookup': 'WHOIS লুকআপ',
      'dns_lookup': 'DNS লুকআপ',
      'ping_test': 'পিং টেস্ট',
      'speed_test': 'স্পিড টেস্ট',
      'ip_details': 'আইপি বিস্তারিত',
      'copy': 'কপি',
      'share': 'শেয়ার',
      'theme': 'থিম',
      'language': 'ভাষা',
      'about': 'সম্পর্কে',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'bn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

