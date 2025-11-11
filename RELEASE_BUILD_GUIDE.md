# Release Build Guide

## Android Release Build Setup

### Step 1: Generate Keystore

Run this command in the project root directory:

```bash
keytool -genkey -v -keystore android/keystore/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:**
- Remember the passwords you set (store password and key password)
- Remember the alias name (usually "upload")
- Keep the keystore file safe - you'll need it for all future updates
- The keystore file is required for Google Play Store uploads

### Step 2: Create key.properties File

1. Copy the template:
```bash
cp android/key.properties.template android/key.properties
```

2. Edit `android/key.properties` and fill in your actual values:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=keystore/upload-keystore.jks
```

**Note:** The `storeFile` path is relative to the `android/` directory.

**⚠️ IMPORTANT:**
- **DO NOT** commit `key.properties` or `keystore/` folder to git
- These files are already in `.gitignore`
- Keep these credentials secure

### Step 3: Build Release APK

For APK (direct installation):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

For App Bundle (Google Play Store):
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Update Version

Before each release, update version in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Format: version_name+build_number
# version_name: 1.0.1 (user-visible version)
# build_number: 2 (incremental build number)
```

### Step 5: Test Release Build

Before publishing:
1. Install the release APK on a test device
2. Test all features
3. Verify ads are working (if enabled)
4. Check performance

## iOS Release Build (Future)

For iOS release builds, you'll need:
1. Apple Developer Account ($99/year)
2. Xcode configured with signing certificates
3. Run: `flutter build ios --release`
4. Archive and upload via Xcode

## Next Version Features (Planned)

### SSH Terminal System (v1.1.0)
- SSH connection management
- Terminal emulator UI
- Command execution
- Multiple session support
- Connection history
- SSH key authentication
- Port forwarding support

**Note:** SSH terminal feature will be added in version 1.1.0
