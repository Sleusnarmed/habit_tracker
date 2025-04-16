// App Strings (Avoid hardcoding text in widgets)
class AppStrings {
  static const String appName = "TaskMatrix";
  static const String today = "Today";
  static const String addTaskHint = "Add a new task...";
  static const String habitStreak = "Day Streak:";
}

// Design Constants (Padding, Sizes, Durations)
class AppDimensions {
  static const double defaultPadding = 16.0;
  static const double taskCardRadius = 12.0;
  static const double fabSize = 56.0;
}

// Firebase Collections (If using Firestore)
class FirestorePaths {
  static const String users = "users";
  static const String tasks = "tasks";
  static const String habits = "habits";
}

// Eisenhower Matrix Categories
class EisenhowerCategories {
  static const String urgentImportant = "Urgent & Important";
  static const String notUrgentImportant = "Not Urgent & Important";
  static const String urgentNotImportant = "Urgent & Not Important";
  static const String notUrgentNotImportant = "Not Urgent & Not Important";
}

// SharedPreferences Keys (For local storage)
class PrefKeys {
  static const String themeMode = "theme_mode";
  static const String firstLaunch = "first_launch";
}

// Animation Durations
class AppDurations {
  static const Duration taskCompleteAnimation = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 200);
}

// Default Values
class AppDefaults {
  static const int maxHabitStreak = 21; // For habit formation
  static const int dailyReminderHour = 20; // 8 PM default reminder
}