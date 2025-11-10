# Setup Guide for "What Is My IP" Flutter App

## Quick Start

1. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API Keys**

   ### Google Maps API Key
   - Get your API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Enable "Maps SDK for Android" and "Maps SDK for iOS"
   - Update `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
     ```
   - Update `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
     ```

   ### AdMob Configuration
   - Create an AdMob account at [AdMob Console](https://admob.google.com/)
   - Create an app and get your App ID
   - Create ad units (Banner, Interstitial, Rewarded)
   - Update `lib/services/ad_service.dart`:
     ```dart
     static const String _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
     static const String _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
     static const String _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
     ```
   - Update `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.gms.ads.APPLICATION_ID"
         android:value="YOUR_ADMOB_APP_ID"/>
     ```

3. **Backend API Configuration (Optional)**
   
   If you have a custom Laravel backend:
   - Update `lib/services/ip_service.dart`:
     ```dart
     IpService(apiEndpoint: 'https://api.digdns.io/ip')
     ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Platform-Specific Setup

### Android

1. **Minimum SDK**: 21 (Android 5.0)
2. **Target SDK**: 33
3. **Permissions**: Already configured in `AndroidManifest.xml`

### iOS

1. **Minimum iOS Version**: 12.0
2. **Update `ios/Podfile`**:
   ```ruby
   platform :ios, '12.0'
   ```
3. **Run pod install**:
   ```bash
   cd ios
   pod install
   cd ..
   ```
4. **Add location permission** in `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to show IP location on map</string>
   ```

## Firebase Setup (Optional)

1. Create a Firebase project
2. Add Android and iOS apps
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Firebase is already initialized in `main.dart`

## Building for Release

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Package not found errors**
   - Run `flutter pub get`
   - Run `flutter clean` then `flutter pub get`

2. **Google Maps not showing**
   - Verify API key is correct
   - Check API key restrictions in Google Cloud Console
   - Ensure Maps SDK is enabled

3. **Ads not showing**
   - Verify AdMob App ID and Ad Unit IDs
   - Check if test ads work first
   - Ensure app is connected to AdMob account

4. **Build errors**
   - Check Flutter version: `flutter --version`
   - Ensure all dependencies are compatible
   - Review error messages for specific package issues

## Development Notes

- The app uses Provider for state management
- IP detection uses multiple APIs with fallback support
- Glassmorphic design uses custom widgets
- Animations use flutter_animate package
- Database uses sqflite for local storage

## Next Steps

1. Replace test AdMob IDs with production IDs
2. Configure your backend API endpoint
3. Add your Google Maps API key
4. Test on physical devices
5. Configure Firebase for analytics (optional)
6. Set up in-app purchases for Pro features (optional)

