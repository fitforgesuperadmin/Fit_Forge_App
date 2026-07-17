import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/hive_service.dart';

class UserProvider extends ChangeNotifier {
  String _name = 'User';
  double _weight = 70.0;
  double _height = 175.0;
  int _age = 25;
  String _gender = 'Male';
  String _activityLevel = 'Active';
  
  Goal _goal = Goal.muscleGain;
  Intensity _intensity = Intensity.medium;
  DietType _dietType = DietType.hybrid;

  int _streak = 0;
  String? _lastStreakDate;

  UserProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = HiveService.userProfileBox;
    _name = box.get('name', defaultValue: 'User');
    _weight = box.get('weight', defaultValue: 70.0);
    _height = box.get('height', defaultValue: 175.0);
    _age = box.get('age', defaultValue: 25);
    _gender = box.get('gender', defaultValue: 'Male');
    _activityLevel = box.get('activityLevel', defaultValue: 'Active');
    
    final goalStr = box.get('goal');
    if (goalStr != null) {
      _goal = Goal.values.firstWhere((e) => e.name == goalStr, orElse: () => Goal.muscleGain);
    }
    
    final intensityStr = box.get('intensity');
    if (intensityStr != null) {
      _intensity = Intensity.values.firstWhere((e) => e.name == intensityStr, orElse: () => Intensity.medium);
    }

    final dietTypeStr = box.get('dietType');
    if (dietTypeStr != null) {
      _dietType = DietType.values.firstWhere((e) => e.name == dietTypeStr, orElse: () => DietType.hybrid);
    }

    _streak = box.get('streak', defaultValue: 0);
    _lastStreakDate = box.get('last_streak_date');
    
    _checkAndValidateStreak();
    
    notifyListeners();
  }

  void _checkAndValidateStreak() {
    if (_lastStreakDate == null || _streak == 0) return;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final lastParts = _lastStreakDate!.split('-');
    if (lastParts.length != 3) return;
    
    final lastDate = DateTime(int.parse(lastParts[0]), int.parse(lastParts[1]), int.parse(lastParts[2]));
    
    final difference = todayDate.difference(lastDate).inDays;
    
    if (difference > 1) {
      // If we missed exactly 1 day and that day was a Sunday, preserve streak.
      if (difference == 2 && lastDate.weekday == DateTime.saturday && todayDate.weekday == DateTime.monday) {
        // Only missed Sunday, streak is preserved.
      } else {
        // Missed non-Sunday days or multiple days, reset streak.
        updateStreak(0, _lastStreakDate!);
      }
    }
  }

  String get name => _name;
  double get weight => _weight;
  double get height => _height;
  int get age => _age;
  String get gender => _gender;
  String get activityLevel => _activityLevel;
  
  Goal get goal => _goal;
  Intensity get intensity => _intensity;
  DietType get dietType => _dietType;
  
  int get streak => _streak;
  String? get lastStreakDate => _lastStreakDate;
  
  double get bmi => _weight / ((_height / 100) * (_height / 100));

  void setPersonalDetails(String name, double weight, double height, int age, String gender, String activity) {
    _name = name;
    _weight = weight;
    _height = height;
    _age = age;
    _gender = gender;
    _activityLevel = activity;
    
    final box = HiveService.userProfileBox;
    box.put('name', name);
    box.put('weight', weight);
    box.put('height', height);
    box.put('age', age);
    box.put('gender', gender);
    box.put('activityLevel', activity);
    
    notifyListeners();
  }
  
  void setGoalAndIntensity(Goal goal, Intensity intensity) {
    _goal = goal;
    _intensity = intensity;
    
    final box = HiveService.userProfileBox;
    box.put('goal', goal.name);
    box.put('intensity', intensity.name);
    
    notifyListeners();
  }

  void setDietType(DietType dietType) {
    _dietType = dietType;
    
    final box = HiveService.userProfileBox;
    box.put('dietType', dietType.name);
    
    notifyListeners();
  }

  void updateStreak(int newStreak, String newDate) {
    _streak = newStreak;
    _lastStreakDate = newDate;
    
    final box = HiveService.userProfileBox;
    box.put('streak', newStreak);
    box.put('last_streak_date', newDate);
    
    notifyListeners();
  }
}
