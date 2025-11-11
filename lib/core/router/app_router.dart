import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/tools_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/device_info_screen.dart';
import '../../presentation/screens/tools/ping_screen.dart';
import '../../presentation/screens/tools/dns_screen.dart';
import '../../presentation/screens/tools/whois_screen.dart';
import '../../presentation/screens/tools/traceroute_screen.dart';
import '../../presentation/screens/tools/speed_test_screen.dart';
import '../../presentation/screens/tools/port_scanner_screen.dart';
import '../../presentation/screens/tools/ssh_screen.dart';
import '../../presentation/screens/ip_history_screen.dart';
import '../../presentation/screens/splash_screen.dart';

class AppRouter {
  // Root navigator key for full-screen routes
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      // Main shell route with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreenContent(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                name: 'tools',
                builder: (context, state) => const ToolsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/device-info',
                name: 'device-info',
                builder: (context, state) => const DeviceInfoScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // Tool screens (full-screen routes, separate from /tools shell route)
      GoRoute(
        path: '/tools/ping',
        name: 'ping',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PingScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/dns',
        name: 'dns',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DnsScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/whois',
        name: 'whois',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WhoisScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/traceroute',
        name: 'traceroute',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TracerouteScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/speed-test',
        name: 'speed-test',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SpeedTestScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/port-scanner',
        name: 'port-scanner',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PortScannerScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/ssh',
        name: 'ssh',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SshScreen(),
        ),
      ),
      GoRoute(
        path: '/ip-history',
        name: 'ip-history',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const IpHistoryScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
