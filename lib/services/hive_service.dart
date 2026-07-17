import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userProfileBoxName = 'user_profile';
  static const String workoutLogsBoxName = 'workout_logs';
  static const String dietLogsBoxName = 'diet_logs';
  static const String gymLinkedKey = 'gym_linked';
  static const String userRoleKey = 'user_role';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(userProfileBoxName);
    await Hive.openBox(workoutLogsBoxName);
    await Hive.openBox(dietLogsBoxName);
  }

  static Box get userProfileBox => Hive.box(userProfileBoxName);
  static Box get workoutLogsBox => Hive.box(workoutLogsBoxName);
  static Box get dietLogsBox => Hive.box(dietLogsBoxName);

  static bool get isGymLinked => userProfileBox.get(gymLinkedKey, defaultValue: false);
  static Future<void> setGymLinked(bool value) async => await userProfileBox.put(gymLinkedKey, value);

  static String get userRole => userProfileBox.get(userRoleKey, defaultValue: 'member');
  static Future<void> setUserRole(String role) async => await userProfileBox.put(userRoleKey, role);
}
