import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:workcalender/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _rippleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1E3A), Color(0xFF0D0F1A), Color(0xFF1A0D2E)],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            _AnimatedRipple(controller: _rippleController, delay: 0, radius: 200, color: AppTheme.primaryBlue),
            _AnimatedRipple(controller: _rippleController, delay: 0.3, radius: 280, color: AppTheme.primaryPurple),
            _AnimatedRipple(controller: _rippleController, delay: 0.6, radius: 360, color: AppTheme.accentTeal),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 52),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  Text(
                    'WorkCalender',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  )
                  .animate().slideY(begin: 0.3, duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Smart Productivity & Planning',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white54,
                      letterSpacing: 0.3,
                    ),
                  )
                  .animate().slideY(begin: 0.3, duration: 500.ms, delay: 350.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 500.ms, delay: 350.ms),

                  const SizedBox(height: 80),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .fadeIn(delay: Duration(milliseconds: i * 200), duration: 400.ms)
                     .scale(delay: Duration(milliseconds: i * 200), duration: 400.ms)),
                  )
                  .animate().fadeIn(delay: 800.ms, duration: 400.ms),
                ],
              ),
            ),

            // Version text
            Positioned(
              bottom: 40,
              left: 0, right: 0,
              child: Text(
                'v1.0.0 • Built with ❤️',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white24),
              ).animate().fadeIn(delay: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRipple extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final double radius;
  final Color color;

  const _AnimatedRipple({
    required this.controller,
    required this.delay,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final progress = ((controller.value + delay) % 1.0);
          return Opacity(
            opacity: (1 - progress) * 0.08,
            child: Container(
              width: radius * progress * 2,
              height: radius * progress * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
