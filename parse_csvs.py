import csv
import sys
import os

workout_csv = 'c:/Users/Vihang Mistry/OneDrive/Desktop/FIR_FORGE_GREY_APP/CSV_FILES/workout_exercises.csv'
food_csv = 'c:/Users/Vihang Mistry/OneDrive/Desktop/FIR_FORGE_GREY_APP/CSV_FILES/indian_food_nutrition (1).csv'
out_file = 'c:/Users/Vihang Mistry/OneDrive/Desktop/FIR_FORGE_GREY_APP/lib/data/exercise_food_library.dart'

exercises = []
foods = []

valid_exercise_count = 0

with open(workout_csv, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader) # skip header
    for row in reader:
        if len(row) >= 2:
            name = row[0].strip()
            muscle = row[1].strip()
            if name and muscle: # if targeted muscle is not empty
                valid_exercise_count += 1
                name_esc = name.replace("'", "\\'")
                muscle_esc = muscle.replace("'", "\\'")
                exercises.append(f"  ExerciseLibraryItem(name: '{name_esc}', targetedMuscle: '{muscle_esc}'),")

with open(food_csv, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if len(row) >= 7:
            category = row[0].strip().replace("'", "\\'")
            name = row[1].strip().replace("'", "\\'")
            cals = row[2].strip()
            protein = row[3].strip()
            carbs = row[4].strip()
            fats = row[5].strip()
            fibre = row[6].strip()
            
            foods.append(f"  FoodLibraryItem(\n"
                         f"    category: '{category}',\n"
                         f"    name: '{name}',\n"
                         f"    caloriesPer100g: {cals},\n"
                         f"    proteinPer100g: {protein},\n"
                         f"    carbsPer100g: {carbs},\n"
                         f"    fatsPer100g: {fats},\n"
                         f"    fibrePer100g: {fibre},\n"
                         f"  ),")

dart_code = f"""// AUTO-GENERATED FILE. DO NOT EDIT.
import '../models/models.dart';

class ExerciseFoodLibrary {{
  static const List<ExerciseLibraryItem> exerciseLibrary = [
{chr(10).join(exercises)}
  ];

  static const List<FoodLibraryItem> foodLibrary = [
{chr(10).join(foods)}
  ];
}}
"""

os.makedirs(os.path.dirname(out_file), exist_ok=True)
with open(out_file, 'w', encoding='utf-8') as f:
    f.write(dart_code)

print(f"VALID_EXERCISE_COUNT: {valid_exercise_count}")
print(f"VALID_FOOD_COUNT: {len(foods)}")
