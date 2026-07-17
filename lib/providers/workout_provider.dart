import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/static_data.dart';
import '../services/hive_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutPlan? _currentPlan;
  
  // Session tracking
  int sessionDurationSeconds = 0;
  double sessionTotalVolume = 0.0;
  int sessionCompletedSets = 0;
  List<String> sessionCompletedExerciseNames = [];
  
  WorkoutPlan? get currentPlan {
    if (_currentPlan == null) return null;
    
    List<WorkoutDay> modifiedDays = _currentPlan!.days.map((day) {
      final box = HiveService.workoutLogsBox;
      final key = "custom_workout_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${day.dayName}";
      
      List<Exercise> customExercises = [];
      final customData = box.get(key);
      if (customData != null && customData is List) {
         customExercises = customData.map((e) => Exercise.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      
      if (customExercises.isEmpty) return day;
      
      return day.copyWith(exercises: [...day.exercises, ...customExercises]);
    }).toList();
    
    return WorkoutPlan(
      goal: _currentPlan!.goal,
      intensity: _currentPlan!.intensity,
      days: modifiedDays,
    );
  }
  
  void initializePlan(Goal goal, Intensity intensity) {
    _currentPlan = StaticData.workoutPlans.firstWhere(
      (plan) => plan.goal == goal && plan.intensity == intensity,
      orElse: () => StaticData.workoutPlans.first,
    );
    notifyListeners();
  }

  void addCustomExercise(WorkoutDay day, Exercise exercise) {
    if (_currentPlan == null) return;
    final box = HiveService.workoutLogsBox;
    final key = "custom_workout_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${day.dayName}";
    
    List<dynamic> existing = List.from(box.get(key, defaultValue: []));
    existing.add(exercise.toMap());
    box.put(key, existing);
    notifyListeners();
  }

  void removeCustomExercise(WorkoutDay day, Exercise exercise) {
    if (_currentPlan == null) return;
    final box = HiveService.workoutLogsBox;
    final key = "custom_workout_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${day.dayName}";
    
    List<dynamic> existing = List.from(box.get(key, defaultValue: []));
    int index = existing.indexWhere((e) => e['name'] == exercise.name);
    if (index != -1) {
      existing.removeAt(index);
      box.put(key, existing);
      notifyListeners();
    }
  }

  void logWorkoutSession(DateTime date, String workoutName) {
    final box = HiveService.workoutLogsBox;
    // We can use an auto-incrementing int key or a timestamp string
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    box.put(id, {
      'date': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'timestamp': DateTime.now().toIso8601String(),
      'workoutName': workoutName,
    });
    
    notifyListeners();
  }

  int getWeeklyWorkoutCount() {
    final now = DateTime.now();
    // Calculate Monday of the current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    // Saturday
    final saturday = startOfWeek.add(const Duration(days: 5));
    final endOfWeek = DateTime(saturday.year, saturday.month, saturday.day, 23, 59, 59);

    final box = HiveService.workoutLogsBox;
    int count = 0;

    for (var key in box.keys) {
      final entry = box.get(key);
      if (entry is Map) {
        final dateStr = entry['date'] as String?;
        if (dateStr != null) {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final logDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            if (logDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
                logDate.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  bool isWorkoutLogged(DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final box = HiveService.workoutLogsBox;
    for (var key in box.keys) {
      final entry = box.get(key);
      if (entry is Map && entry['date'] == dateStr) {
        return true;
      }
    }
    return false;
  }
}
