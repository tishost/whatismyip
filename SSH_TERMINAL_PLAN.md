# SSH Terminal Tool Implementation & Deployment Plan

## 📋 Overview
এই document-এ SSH Terminal tool যোগ করার এবং deployment করার সম্পূর্ণ plan দেওয়া আছে।

---

## 🎯 Phase 1: SSH Terminal Implementation

### Step 1: Dependencies যোগ করা

**Required Packages:**
```yaml
# pubspec.yaml এ যোগ করতে হবে:
dependencies:
  # SSH Client
  ssh: ^2.0.0  # বা latest version
  # Alternative: flutter_ssh (যদি available হয়)
  
  # Terminal UI
  flutter_terminal: ^0.1.0  # Terminal emulator UI
  # Alternative: xterm.dart বা custom terminal widget
```

**Package Options:**
1. **ssh** package - Pure Dart SSH client
2. **flutter_ssh** - Flutter-specific wrapper (যদি available হয়)
3. **Backend API Approach** - digdns.io API দিয়ে SSH proxy (traceroute এর মতো)

### Step 2: Model Update

**File: `lib/data/models/tool_result.dart`**
- `ToolType` enum এ `ssh` যোগ করতে হবে
- `NetworkTool.allTools` list এ SSH tool যোগ করতে হবে

```dart
enum ToolType {
  // ... existing
  ssh,
}

// NetworkTool.allTools এ:
NetworkTool(
  type: ToolType.ssh,
  name: 'SSH Terminal',
  icon: '💻',
  description: 'Secure shell terminal client',
  isPro: true,  // Pro feature হিসেবে রাখা
),
```

### Step 3: SSH Screen তৈরি

**File: `lib/presentation/screens/tools/ssh_screen.dart`**

**Features:**
- Connection form (Host, Port, Username, Password/Key)
- Terminal output display
- Command input field
- Connection status indicator
- Multiple session support (optional)
- Connection history
- SSH key file picker (optional)

**UI Components:**
- Glass card design (existing style maintain)
- Terminal-like output area (monospace font, dark background)
- Input field with command history
- Connection settings panel

### Step 4: Router Update

**File: `lib/core/router/app_router.dart`**
- SSH screen route যোগ করতে হবে

```dart
GoRoute(
  path: '/tools/ssh',
  name: 'ssh',
  pageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: const SshScreen(),
  ),
),
```

### Step 5: Tools Screen Update

**File: `lib/presentation/screens/tools_screen.dart`**
- `_navigateToTool` method এ SSH case যোগ করতে হবে

```dart
case ToolType.ssh:
  route = '/tools/ssh';
  break;
```

---

## 🔧 Phase 2: Implementation Details

### SSH Connection Flow

1. **Input Validation:**
   - Host/IP validation
   - Port validation (default: 22)
   - Username validation
   - Password or SSH key selection

2. **Connection Establishment:**
   - SSH client initialization
   - Authentication (password/key)
   - Session creation
   - Error handling

3. **Command Execution:**
   - Command input
   - Execute via SSH session
   - Output display
   - Error handling

4. **Session Management:**
   - Connection status
   - Disconnect functionality
   - Reconnection support

### Security Considerations

1. **Credential Storage:**
   - Password: Never store in plain text
   - Use secure storage (encrypted SharedPreferences)
   - SSH keys: Store securely, never expose

2. **Network Security:**
   - Validate host certificates
   - Support for known_hosts
   - Warning for unknown hosts

3. **Permissions:**
   - Internet permission (already in AndroidManifest)
   - Storage permission (for SSH key files)

---

## 🚀 Phase 3: Deployment Plan

### Option A: Direct SSH Client (Recommended for MVP)

**Pros:**
- No backend required
- Direct connection
- Lower latency

**Cons:**
- Mobile platform limitations
- Certificate management complexity
- Battery usage

**Implementation:**
- Use `ssh` package
- Handle all SSH logic in app
- Store credentials securely

### Option B: Backend API Proxy (Recommended for Production)

**Pros:**
- Better security (credentials never leave backend)
- Easier certificate management
- Can add rate limiting
- Better error handling

**Cons:**
- Requires backend API endpoint
- Additional server cost
- Slightly higher latency

**Implementation:**
- Add SSH endpoint to digdns.io API
- App sends commands via HTTPS
- Backend executes via SSH
- Results returned to app

