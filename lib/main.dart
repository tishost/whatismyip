import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/providers/ip_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/tools_provider.dart';
import 'core/services/ip_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_theme.dart';
import 'core/utils/localization.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Initialize AdMob only if ads are enabled
  if (AppConstants.adsEnabled) {
    await MobileAds.instance.initialize();
  }
  
  await NotificationService.instance.initialize();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => IpProvider(IpService())..fetchIpInfo(),
        ),
        ChangeNotifierProvider(create: (_) => ToolsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp.router(
          title: 'What Is My IP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('bn', 'BD'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
