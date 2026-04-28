import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int priority; // 0-4
  final String status;
  final String? categoryId;
  final String? notes;
  final String repeat;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isAllDay;
  final List<String> tags;
  final double estimatedValue; // For knapsack algo

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes = 30,
    this.priority = AppConstants.priorityMedium,
    this.status = AppConstants.statusPending,
    this.categoryId,
    this.notes,
    this.repeat = AppConstants.repeatNone,
    required this.createdAt,
    this.completedAt,
    this.isAllDay = false,
    this.tags = const [],
    this.estimatedValue = 1.0,
  });

  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isPending => status == AppConstants.statusPending;
  bool get isMissed => status == AppConstants.statusMissed;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isPostponed => status == AppConstants.statusPostponed;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final deadlineTime = endTime ?? DateTime(date.year, date.month, date.day, 23, 59);
    return now.isAfter(deadlineTime);
  }

  double get urgencyScore {
    final hoursUntilDeadline = _hoursUntilDeadline();
    final priorityMultiplier = [0.5, 1.0, 2.0, 3.5, 5.0][priority.clamp(0, 4)];

    if (hoursUntilDeadline <= 0) return 100.0 * priorityMultiplier;
    if (hoursUntilDeadline <= 1) return 90.0 * priorityMultiplier;
    if (hoursUntilDeadline <= 3) return 70.0 * priorityMultiplier;
    if (hoursUntilDeadline <= 6) return 50.0 * priorityMultiplier;
    if (hoursUntilDeadline <= 24) return 30.0 * priorityMultiplier;
    return (20.0 - hoursUntilDeadline * 0.1).clamp(1.0, 20.0) * priorityMultiplier;
  }

  double _hoursUntilDeadline() {
    final deadline = endTime ?? DateTime(date.year, date.month, date.day, 23, 59);
    return deadline.difference(DateTime.now()).inMinutes / 60.0;
  }

  String get priorityLabel {
    switch (priority) {
      case 0: return 'None';
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      case 4: return 'Urgent';
      default: return 'Medium';
    }
  }

  String get statusLabel {
    switch (status) {
      case AppConstants.statusPending: return 'Pending';
      case AppConstants.statusInProgress: return 'In Progress';
      case AppConstants.statusCompleted: return 'Completed';
      case AppConstants.statusMissed: return 'Missed';
      case AppConstants.statusPostponed: return 'Postponed';
      default: return 'Pending';
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? priority,
    String? status,
    String? categoryId,
    String? notes,
    String? repeat,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isAllDay,
    List<String>? tags,
    double? estimatedValue,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      repeat: repeat ?? this.repeat,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isAllDay: isAllDay ?? this.isAllDay,
      tags: tags ?? this.tags,
      estimatedValue: estimatedValue ?? this.estimatedValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'priority': priority,
      'status': status,
      'categoryId': categoryId,
      'notes': notes,
      'repeat': repeat,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'isAllDay': isAllDay ? 1 : 0,
      'tags': tags.join(','),
      'estimatedValue': estimatedValue,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      startTime: map['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
          : null,
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      durationMinutes: map['durationMinutes'] ?? 30,
      priority: map['priority'] ?? AppConstants.priorityMedium,
      status: map['status'] ?? AppConstants.statusPending,
      categoryId: map['categoryId'],
      notes: map['notes'],
      repeat: map['repeat'] ?? AppConstants.repeatNone,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      isAllDay: (map['isAllDay'] ?? 0) == 1,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      estimatedValue: (map['estimatedValue'] ?? 1.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id, title, description, date, startTime, endTime,
    durationMinutes, priority, status, categoryId, notes,
    repeat, createdAt, completedAt, isAllDay, tags, estimatedValue,
  ];
}
