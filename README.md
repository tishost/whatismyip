# What Is My IP - Flutter App

A modern, glassmorphic mobile application for checking your IP address and network information with advanced network tools.

## Features

### Core Features
- **IP Detection**: Public and Private IP address detection
- **IP Information**: Detailed metadata including location, ISP, ASN, and more
- **VPN/Proxy Detection**: Identify if you're using a VPN or proxy
- **Google Maps Integration**: Visual representation of IP location
- **IP History**: Track IP changes over time with export options

### Network Tools
- **WHOIS Lookup**: Domain registration information
- **DNS Lookup**: Query DNS records (A, MX, NS, TXT, CNAME)
- **Ping Test**: Network latency testing
- **Speed Test**: Download/upload speed measurement

### Design & UX
- **Glassmorphic UI**: Modern glass-effect cards with blur
- **Gradient Background**: Deep Blue → Purple → Violet gradient
- **Animated Effects**: Typewriter text, floating particles, smooth transitions
- **Dark Mode**: Full dark mode support
- **Multilingual**: English and Bangla support

### Additional Features
- **AdMob Integration**: Banner, interstitial, and rewarded ads
- **Pro Features**: Ad-free experience with unlimited tools
- **Export Options**: CSV/PDF export for IP history
- **Push Notifications**: IP change alerts (Firebase integration)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── ip_info.dart
│   └── network_tool.dart
├── providers/                # State management
│   ├── ip_provider.dart
│   ├── theme_provider.dart
│   └── language_provider.dart
├── screens/                   # UI screens
│   ├── home_screen.dart
│   ├── detail_screen.dart
│   ├── settings_screen.dart
│   └── tools/
│       ├── whois_screen.dart
│       ├── dns_screen.dart
│       ├── ping_screen.dart
│       └── speed_test_screen.dart
├── services/                  # Business logic
│   ├── ip_service.dart
│   └── ad_service.dart
├── widgets/                   # Reusable widgets
│   ├── glassmorphic_card.dart
│   ├── gradient_text.dart
│   ├── neon_button.dart
│   ├── particle_background.dart
│   └── typewriter_text.dart
└── utils/                     # Utilities
    ├── app_theme.dart
    ├── database_helper.dart
    └── localization.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode
- Google Maps API key (for maps feature)
- AdMob account (for ads)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "What is My IP"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**

   - **Google Maps**: Add your API key in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`
   - **AdMob**: Update AdMob unit IDs in `lib/services/ad_service.dart`
   - **IP API**: Configure your backend API endpoint in `lib/services/ip_service.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Android Configuration

1. Update `android/app/build.gradle`:
   ```gradle
   minSdkVersion 21
   targetSdkVersion 33
   ```

2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```

3. Add Google Maps API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
   ```

### iOS Configuration

1. Update `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```

2. Add permissions in `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to show IP location on map</string>
   ```

## Backend API Integration

The app uses multiple IP information APIs with fallback support:

1. **Primary API**: Configure in `lib/services/ip_service.dart`
   ```dart
   IpService(apiEndpoint: 'https://api.digdns.io/ip')
   ```

2. **Fallback APIs**: 
   - ipapi.co
   - ipinfo.io
   - ipify.org

### Custom Laravel Backend

To use your own Laravel backend:

1. Create API endpoint: `GET /api/ip`
2. Return JSON response matching `IpInfo` model structure
3. Update `IpService` to use your endpoint

Example Laravel route:
```php
Route::get('/api/ip', function () {
    return response()->json([
        'ip' => request()->ip(),
        'country' => 'United States',
        'city' => 'New York',
        // ... other fields
    ]);
});
```

## AdMob Integration

1. **Get AdMob App ID**: Create an app in AdMob console
2. **Update Ad Unit IDs**: Replace test IDs in `lib/services/ad_service.dart`:
   ```dart
   static const String _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
   static const String _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
   static const String _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
   ```

3. **Android**: Add App ID in `android/app/src/main/AndroidManifest.xml`
4. **iOS**: Add App ID in `ios/Runner/Info.plist`

## Pro Features

Pro features are controlled via `AdService.isProUser()`. To implement in-app purchases:

1. Add `in_app_purchase` package
2. Implement purchase flow in Settings screen
3. Update `AdService.setProUser()` on successful purchase

## Building for Release

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Dependencies

Key dependencies:
- `provider`: State management
- `google_maps_flutter`: Maps integration
- `google_mobile_ads`: AdMob integration
- `dio`: HTTP client
- `sqflite`: Local database
- `google_fonts`: Poppins font
- `flutter_animate`: Animations
- `firebase_core`: Firebase integration

## Future Enhancements

- [ ] Port Scanner tool
- [ ] Traceroute tool
- [ ] Local network scan
- [ ] IP blacklist checking
- [ ] Home screen widget
- [ ] More language support
- [ ] IP change notifications
- [ ] CSV/PDF export for history

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please open an issue on GitHub.

