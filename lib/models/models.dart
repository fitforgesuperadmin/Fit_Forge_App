enum Goal {
  fatLoss,
  muscleGain,
  leanRecomposition,
  strengthPower,
  enduranceFitness,
}

enum Intensity {
  low,
  medium,
  high,
}

class ExerciseLibraryItem {
  final String name;
  final String targetedMuscle;

  const ExerciseLibraryItem({
    required this.name,
    required this.targetedMuscle,
  });
}

class FoodLibraryItem {
  final String category;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double fibrePer100g;

  const FoodLibraryItem({
    required this.category,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.fibrePer100g,
  });
}

class ExerciseSet {
  final int reps;
  final double weight;
  
  const ExerciseSet({required this.reps, required this.weight});
  
  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      reps: map['reps']?.toInt() ?? 0,
      weight: map['weight']?.toDouble() ?? 0.0,
    );
  }
}

class Exercise {
  final String name;
  final List<ExerciseSet> sets;
  final String targetedMuscle;
  
  const Exercise({
    required this.name, 
    required this.sets,
    this.targetedMuscle = '',
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets.map((x) => x.toMap()).toList(),
      'targetedMuscle': targetedMuscle,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      sets: List<ExerciseSet>.from(map['sets']?.map((x) => ExerciseSet.fromMap(x)) ?? []),
      targetedMuscle: map['targetedMuscle'] ?? '',
    );
  }
}

class WorkoutDay {
  final String dayName;
  final String workoutName;
  final List<String> muscleGroups;
  final int durationMinutes;
  final List<Exercise> exercises;
  final bool isRestDay;
  
  const WorkoutDay({
    required this.dayName,
    required this.workoutName,
    required this.muscleGroups,
    required this.durationMinutes,
    required this.exercises,
    this.isRestDay = false,
  });
  
  WorkoutDay copyWith({
    String? dayName,
    String? workoutName,
    List<String>? muscleGroups,
    int? durationMinutes,
    List<Exercise>? exercises,
    bool? isRestDay,
  }) {
    return WorkoutDay(
      dayName: dayName ?? this.dayName,
      workoutName: workoutName ?? this.workoutName,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }
}

class WorkoutPlan {
  final Goal goal;
  final Intensity intensity;
  final List<WorkoutDay> days;
  
  const WorkoutPlan({
    required this.goal,
    required this.intensity,
    required this.days,
  });
}

class FoodItem {
  final String name;
  final int calories;
  final double quantityG;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  
  const FoodItem({
    required this.name, 
    required this.calories,
    this.quantityG = 0.0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatsG = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'quantityG': quantityG,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatsG': fatsG,
    };
  }

  FoodItem copyWith({
    String? name,
    int? calories,
    double? quantityG,
    double? proteinG,
    double? carbsG,
    double? fatsG,
  }) {
    return FoodItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      quantityG: quantityG ?? this.quantityG,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
    );
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      calories: map['calories']?.toInt() ?? 0,
      quantityG: map['quantityG']?.toDouble() ?? 0.0,
      proteinG: map['proteinG']?.toDouble() ?? 0.0,
      carbsG: map['carbsG']?.toDouble() ?? 0.0,
      fatsG: map['fatsG']?.toDouble() ?? 0.0,
    );
  }
}

class Meal {
  final String name;
  final List<FoodItem> items;
  
  const Meal({required this.name, required this.items});
  
  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  
  Meal copyWith({
    String? name,
    List<FoodItem>? items,
  }) {
    return Meal(
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

enum DietType {
  pureVegetarian,
  vegetarianPlusEggs,
  nonVegetarian,
  hybrid,
}

class DietPlan {
  final Goal goal;
  final Intensity intensity;
  final DietType dietType;
  final int dailyTargetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;
  final List<Meal> meals;
  
  const DietPlan({
    required this.goal,
    required this.intensity,
    required this.dietType,
    required this.dailyTargetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.meals,
  });
}
