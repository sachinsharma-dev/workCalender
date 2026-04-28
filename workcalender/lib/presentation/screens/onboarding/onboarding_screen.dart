import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workcalender/presentation/core/theme/app_theme.dart';
import 'package:workcalender/presentation/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardPage(
      gradient: [AppTheme.primaryBlue, const Color(0xFF2D4CC8)],
      icon: Icons.dashboard_rounded,
      title: 'Smart Dashboard',
      subtitle: 'Your entire day at a glance. Know exactly what to do next with AI-powered suggestions.',
      features: ['Daily productivity score', 'Best next task AI', 'Time remaining tracker'],
    ),
    _OnboardPage(
      gradient: [AppTheme.primaryPurple, const Color(0xFF5A3CC8)],
      icon: Icons.calendar_month_rounded,
      title: 'Interactive Calendar',
      subtitle: 'Visual planning made beautiful. Tap any date, drag tasks, see your whole month.',
      features: ['Monthly / Weekly / Daily views', 'Color-coded tasks', 'Drag & drop scheduling'],
    ),
    _OnboardPage(
      gradient: [AppTheme.accentTeal, const Color(0xFF00A888)],
      icon: Icons.mic_rounded,
      title: 'Voice Task Input',
      subtitle: 'Just speak naturally. "Study math tomorrow 7pm for 2 hours" — done automatically.',
      features: ['Natural language processing', 'Auto date & time parsing', 'Smart task creation'],
    ),
    _OnboardPage(
      gradient: [AppTheme.accentOrange, const Color(0xFFE85520)],
      icon: Icons.auto_awesome_rounded,
      title: 'AI Scheduler',
      subtitle: 'Advanced algorithms decide what fits today, what to prioritize, and what to postpone.',
      features: ['Knapsack optimization', 'Deadline-first ordering', 'Auto reschedule missed tasks'],
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _OnboardPageView(page: _pages[i]),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: TextButton(
              onPressed: _complete,
              child: Text('Skip',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(context).padding.bottom + 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: AppConstants.animNormal,
                      curve: Curves.easeInOut,
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(i == _currentPage ? 1 : 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].gradient[0],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _controller.nextPage(
                              duration: AppConstants.animNormal, curve: Curves.easeInOut);
                        } else {
                          _complete();
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Continue' : 'Get Started',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: _pages[_currentPage].gradient[0]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  const _OnboardPage({
    required this.gradient, required this.icon, required this.title,
    required this.subtitle, required this.features,
  });
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [...page.gradient, Colors.black87],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Icon
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(page.icon, size: 60, color: Colors.white),
              )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              Text(page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
              ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              Text(page.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.8), height: 1.5),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 40),

              // Feature pills
              ...page.features.asMap().entries.map((e) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Text(e.value,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
                .animate()
                .slideX(begin: 0.2, duration: 400.ms, delay: Duration(milliseconds: 300 + e.key * 80))
                .fadeIn(delay: Duration(milliseconds: 300 + e.key * 80)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
