import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../blocs/task_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/repositories.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<AnalyticsLog> _logs = [];
  bool _loading = true;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _selectedDays));
    final logs = await AnalyticsRepository().getLogsInRange(start, end);
    setState(() { _logs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avgScore = _logs.isEmpty ? 0.0
        : _logs.map((l) => l.productivityScore).reduce((a, b) => a + b) / _logs.length;
    final totalCompleted = _logs.fold<int>(0, (s, l) => s + l.tasksCompleted);
    final totalMissed = _logs.fold<int>(0, (s, l) => s + l.tasksMissed);
    final totalWorked = _logs.fold<int>(0, (s, l) => s + l.totalMinutesWorked);
    final completionRate = _logs.isEmpty ? 0.0
        : _logs.fold<double>(0, (s, l) => s + l.completionRate) / _logs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              segments: const [
                ButtonSegment(value: 7, label: Text('7d', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 30, label: Text('30d', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 90, label: Text('90d', style: TextStyle(fontSize: 12))),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (s) {
                setState(() => _selectedDays = s.first);
                _load();
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _EmptyAnalytics()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Score Banner ────────────────────────────────────
                          _ScoreBanner(score: avgScore)
                              .animate().slideY(begin: 0.2).fadeIn(),

                          const SizedBox(height: 20),

                          // ── Summary Cards ───────────────────────────────────
                          Row(children: [
                            _SummaryCard(
                              label: 'Completed', value: '$totalCompleted',
                              icon: Icons.check_circle_rounded, color: AppTheme.priorityLow),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Missed', value: '$totalMissed',
                              icon: Icons.cancel_rounded, color: AppTheme.priorityHigh),
                          ]).animate().slideY(begin: 0.2, delay: 100.ms).fadeIn(delay: 100.ms),

                          const SizedBox(height: 12),

                          Row(children: [
                            _SummaryCard(
                              label: 'Hours Worked',
                              value: '${(totalWorked / 60).toStringAsFixed(1)}h',
                              icon: Icons.timer_rounded, color: AppTheme.primaryBlue),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Completion',
                              value: '${(completionRate * 100).round()}%',
                              icon: Icons.percent_rounded, color: AppTheme.accentTeal),
                          ]).animate().slideY(begin: 0.2, delay: 150.ms).fadeIn(delay: 150.ms),

                          const SizedBox(height: 24),

                          // ── Productivity Chart ──────────────────────────────
                          _ChartCard(
                            title: 'Productivity Score',
                            subtitle: 'Last $_selectedDays days',
                            child: _ProductivityChart(logs: _logs),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 20),

                          // ── Task Completion Chart ───────────────────────────
                          _ChartCard(
                            title: 'Tasks Overview',
                            subtitle: 'Completed vs Missed',
                            child: _CompletionChart(logs: _logs),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 20),

                          // ── Best Days ───────────────────────────────────────
                          _BestDaysCard(logs: _logs)
                              .animate().fadeIn(delay: 400.ms),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Components ──────────────────────────────────────────────────────────────

class _ScoreBanner extends StatelessWidget {
  final double score;
  const _ScoreBanner({required this.score});

  String get _grade {
    if (score >= 85) return 'Excellent 🌟';
    if (score >= 70) return 'Great 👍';
    if (score >= 50) return 'Good 😊';
    if (score >= 30) return 'Fair 📈';
    return 'Needs Work 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Average Score', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_grade, style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text('${score.round()}',
            style: const TextStyle(color: Colors.white,
              fontSize: 56, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProductivityChart extends StatelessWidget {
  final List<AnalyticsLog> logs;
  const _ProductivityChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox(height: 160);
    final spots = logs.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.productivityScore)).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x1A000000), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.round()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)))),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= logs.length) return const SizedBox();
                  return Text(DateFormat('d/M').format(logs[i].date),
                    style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryBlue,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryBlue.withOpacity(0.1),
              ),
            ),
          ],
          minY: 0, maxY: 100,
        ),
      ),
    );
  }
}

class _CompletionChart extends StatelessWidget {
  final List<AnalyticsLog> logs;
  const _CompletionChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox(height: 160);
    final completed = logs.fold<int>(0, (s, l) => s + l.tasksCompleted).toDouble();
    final missed = logs.fold<int>(0, (s, l) => s + l.tasksMissed).toDouble();
    final pending = (logs.fold<int>(0, (s, l) => s + l.tasksTotal) - completed - missed)
        .clamp(0, double.infinity);

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  if (completed > 0) PieChartSectionData(
                    color: AppTheme.priorityLow, value: completed,
                    title: '${((completed / (completed + missed + pending)) * 100).round()}%',
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 60,
                  ),
                  if (missed > 0) PieChartSectionData(
                    color: AppTheme.priorityHigh, value: missed,
                    title: '${((missed / (completed + missed + pending)) * 100).round()}%',
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 60,
                  ),
                  if (pending > 0) PieChartSectionData(
                    color: AppTheme.priorityNone, value: pending,
                    title: '',
                    radius: 60,
                  ),
                ],
                centerSpaceRadius: 30,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(color: AppTheme.priorityLow, label: 'Completed'),
              const SizedBox(height: 10),
              _Legend(color: AppTheme.priorityHigh, label: 'Missed'),
              const SizedBox(height: 10),
              _Legend(color: AppTheme.priorityNone, label: 'Pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _BestDaysCard extends StatelessWidget {
  final List<AnalyticsLog> logs;
  const _BestDaysCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sorted = [...logs]..sort((a, b) => b.productivityScore.compareTo(a.productivityScore));
    final best = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Best Days', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Your most productive days', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          ...best.asMap().entries.map((e) {
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(medals[e.key], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE, MMM d').format(e.value.date),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${e.value.tasksCompleted} tasks completed',
                          style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${e.value.productivityScore.round()}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No data yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Start completing tasks to see your analytics',
            style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
