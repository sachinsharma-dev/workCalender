import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showMissedBadge;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onTap,
    required this.onDelete,
    this.showMissedBadge = false,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 0: return AppTheme.priorityNone;
      case 1: return AppTheme.priorityLow;
      case 2: return AppTheme.priorityMedium;
      case 3: return AppTheme.priorityHigh;
      case 4: return AppTheme.accentPink;
      default: return AppTheme.priorityNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = task.isCompleted;
    final isMissed = task.isMissed || showMissedBadge;

    return Dismissible(
      key: Key(task.id),
      background: _dismissBackground(isRight: false),
      secondaryBackground: _dismissBackground(isRight: true),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onDelete();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.priorityLow.withOpacity(0.3)
                  : isMissed
                      ? AppTheme.priorityHigh.withOpacity(0.3)
                      : isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: isCompleted || isMissed ? 1.5 : 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 70,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.priorityLow : _priorityColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),

              // Checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onComplete();
                  },
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.priorityLow : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? AppTheme.priorityLow : _priorityColor,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? theme.textTheme.bodySmall?.color
                                    : theme.textTheme.titleMedium?.color,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMissed && !isCompleted)
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.priorityHigh.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Missed',
                                style: TextStyle(color: AppTheme.priorityHigh,
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (task.startTime != null) ...[
                            Icon(Icons.access_time_rounded, size: 12,
                              color: theme.textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(task.startTime!),
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.timer_rounded, size: 12,
                            color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(_formatDuration(task.durationMinutes),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                          const SizedBox(width: 8),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _priorityColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(task.priorityLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11, color: _priorityColor)),
                        ],
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description!,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ),

              const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissBackground({required bool isRight}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isRight ? AppTheme.priorityHigh : AppTheme.priorityLow,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        isRight ? Icons.delete_rounded : Icons.check_rounded,
        color: Colors.white, size: 24),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
