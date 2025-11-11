import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/tool_result.dart';
import '../widgets/tool_card.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_theme.dart';
import '../widgets/gradient_text.dart';
import '../widgets/particle_background.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  void _navigateToTool(BuildContext context, ToolType toolType) {
    String route;
    switch (toolType) {
      case ToolType.whois:
        route = '/tools/whois';
        break;
      case ToolType.dns:
        route = '/tools/dns';
        break;
      case ToolType.ping:
        route = '/tools/ping';
        break;
      case ToolType.speedTest:
        route = '/tools/speed-test';
        break;
      case ToolType.traceroute:
        route = '/tools/traceroute';
        break;
      case ToolType.portScanner:
        route = '/tools/port-scanner';
        break;
      case ToolType.ssh:
        route = '/tools/ssh';
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.comingSoon)),
        );
        return;
    }
    
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: ParticleBackground(
        child: Container(
          decoration: AppTheme.gradientBackground(
            brightness: Theme.of(context).brightness,
          ),
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
      ),
    );
  }
}

