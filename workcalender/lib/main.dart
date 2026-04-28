import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'presentation/blocs/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system chrome
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize router (checks onboarding status)
  await AppRouter.initialize();

  // Configure flutter_animate
  Animate.restartOnHotReload = true;

  runApp(const WorkCalenderApp());
}

class WorkCalenderApp extends StatelessWidget {
  const WorkCalenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc()..add(LoadSettingsEvent()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'WorkCalender',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
