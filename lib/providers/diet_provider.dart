import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/static_data.dart';
import '../services/hive_service.dart';

class DietProvider extends ChangeNotifier {
  DietPlan? _currentPlan;
  
  DietPlan? get currentPlan {
    if (_currentPlan == null) return null;
    
    List<Meal> modifiedMeals = _currentPlan!.meals.map((meal) {
      final box = HiveService.dietLogsBox;
      final key = "custom_meal_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${_currentPlan!.dietType.name}_${meal.name}";
      
      List<FoodItem> customFoods = [];
      final customData = box.get(key);
      if (customData != null && customData is List) {
         customFoods = customData.map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      
      if (customFoods.isEmpty) return meal;
      
      return meal.copyWith(items: [...meal.items, ...customFoods]);
    }).toList();

    return DietPlan(
      goal: _currentPlan!.goal,
      intensity: _currentPlan!.intensity,
      dietType: _currentPlan!.dietType,
      dailyTargetCalories: _currentPlan!.dailyTargetCalories,
      targetProtein: _currentPlan!.targetProtein,
      targetCarbs: _currentPlan!.targetCarbs,
      targetFats: _currentPlan!.targetFats,
      meals: modifiedMeals,
    );
  }
  
  // Track consumed calories per meal item for simple tracking
  Map<String, bool> consumedItems = {}; // key: "mealName_itemName"
  
  void initializePlan(Goal goal, Intensity intensity, DietType dietType) {
    _currentPlan = StaticData.dietPlans.firstWhere(
      (plan) => plan.goal == goal && plan.intensity == intensity && plan.dietType == dietType,
      orElse: () => StaticData.dietPlans.first,
    );
    consumedItems.clear();
    _restoreDailyProgress();
    notifyListeners();
  }

  void _restoreDailyProgress() {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final box = HiveService.dietLogsBox;
    final storedProgress = box.get("progress_$dateKey");
    
    if (storedProgress != null && storedProgress is Map) {
      consumedItems = Map<String, bool>.from(storedProgress);
    }
  }

  void _saveDailyProgress() {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final box = HiveService.dietLogsBox;
    box.put("progress_$dateKey", consumedItems);
  }

  void addCustomFoodItem(String mealName, FoodItem item) {
    if (_currentPlan == null) return;
    final box = HiveService.dietLogsBox;
    final key = "custom_meal_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${_currentPlan!.dietType.name}_$mealName";
    
    List<dynamic> existing = List.from(box.get(key, defaultValue: []));
    existing.add(item.toMap());
    box.put(key, existing);
    
    consumedItems["${mealName}_${item.name}"] = true;
    _saveDailyProgress();
    _updateMealLoggedStatus(mealName);
    
    notifyListeners();
  }

  void removeCustomFoodItem(String mealName, FoodItem item) {
    if (_currentPlan == null) return;
    final box = HiveService.dietLogsBox;
    final key = "custom_meal_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${_currentPlan!.dietType.name}_$mealName";
    
    List<dynamic> existing = List.from(box.get(key, defaultValue: []));
    int index = existing.indexWhere((e) => e['name'] == item.name);
    if (index != -1) {
      existing.removeAt(index);
      box.put(key, existing);
      notifyListeners();
    }
  }

  void updateCustomFoodQuantity(String mealName, FoodItem item, double newQuantity) {
    if (_currentPlan == null) return;
    final box = HiveService.dietLogsBox;
    final key = "custom_meal_${_currentPlan!.goal.name}_${_currentPlan!.intensity.name}_${_currentPlan!.dietType.name}_$mealName";
    
    List<dynamic> existing = List.from(box.get(key, defaultValue: []));
    int index = existing.indexWhere((e) => e['name'] == item.name);
    if (index != -1) {
      existing[index] = item.copyWith(quantityG: newQuantity).toMap();
      box.put(key, existing);
      notifyListeners();
    }
  }
  
  void toggleItem(String mealName, String itemName, bool value) {
    consumedItems["${mealName}_$itemName"] = value;
    _saveDailyProgress();
    if (value) {
      _updateMealLoggedStatus(mealName);
    }
    notifyListeners();
  }
  
  bool isItemConsumed(String mealName, String itemName) {
    return consumedItems["${mealName}_$itemName"] ?? false;
  }

  void _updateMealLoggedStatus(String mealName) {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final box = HiveService.dietLogsBox;
    
    List<String> loggedMeals = List<String>.from(box.get(dateKey, defaultValue: <String>[]));
    if (!loggedMeals.contains(mealName)) {
      loggedMeals.add(mealName);
      box.put(dateKey, loggedMeals);
    }
  }
  
  int get currentConsumedCalories {
    final plan = currentPlan;
    if (plan == null) return 0;
    int total = 0;
    for (var meal in plan.meals) {
      for (var item in meal.items) {
        if (isItemConsumed(meal.name, item.name)) {
          total += item.calories;
        }
      }
    }
    return total;
  }
  
  int get currentConsumedProtein {
    final plan = currentPlan;
    if (plan == null) return 0;
    double total = 0;
    for (var meal in plan.meals) {
      for (var item in meal.items) {
        if (isItemConsumed(meal.name, item.name)) {
          total += item.proteinG;
        }
      }
    }
    return total.round();
  }
  
  int get currentConsumedCarbs {
    final plan = currentPlan;
    if (plan == null) return 0;
    double total = 0;
    for (var meal in plan.meals) {
      for (var item in meal.items) {
        if (isItemConsumed(meal.name, item.name)) {
          total += item.carbsG;
        }
      }
    }
    return total.round();
  }
  
  int get currentConsumedFats {
    final plan = currentPlan;
    if (plan == null) return 0;
    double total = 0;
    for (var meal in plan.meals) {
      for (var item in meal.items) {
        if (isItemConsumed(meal.name, item.name)) {
          total += item.fatsG;
        }
      }
    }
    return total.round();
  }
  
  String? getNextMeal() {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final box = HiveService.dietLogsBox;
    
    List<String> loggedMeals = List<String>.from(box.get(dateKey, defaultValue: <String>[]));
    
    // Ordered meals as per requirements
    final orderedMeals = ['Breakfast', 'Lunch', 'Evening Snack', 'Dinner'];
    
    for (String meal in orderedMeals) {
      if (!loggedMeals.contains(meal)) {
        return meal;
      }
    }
    
    return null; // All meals logged
  }

  bool isAnyMealLogged(DateTime date) {
    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final box = HiveService.dietLogsBox;
    List<String> loggedMeals = List<String>.from(box.get(dateKey, defaultValue: <String>[]));
    return loggedMeals.isNotEmpty;
  }
}
