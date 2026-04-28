import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../blocs/settings_bloc.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [

              // ── Appearance ────────────────────────────────────────────────
              _SectionHeader(label: '🎨 Appearance'),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _ThemeTile(current: state.themeMode),
              ]).animate().slideY(begin: 0.1).fadeIn(),

              const SizedBox(height: 24),

              // ── Notifications ─────────────────────────────────────────────
              _SectionHeader(label: '🔔 Notifications'),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _SwitchTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppTheme.accentOrange,
                  title: 'Enable Notifications',
                  subtitle: 'Get reminders and deadline alerts',
                  value: state.notificationsEnabled,
                  onChanged: (v) => context.read<SettingsBloc>()
                      .add(ToggleNotificationsEvent(v)),
                ),
                if (state.notificationsEnabled) ...[
                  const Divider(height: 1),
                  _TimeTile(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: AppTheme.accentOrange,
                    title: 'Morning Reminder',
                    subtitle: 'Daily planning summary',
                    time: state.morningReminderTime,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: state.morningReminderTime,
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(colorScheme:
                            Theme.of(c).colorScheme.copyWith(primary: AppTheme.primaryBlue)),
                          child: child!),
                      );
                      if (t != null && context.mounted) {
                        context.read<SettingsBloc>().add(SetMorningReminderEvent(t));
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _TimeTile(
                    icon: Icons.nightlight_round,
                    iconColor: AppTheme.primaryPurple,
                    title: 'Evening Review',
                    subtitle: 'End of day summary',
                    time: state.eveningReminderTime,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: state.eveningReminderTime,
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(colorScheme:
                            Theme.of(c).colorScheme.copyWith(primary: AppTheme.primaryBlue)),
                          child: child!),
                      );
                      if (t != null && context.mounted) {
                        context.read<SettingsBloc>().add(SetEveningReminderEvent(t));
                      }
                    },
                  ),
                ],
              ]).animate().slideY(begin: 0.1, delay: 50.ms).fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // ── Productivity ──────────────────────────────────────────────
              _SectionHeader(label: '⚡ Smart Scheduler'),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _InfoTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppTheme.primaryBlue,
                  title: 'Algorithm',
                  value: 'Knapsack + Priority Queue'),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.timer_rounded,
                  iconColor: AppTheme.accentTeal,
                  title: 'Buffer Between Tasks',
                  value: '15 minutes'),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.work_history_rounded,
                  iconColor: AppTheme.primaryPurple,
                  title: 'Max Daily Hours',
                  value: '10 hours'),
              ]).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // ── Data ──────────────────────────────────────────────────────
              _SectionHeader(label: '💾 Data & Backup'),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _ActionTile(
                  icon: Icons.backup_rounded,
                  iconColor: AppTheme.accentTeal,
                  title: 'Backup Data',
                  subtitle: 'Export tasks to local file',
                  onTap: () => _showComingSoon(context)),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.restore_rounded,
                  iconColor: AppTheme.primaryBlue,
                  title: 'Restore Data',
                  subtitle: 'Import from backup file',
                  onTap: () => _showComingSoon(context)),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: AppTheme.primaryPurple,
                  title: 'Cloud Sync',
                  subtitle: 'Sync with Firebase (coming soon)',
                  onTap: () => _showComingSoon(context)),
              ]).animate().slideY(begin: 0.1, delay: 150.ms).fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(label: 'ℹ️ About'),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _InfoTile(icon: Icons.apps_rounded, iconColor: AppTheme.primaryBlue,
                  title: 'App Name', value: 'WorkCalender'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.info_outline_rounded, iconColor: AppTheme.accentTeal,
                  title: 'Version', value: '1.0.0'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.code_rounded, iconColor: AppTheme.primaryPurple,
                  title: 'Built With', value: 'Flutter + BLoC'),
              ]).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // ── App info ─────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text('WorkCalender', style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800)),
                    Text('Smart Productivity & Planning',
                      style: theme.textTheme.bodyMedium),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon! This feature is in development.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}

// ─── Component Widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode current;
  const _ThemeTile({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.palette_rounded, color: AppTheme.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Theme Mode', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('Choose your preferred look', style: theme.textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 8),
          DropdownButton<ThemeMode>(
            value: current,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(14),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (v) {
              if (v != null) context.read<SettingsBloc>().add(ToggleThemeEvent(v));
            },
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.value, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ])),
        Switch(value: value, onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); }),
      ]),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({
    required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.time, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ])),
          Text(time.format(context),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, value;
  const _InfoTile({required this.icon, required this.iconColor, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}
