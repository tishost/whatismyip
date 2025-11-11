import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../widgets/gradient_text.dart';
import '../../core/utils/app_theme.dart';
import '../../core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _networkController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _networkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Navigate to home after minimum splash duration
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for minimum splash screen duration (2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      // Navigate to home screen
      context.go('/');
    }
  }

  @override
  void dispose() {
    _networkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(
          brightness: Theme.of(context).brightness,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Network Animation
                SizedBox(
                  width: size.width * 0.8,
                  height: size.width * 0.6,
                  child: _buildNetworkAnimation(),
                ),
                const SizedBox(height: 40),
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonBlue.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.network_check,
                            size: 60,
                            color: AppColors.neonBlue,
                          ),
                        );
                      },
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.05, 1.05),
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 30),
                // App Name
                const GradientText(
                  'What Is My IP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  'Network Information & Tools',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 800.ms, delay: 500.ms),
                const SizedBox(height: 60),
                // Loading Indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neonBlue,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 1500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkAnimation() {
    return AnimatedBuilder(
      animation: _networkController,
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkPainter(
            progress: _networkController.value,
            pulseProgress: _pulseController.value,
          ),
        );
      },
    );
  }
}

class NetworkPainter extends CustomPainter {
  final double progress;
  final double pulseProgress;

  NetworkPainter({
    required this.progress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Define network nodes (central hub and connected nodes)
    final nodes = [
      center, // Central hub
      Offset(size.width * 0.2, size.height * 0.3), // Top left
      Offset(size.width * 0.8, size.height * 0.3), // Top right
      Offset(size.width * 0.2, size.height * 0.7), // Bottom left
      Offset(size.width * 0.8, size.height * 0.7), // Bottom right
      Offset(size.width * 0.1, size.height * 0.5), // Left
      Offset(size.width * 0.9, size.height * 0.5), // Right
    ];

    // Draw connections with animated data flow
    for (int i = 1; i < nodes.length; i++) {
      final start = nodes[0];
      final end = nodes[i];

      // Calculate animated point along the connection
      final animatedPoint = Offset.lerp(
        start,
        end,
        (progress * 2) % 1.0,
      ) ?? start;

      // Draw connection line
      paint.color = AppColors.neonBlue.withOpacity(0.3);
      canvas.drawLine(start, end, paint);

      // Draw animated data packet
      paint.color = AppColors.neonBlue;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(animatedPoint, 6, paint);

      // Add glow effect
      paint.color = AppColors.neonBlue.withOpacity(0.3);
      canvas.drawCircle(animatedPoint, 12, paint);
    }

    // Draw nodes
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isCenter = i == 0;

      // Pulse effect for center node
      if (isCenter) {
        final pulseRadius = 20 + (pulseProgress * 10);
        paint.color = AppColors.neonBlue.withOpacity(0.2);
        canvas.drawCircle(node, pulseRadius, paint);
      }

      // Node circle
      paint.color = isCenter
          ? AppColors.neonBlue
          : AppColors.neonBlue.withOpacity(0.7);
      canvas.drawCircle(node, isCenter ? 12 : 8, paint);

      // Inner glow
      paint.color = Colors.white.withOpacity(0.8);
      canvas.drawCircle(node, isCenter ? 6 : 4, paint);
    }

    // Draw signal waves from center
    final waveCount = 3;
    for (int i = 0; i < waveCount; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final waveRadius = 30 + (waveProgress * 60);
      final opacity = (1 - waveProgress) * 0.5;

      paint
        ..style = PaintingStyle.stroke
        ..color = AppColors.neonBlue.withOpacity(opacity)
        ..strokeWidth = 2;
      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  @override
  bool shouldRepaint(NetworkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

