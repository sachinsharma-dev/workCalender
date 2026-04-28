import 'dart:math';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';

/// WorkCalender Smart Scheduler
///
/// Implements multiple scheduling algorithms:
/// 1. Priority Queue  – sorts by urgency + priority score
/// 2. Knapsack        – fits max-value tasks in available time
/// 3. Deadline-First  – EDF (Earliest Deadline First) ordering
/// 4. Greedy          – picks best next task at each step
/// 5. Auto-Reschedule – finds new slots for missed tasks
class SmartScheduler {
  static final SmartScheduler instance = SmartScheduler._();
  SmartScheduler._();

  // ─── Priority Queue Scheduling ──────────────────────────────────────────────

  /// Returns tasks ordered by urgency score (priority + deadline proximity)
  List<Task> priorityQueueSort(List<Task> tasks) {
    final pending = tasks.where((t) => t.isPending || t.isInProgress).toList();
    pending.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    return pending;
  }

  // ─── Knapsack Scheduling ────────────────────────────────────────────────────

  /// 0/1 Knapsack: select tasks that maximize value within available minutes
  ScheduleResult knapsackSchedule({
    required List<Task> tasks,
    required int availableMinutes,
    DateTime? workStart,
  }) {
    final eligible = tasks
        .where((t) => t.isPending || t.isInProgress)
        .toList();

    if (eligible.isEmpty || availableMinutes <= 0) {
      return ScheduleResult(scheduledTasks: [], postponedTasks: eligible, totalMinutes: 0, totalValue: 0);
    }

    final n = eligible.length;
    // Scale values: priority * (1 + urgency/10)
    final values = eligible.map((t) =>
        (t.priority + 1) * (1 + t.urgencyScore / 10)).toList();
    final weights = eligible.map((t) => t.durationMinutes).toList();

    // DP table
    final dp = List.generate(n + 1,
        (_) => List<double>.filled(availableMinutes + 1, 0.0));

    for (int i = 1; i <= n; i++) {
      for (int w = 0; w <= availableMinutes; w++) {
        dp[i][w] = dp[i - 1][w];
        if (weights[i - 1] <= w) {
          final withItem = dp[i - 1][w - weights[i - 1]] + values[i - 1];
          if (withItem > dp[i][w]) dp[i][w] = withItem;
        }
      }
    }

    // Backtrack
    final selected = <bool>List.filled(n, false);
    int w = availableMinutes;
    for (int i = n; i > 0; i--) {
      if (dp[i][w] != dp[i - 1][w]) {
        selected[i - 1] = true;
        w -= weights[i - 1];
      }
    }

    final scheduled = <Task>[];
    final postponed = <Task>[];
    int totalMinutes = 0;
    double totalValue = 0;

    for (int i = 0; i < n; i++) {
      if (selected[i]) {
        scheduled.add(eligible[i]);
        totalMinutes += weights[i];
        totalValue += values[i];
      } else {
        postponed.add(eligible[i]);
      }
    }

    // Sort scheduled by deadline first
    scheduled.sort((a, b) {
      final aDeadline = a.endTime ?? DateTime(a.date.year, a.date.month, a.date.day, 23, 59);
      final bDeadline = b.endTime ?? DateTime(b.date.year, b.date.month, b.date.day, 23, 59);
      return aDeadline.compareTo(bDeadline);
    });

    // Assign time slots
    DateTime currentTime = workStart ?? DateTime.now();
    final scheduledWithSlots = scheduled.map((task) {
      final start = currentTime;
      final end = currentTime.add(Duration(minutes: task.durationMinutes + AppConstants.schedulerBufferMinutes));
      currentTime = end;
      return task.copyWith(startTime: start, endTime: end);
    }).toList();

    return ScheduleResult(
      scheduledTasks: scheduledWithSlots,
      postponedTasks: postponed,
      totalMinutes: totalMinutes,
      totalValue: totalValue,
    );
  }

  // ─── Earliest Deadline First ────────────────────────────────────────────────

  List<Task> earliestDeadlineFirst(List<Task> tasks) {
    final eligible = tasks.where((t) => t.isPending || t.isInProgress).toList();
    eligible.sort((a, b) {
      final aDeadline = a.endTime ?? DateTime(a.date.year, a.date.month, a.date.day, 23, 59);
      final bDeadline = b.endTime ?? DateTime(b.date.year, b.date.month, b.date.day, 23, 59);
      return aDeadline.compareTo(bDeadline);
    });
    return eligible;
  }

  // ─── Greedy Next Task ───────────────────────────────────────────────────────

