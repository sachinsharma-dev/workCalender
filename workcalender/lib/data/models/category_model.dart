import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final int colorValue;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    this.icon = 'grid',
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      colorValue: map['colorValue'],
      icon: map['icon'] ?? 'grid',
      isDefault: (map['isDefault'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, colorValue, icon, isDefault, createdAt];
}

class AnalyticsLog extends Equatable {
  final String id;
  final DateTime date;
  final int tasksCompleted;
  final int tasksMissed;
  final int tasksTotal;
  final double productivityScore;
  final int totalMinutesWorked;
  final DateTime createdAt;

  const AnalyticsLog({
    required this.id,
    required this.date,
    this.tasksCompleted = 0,
    this.tasksMissed = 0,
    this.tasksTotal = 0,
    this.productivityScore = 0.0,
    this.totalMinutesWorked = 0,
    required this.createdAt,
  });

  double get completionRate =>
      tasksTotal == 0 ? 0.0 : tasksCompleted / tasksTotal;
  double get missRate =>
      tasksTotal == 0 ? 0.0 : tasksMissed / tasksTotal;

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'tasksCompleted': tasksCompleted,
    'tasksMissed': tasksMissed,
    'tasksTotal': tasksTotal,
    'productivityScore': productivityScore,
    'totalMinutesWorked': totalMinutesWorked,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory AnalyticsLog.fromMap(Map<String, dynamic> map) => AnalyticsLog(
    id: map['id'],
    date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    tasksCompleted: map['tasksCompleted'] ?? 0,
    tasksMissed: map['tasksMissed'] ?? 0,
    tasksTotal: map['tasksTotal'] ?? 0,
    productivityScore: (map['productivityScore'] ?? 0.0).toDouble(),
    totalMinutesWorked: map['totalMinutesWorked'] ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
  );

  @override
  List<Object?> get props => [id, date, tasksCompleted, tasksMissed, tasksTotal,
    productivityScore, totalMinutesWorked, createdAt];
}
