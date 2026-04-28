import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workcalender/presentation/blocs/task_bloc.dart';
import 'package:workcalender/presentation/blocs/settings_bloc.dart';
import 'package:workcalender/presentation/screens/onboarding/splash_screen.dart';
import 'package:workcalender/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:workcalender/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:workcalender/presentation/screens/dashboard/main_shell.dart';
import 'package:workcalender/presentation/screens/calendar/calendar_screen.dart';
import 'package:workcalender/presentation/screens/analytics/analytics_screen.dart';
import 'package:workcalender/presentation/screens/settings/settings_screen.dart';
import 'package:workcalender/data/repositories/repositories.dart';
import 'package:workcalender/core/constants/app_constants.dart';

class AppRouter {
  static late GoRouter router;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

    router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        ShellRoute(
          builder: (ctx, state, child) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => TaskBloc(
                  taskRepo: TaskRepository(),
                  categoryRepo: CategoryRepository(),
                  analyticsRepo: AnalyticsRepository(),
                )..add(LoadTasksEvent(DateTime.now())),
              ),
              BlocProvider(
                create: (_) => SettingsBloc()..add(LoadSettingsEvent()),
              ),
            ],
            child: MainShell(child: child),
          ),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
            GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ],
        ),
      ],
      redirect: (ctx, state) {
        if (state.matchedLocation == '/splash') return null;
        if (!onboardingDone && state.matchedLocation != '/onboarding') return '/onboarding';
        return null;
      },
    );
  }
}
