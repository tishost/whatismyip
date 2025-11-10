import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ip_info.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/detail_screen.dart';
import '../../presentation/screens/tools_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/device_info_screen.dart';
import '../../presentation/screens/tools/ping_screen.dart';
import '../../presentation/screens/tools/dns_screen.dart';
import '../../presentation/screens/tools/whois_screen.dart';
import '../../presentation/screens/tools/traceroute_screen.dart';
import '../../presentation/screens/tools/speed_test_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
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
      
      // Detail screens (full screen, no bottom nav)
      GoRoute(
        path: '/detail',
        name: 'detail',
        pageBuilder: (context, state) {
          final ipInfo = state.extra as IpInfo?;
          if (ipInfo == null) {
            return MaterialPage(
              child: Scaffold(
                body: Center(child: Text('IP Info not found')),
              ),
            );
          }
          return MaterialPage(
            key: state.pageKey,
            child: DetailScreen(ipInfo: ipInfo),
          );
        },
      ),
      
      // Tool screens
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

