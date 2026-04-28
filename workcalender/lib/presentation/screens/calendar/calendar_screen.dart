import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../blocs/task_bloc.dart';
import '../../widgets/common/task_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasksEvent(_selectedDay));
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    context.read<TaskBloc>().add(LoadTasksEvent(selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          // View toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormatButton(
                  label: 'M', selected: _format == CalendarFormat.month,
                  onTap: () => setState(() => _format = CalendarFormat.month)),
                _FormatButton(
                  label: 'W', selected: _format == CalendarFormat.twoWeeks,
                  onTap: () => setState(() => _format = CalendarFormat.twoWeeks)),
                _FormatButton(
                  label: 'D', selected: _format == CalendarFormat.week,
                  onTap: () => setState(() => _format = CalendarFormat.week)),
              ],
            ),
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final allTasks = state is TaskLoaded ? state.tasks : <Task>[];
          final dayTasks = state is TaskLoaded ? state.todayTasks : <Task>[];

          // Build event map
          final Map<DateTime, List<Task>> eventMap = {};
          for (final task in allTasks) {
            final key = DateTime(task.date.year, task.date.month, task.date.day);
            eventMap.putIfAbsent(key, () => []).add(task);
          }

          List<Task> getEventsForDay(DateTime day) {
            final key = DateTime(day.year, day.month, day.day);
            return eventMap[key] ?? [];
          }

          return Column(
            children: [
              // Calendar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isDark ? [] : [
                    BoxShadow(color: Colors.black.withOpacity(0.06),
                      blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  eventLoader: getEventsForDay,
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (f) => setState(() => _format = f),
                  onPageChanged: (focused) => setState(() => _focusedDay = focused),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: AppTheme.primaryBlue, fontWeight: FontWeight.w700),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primaryBlue, shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.accentTeal, shape: BoxShape.circle),
                    markersMaxCount: 3,
                    markerSize: 5,
                    defaultTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    weekendTextStyle: TextStyle(color: AppTheme.priorityHigh.withOpacity(0.8)),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                    leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: theme.textTheme.bodyLarge?.color),
                    rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: theme.textTheme.bodyLarge?.color),
                    headerPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(
                      color: AppTheme.priorityHigh.withOpacity(0.7),
                      fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),

              // Day summary
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDay),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (dayTasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${dayTasks.length} tasks',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Task list for selected day
              Expanded(
                child: state is TaskLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dayTasks.isEmpty
                        ? _EmptyDayState(date: _selectedDay)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: dayTasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => TaskCard(
                              task: dayTasks[i],
                              onComplete: () => context.read<TaskBloc>()
                                  .add(CompleteTaskEvent(dayTasks[i].id)),
                              onTap: () {},
                              onDelete: () => context.read<TaskBloc>()
                                  .add(DeleteTaskEvent(dayTasks[i].id)),
                            ).animate()
                             .slideX(begin: 0.1, duration: 300.ms,
                               delay: Duration(milliseconds: i * 60))
                             .fadeIn(delay: Duration(milliseconds: i * 60)),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  final DateTime date;
  const _EmptyDayState({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(date, DateTime.now());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 64,
            color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(isToday ? 'Nothing today!' : 'No tasks',
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Tap + to add a task for this day',
            style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