  /// Pick the single best task to do right now
  Task? getBestNextTask(List<Task> tasks, {int availableMinutes = 120}) {
    final eligible = tasks
        .where((t) =>
            (t.isPending || t.isInProgress) &&
            t.durationMinutes <= availableMinutes)
        .toList();

    if (eligible.isEmpty) return null;

    eligible.sort((a, b) {
      // Score = urgency * 0.5 + priority * 0.3 + value_density * 0.2
      final aScore = a.urgencyScore * 0.5 +
          a.priority * 10 * 0.3 +
          (a.estimatedValue / max(1, a.durationMinutes)) * 100 * 0.2;
      final bScore = b.urgencyScore * 0.5 +
          b.priority * 10 * 0.3 +
          (b.estimatedValue / max(1, b.durationMinutes)) * 100 * 0.2;
      return bScore.compareTo(aScore);
    });

    return eligible.first;
  }

  // ─── Auto-Reschedule ────────────────────────────────────────────────────────

  List<RescheduleProposal> autoReschedule({
    required List<Task> missedTasks,
    required List<Task> existingTasks,
    int daysAhead = 7,
  }) {
    final proposals = <RescheduleProposal>[];
    final now = DateTime.now();

    for (final missed in missedTasks) {
      // Find first available slot in next daysAhead days
      final slot = _findAvailableSlot(
        task: missed,
        existingTasks: existingTasks,
        searchFrom: now,
        daysAhead: daysAhead,
      );

      if (slot != null) {
        proposals.add(RescheduleProposal(
          originalTask: missed,
          proposedDate: slot.date,
          proposedStartTime: slot.startTime,
          proposedEndTime: slot.endTime,
          reason: 'Best available slot with minimal conflicts',
        ));
      }
    }

    return proposals;
  }

