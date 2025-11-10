# Project Structure Migration Guide

The project has been reorganized to follow clean architecture principles. Here's what changed:

## New Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   ├── colors.dart              # Color definitions
│   │   └── strings.dart             # String constants
│   ├── utils/
│   │   ├── network_utils.dart       # Network utilities
│   │   ├── animation_utils.dart     # Animation helpers
│   │   ├── localization.dart        # Localization support
│   │   └── app_theme.dart           # Theme configuration
│   └── services/
│       ├── api_service.dart         # Base API service
│       ├── ip_service.dart          # IP-related services
│       ├── ad_service.dart          # AdMob service
│       └── notification_service.dart # Push notifications
├── data/
│   ├── models/
│   │   ├── ip_info.dart            # IP info model
│   │   └── tool_result.dart        # Tool result model
│   └── repositories/
│       ├── ip_repository.dart       # IP data repository
│       └── tools_repository.dart   # Tools data repository
└── presentation/
    ├── widgets/
    │   ├── glass_card.dart          # Glassmorphic card
    │   ├── gradient_text.dart       # Gradient text widget
    │   ├── animated_ip_text.dart    # Animated IP text
    │   ├── particle_background.dart # Particle animation
    │   └── tool_card.dart          # Tool card widget
    ├── screens/
    │   ├── home_screen.dart
    │   ├── detail_screen.dart
    │   ├── tools_screen.dart
    │   ├── whois_screen.dart
    │   ├── dns_screen.dart
    │   ├── ping_screen.dart
    │   └── speed_test_screen.dart
    └── providers/
        ├── ip_provider.dart
        ├── theme_provider.dart
        ├── language_provider.dart
        └── tools_provider.dart
```

## Import Updates Required

### Old Imports → New Imports

**Models:**
```dart
// Old
import '../models/ip_info.dart';
// New
import '../../data/models/ip_info.dart';
```

**Services:**
```dart
// Old
import '../services/ip_service.dart';
// New
import '../../core/services/ip_service.dart';
```

**Widgets:**
```dart
// Old
import '../widgets/glassmorphic_card.dart';
// New
import '../widgets/glass_card.dart';
```

**Providers:**
```dart
// Old
import '../providers/ip_provider.dart';
// New
import '../providers/ip_provider.dart'; // Same path in presentation/
```

**Constants:**
```dart
// Old
import '../utils/app_theme.dart';
// New
import '../../core/utils/app_theme.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
```

## Key Changes

1. **Constants separated**: Colors, strings, and app constants are now in `core/constants/`
2. **Services centralized**: All services moved to `core/services/`
3. **Models in data layer**: All models in `data/models/`
4. **Repositories added**: Data access layer in `data/repositories/`
5. **Presentation layer**: All UI components in `presentation/`
6. **Widgets renamed**: `glassmorphic_card.dart` → `glass_card.dart`
7. **Theme utilities**: Moved to `core/utils/app_theme.dart`

## Migration Steps for Screens

For each screen file, update imports:

1. Replace model imports:
   ```dart
   import '../../data/models/ip_info.dart';
   import '../../data/models/tool_result.dart';
   ```

2. Replace service imports:
   ```dart
   import '../../core/services/ip_service.dart';
   import '../../core/services/ad_service.dart';
   ```

3. Replace widget imports:
   ```dart
   import '../widgets/glass_card.dart';
   import '../widgets/gradient_text.dart';
   import '../widgets/animated_ip_text.dart';
   import '../widgets/particle_background.dart';
   ```

4. Replace constant imports:
   ```dart
   import '../../core/constants/colors.dart';
   import '../../core/constants/strings.dart';
   import '../../core/utils/app_theme.dart';
   ```

5. Replace provider imports (if in presentation/screens):
   ```dart
   import '../providers/ip_provider.dart';
   ```

## Files to Update

- [ ] `lib/presentation/screens/home_screen.dart`
- [ ] `lib/presentation/screens/detail_screen.dart`
- [ ] `lib/presentation/screens/tools_screen.dart`
- [ ] `lib/presentation/screens/whois_screen.dart`
- [ ] `lib/presentation/screens/dns_screen.dart`
- [ ] `lib/presentation/screens/ping_screen.dart`
- [ ] `lib/presentation/screens/speed_test_screen.dart`
- [ ] `lib/presentation/screens/settings_screen.dart`

## Old Files to Delete

After migration, delete:
- `lib/models/` (moved to `lib/data/models/`)
- `lib/services/` (moved to `lib/core/services/`)
- `lib/providers/` (moved to `lib/presentation/providers/`)
- `lib/widgets/` (moved to `lib/presentation/widgets/`)
- `lib/utils/` (moved to `lib/core/utils/`)

## Benefits of New Structure

1. **Separation of Concerns**: Clear separation between data, business logic, and presentation
2. **Scalability**: Easy to add new features without cluttering
3. **Testability**: Each layer can be tested independently
4. **Maintainability**: Easier to find and update code
5. **Clean Architecture**: Follows industry best practices

