import 'package:flutter/material.dart';
import '../../data/models/tool_result.dart';
import '../widgets/tool_card.dart';
import 'tools/whois_screen.dart';
import 'tools/dns_screen.dart';
import 'tools/ping_screen.dart';
import 'tools/speed_test_screen.dart';
import 'tools/traceroute_screen.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/particle_background.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  void _navigateToTool(BuildContext context, ToolType toolType) {
    Widget screen;
    switch (toolType) {
      case ToolType.whois:
        screen = const WhoisScreen();
        break;
      case ToolType.dns:
        screen = const DnsScreen();
        break;
      case ToolType.ping:
        screen = const PingScreen();
        break;
      case ToolType.speedTest:
        screen = const SpeedTestScreen();
        break;
      case ToolType.traceroute:
        screen = const TracerouteScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.comingSoon)),
        );
        return;
    }
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ParticleBackground(
      child: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                GradientText(
                  AppStrings.tools,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Powerful utilities for network analysis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: NetworkTool.allTools.length,
                  itemBuilder: (context, index) {
                    final tool = NetworkTool.allTools[index];
                    return ToolCard(
                      tool: tool,
                      onTap: () => _navigateToTool(context, tool.type),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