  _TimeSlot? _findAvailableSlot({
    required Task task,
    required List<Task> existingTasks,
    required DateTime searchFrom,
    required int daysAhead,
  }) {
    final duration = task.durationMinutes;

    for (int day = 0; day < daysAhead; day++) {
      final targetDate = searchFrom.add(Duration(days: day));
      final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day, 8, 0);
      final dayEnd = DateTime(targetDate.year, targetDate.month, targetDate.day, 22, 0);

      // Get tasks for this day
      final dayTasks = existingTasks.where((t) =>
          t.date.year == targetDate.year &&
          t.date.month == targetDate.month &&
          t.date.day == targetDate.day &&
          !t.isCompleted).toList();

      dayTasks.sort((a, b) => (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));

      // Find free slots
      DateTime slotStart = day == 0 ? (searchFrom.isAfter(dayStart) ? searchFrom : dayStart) : dayStart;

      for (final existing in dayTasks) {
        final existStart = existing.startTime ?? existing.date;
        final existEnd = existing.endTime ??
            existStart.add(Duration(minutes: existing.durationMinutes));

        if (slotStart.add(Duration(minutes: duration)).isBefore(existStart)) {
          // Slot found before this task
          return _TimeSlot(
            date: targetDate,
            startTime: slotStart,
            endTime: slotStart.add(Duration(minutes: duration)),
          );
        }
        if (existEnd.isAfter(slotStart)) slotStart = existEnd;
      }

      // Check end of day
      if (slotStart.add(Duration(minutes: duration)).isBefore(dayEnd)) {
        return _TimeSlot(
          date: targetDate,
          startTime: slotStart,
          endTime: slotStart.add(Duration(minutes: duration)),
        );
      }
    }
    return null;
  }

  // ─── Daily Optimization ─────────────────────────────────────────────────────

  DailyPlan optimizeDailyPlan({
    required List<Task> allTasks,
    required DateTime date,
    int workdayStartHour = 8,
    int workdayEndHour = 22,
  }) {
    final dayTasks = allTasks.where((t) =>
        t.date.year == date.year &&
        t.date.month == date.month &&
        t.date.day == date.day).toList();

    final now = DateTime.now();
    final dayStart = DateTime(date.year, date.month, date.day, workdayStartHour);
    final dayEnd = DateTime(date.year, date.month, date.day, workdayEndHour);

    final effectiveStart = now.isAfter(dayStart) ? now : dayStart;
    final availableMinutes = dayEnd.difference(effectiveStart).inMinutes;

    final knapsackResult = knapsackSchedule(
      tasks: dayTasks,
      availableMinutes: availableMinutes.clamp(0, AppConstants.maxDailyWorkHours * 60),
      workStart: effectiveStart,
    );

    final missedTasks = dayTasks.where((t) => t.isMissed).toList();
    final bestNext = getBestNextTask(dayTasks, availableMinutes: availableMinutes);

    final completedToday = dayTasks.where((t) => t.isCompleted).length;
    final totalToday = dayTasks.length;
    final completionRate = totalToday == 0 ? 0.0 : completedToday / totalToday;
    final productivityScore = _calculateProductivityScore(dayTasks);

    return DailyPlan(
      date: date,
      scheduledTasks: knapsackResult.scheduledTasks,
      postponedTasks: knapsackResult.postponedTasks,
      missedTasks: missedTasks,
      bestNextTask: bestNext,
      availableMinutes: availableMinutes,
      completionRate: completionRate,
      productivityScore: productivityScore,
    );
  }

  double _calculateProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final highPriorityCompleted = tasks
        .where((t) => t.isCompleted && t.priority >= AppConstants.priorityHigh)
        .length;
    final highPriorityTotal = tasks
        .where((t) => t.priority >= AppConstants.priorityHigh)
        .length;

    final completionScore = (completed / total) * AppConstants.completionWeight;
    final priorityScore = highPriorityTotal == 0
        ? AppConstants.priorityWeight
        : (highPriorityCompleted / highPriorityTotal) * AppConstants.priorityWeight;

    return ((completionScore + priorityScore) * 100).clamp(0, 100);
  }

  // ─── NLP Task Parser ────────────────────────────────────────────────────────

  ParsedTaskInput parseNaturalLanguage(String input) {
    final lower = input.toLowerCase();
    String title = input;
    DateTime? date;
    DateTime? startTime;
    int durationMinutes = 30;
    int priority = AppConstants.priorityMedium;

    // Date parsing
    final now = DateTime.now();
    if (lower.contains('today')) {
      date = DateTime(now.year, now.month, now.day);
    } else if (lower.contains('tomorrow')) {
      date = now.add(const Duration(days: 1));
    } else {
      final weekdays = {
        'monday': 1, 'tuesday': 2, 'wednesday': 3,
        'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
      };
      for (final entry in weekdays.entries) {
        if (lower.contains(entry.key)) {
          int daysUntil = (entry.value - now.weekday) % 7;
          if (daysUntil == 0) daysUntil = 7;
          date = now.add(Duration(days: daysUntil));
          break;
        }
      }
    }
    date ??= DateTime(now.year, now.month, now.day);

    // Time parsing: e.g. "7pm", "14:00", "7:30am"
    final timeRegex = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(lower);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final ampm = timeMatch.group(3)?.toLowerCase();
      if (ampm == 'pm' && hour != 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      startTime = DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Duration parsing: "for 2 hours", "30 minutes"
    final durationRegex = RegExp(
        r'for\s+(\d+(?:\.\d+)?)\s*(hour|hr|h|minute|min|m)s?', caseSensitive: false);
    final durMatch = durationRegex.firstMatch(lower);
    if (durMatch != null) {
      final amount = double.parse(durMatch.group(1)!);
      final unit = durMatch.group(2)!.toLowerCase();
      if (unit.startsWith('h')) {
        durationMinutes = (amount * 60).round();
      } else {
        durationMinutes = amount.round();
      }
    }

    // Priority parsing
    if (lower.contains('urgent') || lower.contains('asap') || lower.contains('critical')) {
      priority = AppConstants.priorityUrgent;
    } else if (lower.contains('important') || lower.contains('high priority')) {
      priority = AppConstants.priorityHigh;
    } else if (lower.contains('low priority') || lower.contains('whenever')) {
      priority = AppConstants.priorityLow;
    }

    // Title cleaning - remove time/date/duration keywords
    title = input
        .replaceAll(RegExp(r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(for\s+\d+(?:\.\d+)?\s*(hour|hr|h|minute|min|m)s?)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(urgent|asap|critical|important|high priority|low priority)\b', caseSensitive: false), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) title = input;

    return ParsedTaskInput(
      title: title.isNotEmpty ? _capitalize(title) : input,
      date: date,
      startTime: startTime,
      durationMinutes: durationMinutes,
      priority: priority,
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Result Objects ─────────────────────────────────────────────────────────

class ScheduleResult {
  final List<Task> scheduledTasks;
  final List<Task> postponedTasks;
  final int totalMinutes;
  final double totalValue;
  const ScheduleResult({
    required this.scheduledTasks,
    required this.postponedTasks,
    required this.totalMinutes,
    required this.totalValue,
  });
}

class RescheduleProposal {
  final Task originalTask;
  final DateTime proposedDate;
  final DateTime proposedStartTime;
  final DateTime proposedEndTime;
  final String reason;
  const RescheduleProposal({
    required this.originalTask,
    required this.proposedDate,
    required this.proposedStartTime,
    required this.proposedEndTime,
    required this.reason,
  });
}

class DailyPlan {
  final DateTime date;
  final List<Task> scheduledTasks;
  final List<Task> postponedTasks;
  final List<Task> missedTasks;
  final Task? bestNextTask;
  final int availableMinutes;
  final double completionRate;
  final double productivityScore;
  const DailyPlan({
    required this.date,
    required this.scheduledTasks,
    required this.postponedTasks,
    required this.missedTasks,
    this.bestNextTask,
    required this.availableMinutes,
    required this.completionRate,
    required this.productivityScore,
  });
}

class ParsedTaskInput {
  final String title;
  final DateTime? date;
  final DateTime? startTime;
  final int durationMinutes;
  final int priority;
  const ParsedTaskInput({
    required this.title,
    this.date,
    this.startTime,
    this.durationMinutes = 30,
    this.priority = 2,
  });
}

class _TimeSlot {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  const _TimeSlot({required this.date, required this.startTime, required this.endTime});
}
