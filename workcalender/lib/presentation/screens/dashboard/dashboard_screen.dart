import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:workcalender/presentation/blocs/task_bloc.dart';
import 'package:workcalender/presentation/widgets/common/task_card.dart';
import 'package:workcalender/presentation/widgets/common/section_header.dart';
import 'package:workcalender/core/theme/app_theme.dart';
import 'package:workcalender/core/constants/app_constants.dart';
import 'package:workcalender/data/models/task_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>()
        ..add(DetectMissedTasksEvent())
        ..add(LoadTasksEvent(DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskLoaded) {
            return _buildDashboard(context, state, theme, isDark);
          }
          if (state is TaskError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, TaskLoaded state, ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final greeting = _greeting();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final remainingHours = endOfDay.difference(now).inMinutes / 60;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── App Bar ───────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          stretch: true,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.blurBackground, StretchMode.fadeTitle],
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A2040), const Color(0xFF0D0F1A)]
                      : [AppTheme.primaryBlue, const Color(0xFF6B4EFF)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(DateFormat('EEEE, MMMM d').format(now),
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          _ScoreRing(score: state.productivityScore),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Today\'s Progress',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60)),
                              Text('${state.completedToday}/${state.todayTasks.length} tasks',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: state.completionRate,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Stats Row ─────────────────────────────────────────────────
              _StatsRow(
                completed: state.completedToday,
                pending: state.pendingToday,
                missed: state.missedTasks.length,
                remainingHours: remainingHours,
              ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Best Next Task ─────────────────────────────────────────────
              if (state.bestNextTask != null) ...[
                const SectionHeader(title: '⚡ Do This Next', showAll: false),
                const SizedBox(height: 12),
                _BestNextCard(task: state.bestNextTask!)
                    .animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(delay: 100.ms),
                const SizedBox(height: 24),
              ],

              // ── Today's Tasks ─────────────────────────────────────────────
              SectionHeader(
                title: '📋 Today\'s Tasks',
                count: state.todayTasks.length,
                showAll: true,
                onTap: () {},
              ),
              const SizedBox(height: 12),

              if (state.todayTasks.isEmpty)
                _EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Nothing Scheduled',
                  subtitle: 'Tap + to add your first task',
                ).animate().fadeIn(delay: 200.ms)
              else
                ...state.todayTasks.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: e.value,
                      onComplete: () => context.read<TaskBloc>().add(CompleteTaskEvent(e.value.id)),
                      onTap: () => _openTask(context, e.value),
                      onDelete: () => context.read<TaskBloc>().add(DeleteTaskEvent(e.value.id)),
                    ).animate()
                     .slideX(begin: 0.1, duration: 350.ms, delay: Duration(milliseconds: 150 + e.key * 60))
                     .fadeIn(delay: Duration(milliseconds: 150 + e.key * 60)),
                  ),
                ),

              // ── Missed Tasks ─────────────────────────────────────────────
              if (state.missedTasks.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: '⚠️ Missed Tasks', showAll: false),
                const SizedBox(height: 12),
                ...state.missedTasks.take(3).map((task) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onComplete: () => context.read<TaskBloc>().add(CompleteTaskEvent(task.id)),
                      onTap: () => _openTask(context, task),
                      onDelete: () => context.read<TaskBloc>().add(DeleteTaskEvent(task.id)),
                      showMissedBadge: true,
                    ),
                  ),
                ),
              ],

              // ── Smart Suggestions ─────────────────────────────────────────
              const SizedBox(height: 24),
              const SectionHeader(title: '💡 Smart Suggestions', showAll: false),
              const SizedBox(height: 12),
              _SmartSuggestions(state: state)
                  .animate().fadeIn(delay: 400.ms),
            ]),
          ),
        ),
      ],
    );
  }

  void _openTask(BuildContext context, Task task) {
    Navigator.of(context).pushNamed('/add-task', arguments: task);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }
}

// ─── Components ──────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final double score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 36,
      lineWidth: 5,
      percent: (score / 100).clamp(0.0, 1.0),
      center: Text(
        '${score.round()}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
      ),
      progressColor: Colors.white,
      backgroundColor: Colors.white24,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completed, pending, missed;
  final double remainingHours;
  const _StatsRow({
    required this.completed, required this.pending,
    required this.missed, required this.remainingHours,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '$completed', label: 'Done', color: AppTheme.priorityLow,
            icon: Icons.check_circle_rounded),
        const SizedBox(width: 12),
        _StatCard(value: '$pending', label: 'Pending', color: AppTheme.primaryBlue,
            icon: Icons.radio_button_unchecked_rounded),
        const SizedBox(width: 12),
        _StatCard(value: '$missed', label: 'Missed', color: AppTheme.priorityHigh,
            icon: Icons.warning_amber_rounded),
        const SizedBox(width: 12),
        _StatCard(
            value: '${remainingHours.toStringAsFixed(1)}h',
            label: 'Left', color: AppTheme.accentTeal,
            icon: Icons.access_time_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: color, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _BestNextCard extends StatelessWidget {
  final Task task;
  const _BestNextCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Now', style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(task.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${task.durationMinutes} min • ${task.priorityLabel} Priority',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}

class _SmartSuggestions extends StatelessWidget {
  final TaskLoaded state;
  const _SmartSuggestions({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    final suggestions = _generateSuggestions(state);

    return Column(
      children: suggestions.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: s.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(s.icon, color: s.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(s.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  List<_Suggestion> _generateSuggestions(TaskLoaded state) {
    final suggestions = <_Suggestion>[];

    if (state.missedTasks.isNotEmpty) {
      suggestions.add(_Suggestion(
        icon: Icons.refresh_rounded,
        color: AppTheme.accentOrange,
        title: 'Reschedule ${state.missedTasks.length} missed task(s)',
        subtitle: 'Let AI find the best slot for you',
      ));
    }

    if (state.completionRate > 0.7) {
      suggestions.add(_Suggestion(
        icon: Icons.star_rounded,
        color: AppTheme.priorityLow,
        title: 'Great progress today!',
        subtitle: 'You\'ve completed ${(state.completionRate * 100).round()}% of your tasks',
      ));
    }

    if (state.pendingToday > 5) {
      suggestions.add(_Suggestion(
        icon: Icons.compress_rounded,
        color: AppTheme.primaryBlue,
        title: 'Heavy day ahead',
        subtitle: 'Consider splitting ${state.pendingToday} tasks across multiple days',
      ));
    }

    if (suggestions.isEmpty) {
      suggestions.add(_Suggestion(
        icon: Icons.rocket_launch_rounded,
        color: AppTheme.primaryPurple,
        title: 'Ready to be productive!',
        subtitle: 'Start with your highest priority task to build momentum',
      ));
    }

    return suggestions;
  }
}

class _Suggestion {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _Suggestion({required this.icon, required this.color, required this.title, required this.subtitle});
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
