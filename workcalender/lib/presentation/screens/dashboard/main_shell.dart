import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workcalender/presentation/core/constants/app_constants.dart';
import 'package:workcalender/presentation/core/theme/app_theme.dart';
import 'package:workcalender/presentation/presentation/blocs/task_bloc.dart';
import 'package:workcalender/presentation/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:workcalender/presentation/presentation/screens/calendar/calendar_screen.dart';
import 'package:workcalender/presentation/presentation/screens/analytics/analytics_screen.dart';
import 'package:workcalender/presentation/presentation/screens/settings/settings_screen.dart';
import 'package:workcalender/presentation/presentation/screens/tasks/add_task_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = ['/dashboard', '/calendar', '/analytics', '/settings'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      floatingActionButton: _currentIndex <= 1
          ? FloatingActionButton(
              onPressed: () => _openAddTask(context),
              child: const Icon(Icons.add_rounded, size: 28),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                  index: 0, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendar',
                  index: 1, current: _currentIndex, onTap: _onTap),
                const SizedBox(width: 72), // FAB space
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics',
                  index: 2, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.settings_rounded, label: 'Settings',
                  index: 3, current: _currentIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  void _openAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, sc) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BlocProvider.value(
              value: context.read<TaskBloc>(),
              child: const AddTaskScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppConstants.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryBlue.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                  size: 22,
                  color: selected ? AppTheme.primaryBlue : theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 4),
              Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primaryBlue : theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