**API Endpoint Design:**
```
POST /api/node/v1/ssh/connect
POST /api/node/v1/ssh/execute
POST /api/node/v1/ssh/disconnect
```

### Option C: Hybrid Approach

- Simple commands: Direct SSH
- Complex operations: Backend API
- User choice: Let user select

---

## 📱 Phase 4: Android Deployment

### Step 1: Permissions Check

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<!-- Already have INTERNET permission -->
<uses-permission android:name="android.permission.INTERNET"/>
<!-- Add if needed for SSH key file access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### Step 2: ProGuard Rules

**File: `android/app/proguard-rules.pro`**
```proguard
# SSH package rules (if needed)
-keep class com.ssh.** { *; }
-dontwarn com.ssh.**
```

### Step 3: Build & Test

```bash
# Debug build
flutter build apk --debug

# Test on device
flutter install

# Release build (after testing)
flutter build apk --release
```

### Step 4: Version Update

**File: `pubspec.yaml`**
```yaml
version: 1.1.0+1  # SSH feature version
```

---

## 🧪 Phase 5: Testing Plan

### Unit Tests
- SSH connection logic
- Command execution
- Error handling

### Integration Tests
- Full SSH connection flow
- Multiple commands
- Disconnect/reconnect

### UI Tests
- Connection form validation
- Terminal output display
- Error messages

### Security Tests
- Credential storage
- Network security
- Certificate validation

---

## 📊 Phase 6: Feature Roadmap

### v1.1.0 (Initial Release)
- ✅ Basic SSH connection
- ✅ Password authentication
- ✅ Command execution
- ✅ Terminal output display
- ✅ Connection management

### v1.1.1 (Enhancement)
- 🔄 SSH key authentication
- 🔄 Connection history
- 🔄 Multiple sessions
- 🔄 Command history

### v1.2.0 (Advanced)
- 🔄 SFTP file transfer
- 🔄 Port forwarding
- 🔄 Terminal customization
- 🔄 Session export/import

---

## 🛠️ Implementation Checklist

### Code Changes
- [ ] Add SSH package to pubspec.yaml
- [ ] Update ToolType enum
- [ ] Add SSH to NetworkTool.allTools
- [ ] Create SshScreen widget
- [ ] Add SSH route to app_router.dart
- [ ] Update tools_screen.dart navigation
- [ ] Create SSH service (optional, for better architecture)

### UI/UX
- [ ] Design connection form
- [ ] Design terminal output area
- [ ] Add loading states
- [ ] Add error handling UI
- [ ] Add connection status indicator
- [ ] Match existing glassmorphic design

### Security
- [ ] Implement secure credential storage
- [ ] Add certificate validation
- [ ] Add security warnings
- [ ] Test credential encryption

### Testing
- [ ] Test connection with various hosts
- [ ] Test password authentication
- [ ] Test error scenarios
- [ ] Test on different Android versions
- [ ] Performance testing

### Deployment
- [ ] Update version number
- [ ] Test release build
- [ ] Update RELEASE_BUILD_GUIDE.md
- [ ] Prepare release notes
- [ ] Build and sign APK/AAB

---

## 🔐 Security Best Practices

1. **Never log credentials** - Remove all debug logs with passwords
2. **Encrypt stored credentials** - Use Flutter secure storage
3. **Validate certificates** - Warn users about unknown hosts
4. **Timeout connections** - Prevent hanging connections
5. **Rate limiting** - Prevent abuse (if using backend API)

---

## 📝 Notes

- SSH terminal is a **Pro feature** (isPro: true)
- Consider adding in-app purchase for Pro features
- Backend API approach is recommended for production
- Test thoroughly before release
- Consider iOS implementation later (if needed)

---

## 🚨 Important Considerations

1. **Battery Usage:** SSH connections can drain battery
2. **Network Usage:** Continuous connections use data
3. **Security:** Handle credentials with extreme care
4. **Platform Support:** Android first, iOS later
5. **User Experience:** Make it intuitive and fast

---

## 📞 Support & Resources

- SSH Package: https://pub.dev/packages/ssh
- Flutter Secure Storage: https://pub.dev/packages/flutter_secure_storage
- digdns.io API: See api.md for existing endpoints

---

**Last Updated:** 2025-01-XX
**Status:** Planning Phase
**Next Steps:** Start with Option B (Backend API) for better security

