class AppConstants {
  // App Info
  static const String appName = 'What Is My IP';
  static const String appVersion = '1.0.1';
  static const int appVersionCode = 2;
  
  // API Endpoints
  static const String defaultIpApiEndpoint = 'https://ipapi.co';
  static const List<String> fallbackIpEndpoints = [
    'https://api.ipify.org?format=json',
    'https://api.ip.sb/ip',
    'https://api.ipify.org',
  ];
  
  // AdMob Configuration
  static const bool adsEnabled = false; // Set to true to enable ads
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String appId = 'ca-app-pub-3940256099942544~3347511713';
  
  // Database
  static const String databaseName = 'ip_history.db';
  static const int databaseVersion = 1;
  
  // Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyCountryCode = 'country_code';
  static const String keyIsProUser = 'is_pro_user';
  
  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration typewriterDuration = Duration(milliseconds: 1500);
  
  // Network
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration networkReceiveTimeout = Duration(seconds: 5);
}

