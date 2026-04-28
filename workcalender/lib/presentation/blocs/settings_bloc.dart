import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class ToggleThemeEvent extends SettingsEvent {
  final ThemeMode mode;
  const ToggleThemeEvent(this.mode);
  @override List<Object?> get props => [mode];
}

class ToggleNotificationsEvent extends SettingsEvent {
  final bool enabled;
  const ToggleNotificationsEvent(this.enabled);
  @override List<Object?> get props => [enabled];
}

class SetMorningReminderEvent extends SettingsEvent {
  final TimeOfDay time;
  const SetMorningReminderEvent(this.time);
  @override List<Object?> get props => [time];
}

class SetEveningReminderEvent extends SettingsEvent {
  final TimeOfDay time;
  const SetEveningReminderEvent(this.time);
  @override List<Object?> get props => [time];
}

// ─── States ─────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final TimeOfDay morningReminderTime;
  final TimeOfDay eveningReminderTime;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.morningReminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.eveningReminderTime = const TimeOfDay(hour: 21, minute: 0),
    this.isLoading = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    TimeOfDay? morningReminderTime,
    TimeOfDay? eveningReminderTime,
    bool? isLoading,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    morningReminderTime: morningReminderTime ?? this.morningReminderTime,
    eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
    isLoading: isLoading ?? this.isLoading,
  );

  @override
  List<Object?> get props => [themeMode, notificationsEnabled,
    morningReminderTime, eveningReminderTime, isLoading];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoad);
    on<ToggleThemeEvent>(_onToggleTheme);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<SetMorningReminderEvent>(_onSetMorning);
    on<SetEveningReminderEvent>(_onSetEvening);
  }

  Future<void> _onLoad(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(AppConstants.keyThemeMode) ?? 0;
    final notifEnabled = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    final morningHour = prefs.getInt('morning_hour') ?? 8;
    final morningMin = prefs.getInt('morning_min') ?? 0;
    final eveningHour = prefs.getInt('evening_hour') ?? 21;
    final eveningMin = prefs.getInt('evening_min') ?? 0;

    emit(state.copyWith(
      themeMode: ThemeMode.values[themeModeIndex],
      notificationsEnabled: notifEnabled,
      morningReminderTime: TimeOfDay(hour: morningHour, minute: morningMin),
      eveningReminderTime: TimeOfDay(hour: eveningHour, minute: eveningMin),
    ));
  }

  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, event.mode.index);
    emit(state.copyWith(themeMode: event.mode));
  }

  Future<void> _onToggleNotifications(
      ToggleNotificationsEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsEnabled, event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  Future<void> _onSetMorning(SetMorningReminderEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_hour', event.time.hour);
    await prefs.setInt('morning_min', event.time.minute);
    emit(state.copyWith(morningReminderTime: event.time));
  }

  Future<void> _onSetEvening(SetEveningReminderEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('evening_hour', event.time.hour);
    await prefs.setInt('evening_min', event.time.minute);
    emit(state.copyWith(eveningReminderTime: event.time));
  }
}
