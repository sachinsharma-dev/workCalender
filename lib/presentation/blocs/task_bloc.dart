import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:workcalender/data/models/task_model.dart';
import 'package:workcalender/data/models/category_model.dart';
import 'package:workcalender/data/repositories/repositories.dart';
import 'package:workcalender/core/services/smart_scheduler.dart';
import 'package:workcalender/core/constants/app_constants.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override List<Object?> get props => [];
}

class LoadTasksEvent extends TaskEvent {
  final DateTime date;
  const LoadTasksEvent(this.date);
  @override List<Object?> get props => [date];
}

class LoadAllTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final Task task;
  const AddTaskEvent(this.task);
  @override List<Object?> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final Task task;
  const UpdateTaskEvent(this.task);
  @override List<Object?> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  const DeleteTaskEvent(this.taskId);
  @override List<Object?> get props => [taskId];
}

class CompleteTaskEvent extends TaskEvent {
  final String taskId;
  const CompleteTaskEvent(this.taskId);
  @override List<Object?> get props => [taskId];
}

class DetectMissedTasksEvent extends TaskEvent {}

class RunSchedulerEvent extends TaskEvent {
  final DateTime date;
  const RunSchedulerEvent(this.date);
  @override List<Object?> get props => [date];
}

class ParseNLPInputEvent extends TaskEvent {
  final String input;
  const ParseNLPInputEvent(this.input);
  @override List<Object?> get props => [input];
}

// ─── States ─────────────────────────────────────────────────────────────────

abstract class TaskState extends Equatable {
  const TaskState();
  @override List<Object?> get props => [];
}

class TaskInitial extends TaskState {}
class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final List<Task> todayTasks;
  final List<Task> missedTasks;
  final DailyPlan? dailyPlan;
  final List<Category> categories;
  final DateTime selectedDate;

  const TaskLoaded({
    required this.tasks,
    required this.todayTasks,
    required this.missedTasks,
    this.dailyPlan,
    required this.categories,
    required this.selectedDate,
  });

  int get completedToday => todayTasks.where((t) => t.isCompleted).length;
  int get pendingToday => todayTasks.where((t) => t.isPending || t.isInProgress).length;
  double get completionRate =>
      todayTasks.isEmpty ? 0.0 : completedToday / todayTasks.length;
  double get productivityScore => dailyPlan?.productivityScore ?? 0.0;
  Task? get bestNextTask => dailyPlan?.bestNextTask;

  TaskLoaded copyWith({
    List<Task>? tasks,
    List<Task>? todayTasks,
    List<Task>? missedTasks,
    DailyPlan? dailyPlan,
    List<Category>? categories,
    DateTime? selectedDate,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      todayTasks: todayTasks ?? this.todayTasks,
      missedTasks: missedTasks ?? this.missedTasks,
      dailyPlan: dailyPlan ?? this.dailyPlan,
      categories: categories ?? this.categories,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [tasks, todayTasks, missedTasks, dailyPlan, categories, selectedDate];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override List<Object?> get props => [message];
}

class NLPParsed extends TaskState {
  final ParsedTaskInput parsed;
  const NLPParsed(this.parsed);
  @override List<Object?> get props => [parsed];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepo;
  final CategoryRepository _categoryRepo;
  final AnalyticsRepository _analyticsRepo;
  final SmartScheduler _scheduler = SmartScheduler.instance;

  TaskBloc({
    required TaskRepository taskRepo,
    required CategoryRepository categoryRepo,
    required AnalyticsRepository analyticsRepo,
  })  : _taskRepo = taskRepo,
        _categoryRepo = categoryRepo,
        _analyticsRepo = analyticsRepo,
        super(TaskInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<LoadAllTasksEvent>(_onLoadAllTasks);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<CompleteTaskEvent>(_onCompleteTask);
    on<DetectMissedTasksEvent>(_onDetectMissed);
    on<RunSchedulerEvent>(_onRunScheduler);
    on<ParseNLPInputEvent>(_onParseNLP);
  }

  Future<void> _onLoadTasks(LoadTasksEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final allTasks = await _taskRepo.getAllTasks();
      final todayTasks = await _taskRepo.getTasksByDate(event.date);
      final missedTasks = await _taskRepo.getMissedTasks();
      final categories = await _categoryRepo.getCategories();
      final dailyPlan = _scheduler.optimizeDailyPlan(
        allTasks: allTasks, date: event.date);

      emit(TaskLoaded(
        tasks: allTasks,
        todayTasks: todayTasks,
        missedTasks: missedTasks,
        dailyPlan: dailyPlan,
        categories: categories,
        selectedDate: event.date,
      ));

      await _analyticsRepo.updateDailyAnalytics(event.date, todayTasks);
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onLoadAllTasks(LoadAllTasksEvent event, Emitter<TaskState> emit) async {
    add(LoadTasksEvent(DateTime.now()));
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await _taskRepo.saveTask(event.task);
      add(LoadTasksEvent(event.task.date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await _taskRepo.updateTask(event.task);
      final currentState = state;
      final date = currentState is TaskLoaded ? currentState.selectedDate : DateTime.now();
      add(LoadTasksEvent(date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await _taskRepo.deleteTask(event.taskId);
      final currentState = state;
      final date = currentState is TaskLoaded ? currentState.selectedDate : DateTime.now();
      add(LoadTasksEvent(date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onCompleteTask(CompleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await _taskRepo.markComplete(event.taskId);
      final currentState = state;
      final date = currentState is TaskLoaded ? currentState.selectedDate : DateTime.now();
      add(LoadTasksEvent(date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDetectMissed(DetectMissedTasksEvent event, Emitter<TaskState> emit) async {
    try {
      await _taskRepo.detectAndMarkMissedTasks();
      final currentState = state;
      final date = currentState is TaskLoaded ? currentState.selectedDate : DateTime.now();
      add(LoadTasksEvent(date));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onRunScheduler(RunSchedulerEvent event, Emitter<TaskState> emit) async {
    add(LoadTasksEvent(event.date));
  }

  Future<void> _onParseNLP(ParseNLPInputEvent event, Emitter<TaskState> emit) async {
    final parsed = _scheduler.parseNaturalLanguage(event.input);
    emit(NLPParsed(parsed));
  }
}
