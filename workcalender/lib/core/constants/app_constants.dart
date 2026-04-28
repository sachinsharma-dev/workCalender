class AppConstants {
  // App Info
  static const String appName = 'WorkCalender';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'workcalender.db';
  static const int dbVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableTasks = 'tasks';
  static const String tableCategories = 'categories';
  static const String tableLogs = 'logs';
  static const String tableAnalytics = 'analytics';
  static const String tableSettings = 'settings';

  // Hive Boxes
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // SharedPrefs Keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserId = 'user_id';
  static const String keyGuestMode = 'guest_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyMorningReminderTime = 'morning_reminder_time';
  static const String keyEveningReminderTime = 'evening_reminder_time';

  // Priority Levels
  static const int priorityNone = 0;
  static const int priorityLow = 1;
  static const int priorityMedium = 2;
  static const int priorityHigh = 3;
  static const int priorityUrgent = 4;

  // Task Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusMissed = 'missed';
  static const String statusPostponed = 'postponed';

  // Repeat Options
  static const String repeatNone = 'none';
  static const String repeatDaily = 'daily';
  static const String repeatWeekly = 'weekly';
  static const String repeatMonthly = 'monthly';
  static const String repeatCustom = 'custom';

  // Calendar Views
  static const String viewMonthly = 'monthly';
  static const String viewWeekly = 'weekly';
  static const String viewDaily = 'daily';

  // Scheduler Config
  static const int maxDailyWorkHours = 10;
  static const int schedulerBufferMinutes = 15;
  static const double urgencyDecayFactor = 0.85;
  static const int missedTaskGracePeriodMinutes = 30;

  // Notification IDs
  static const int notifMorningId = 1001;
  static const int notifEveningId = 1002;
  static const int notifTaskReminderBase = 2000;
  static const int notifDeadlineAlertBase = 3000;

  // NLP Patterns
  static const List<String> timeKeywords = [
    'today', 'tomorrow', 'monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday', 'sunday',
    'morning', 'afternoon', 'evening', 'night', 'noon',
    'next week', 'this week'
  ];

  static const List<String> durationKeywords = [
    'for', 'hour', 'hours', 'minute', 'minutes', 'hrs', 'min'
  ];

  static const List<String> priorityKeywords = [
    'urgent', 'important', 'asap', 'critical', 'high priority',
    'low priority', 'whenever'
  ];

  // Analytics
  static const int analyticsRetentionDays = 90;

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Work', 'color': 0xFF4A7CFF, 'icon': 'briefcase'},
    {'name': 'Personal', 'color': 0xFF7C5FF0, 'icon': 'person'},
    {'name': 'Health', 'color': 0xFF26DE81, 'icon': 'fitness'},
    {'name': 'Study', 'color': 0xFFFFBB00, 'icon': 'book'},
    {'name': 'Finance', 'color': 0xFF00D4AA, 'icon': 'wallet'},
    {'name': 'Social', 'color': 0xFFFF4D8B, 'icon': 'people'},
    {'name': 'Home', 'color': 0xFFFF6B35, 'icon': 'home'},
    {'name': 'Other', 'color': 0xFFB0B8CC, 'icon': 'grid'},
  ];

  // Productivity Score Weights
  static const double completionWeight = 0.6;
  static const double onTimeWeight = 0.3;
  static const double priorityWeight = 0.1;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);
}
