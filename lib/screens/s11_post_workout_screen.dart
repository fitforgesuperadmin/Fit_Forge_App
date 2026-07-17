import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/custom_button.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class S11PostWorkoutScreen extends StatelessWidget {
  final WorkoutDay? workoutDay;

  const S11PostWorkoutScreen({Key? key, this.workoutDay}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (workoutDay == null) {
      return const Scaffold(body: Center(child: Text('Error: No workout data')));
    }

    final workoutProvider = Provider.of<WorkoutProvider>(context);
    
    // Format Time
    int duration = workoutProvider.sessionDurationSeconds;
    String timeStr;
    if (duration < 3600) {
      int minutes = duration ~/ 60;
      int seconds = duration % 60;
      timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      int hours = duration ~/ 3600;
      int minutes = (duration % 3600) ~/ 60;
      int seconds = duration % 60;
      timeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // Format Volume
    double volume = workoutProvider.sessionTotalVolume;
    String volStr;
    String volUnit;
    if (volume >= 1000) {
      volStr = (volume / 1000).toStringAsFixed(1);
      volUnit = 'k kg';
    } else {
      volStr = volume.toStringAsFixed(0);
      volUnit = 'kg';
    }

    // Format Sets
    String setsStr = workoutProvider.sessionCompletedSets.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('WORKOUT COMPLETE', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('GREAT JOB!', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      workoutDay!.workoutName,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('TIME', timeStr, duration < 3600 ? 'min' : 'hrs')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('VOLUME', volStr, volUnit)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('SETS', setsStr, 'total')),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    Text('MUSCLES WORKED', style: AppTextStyles.labelAllcaps),
                    const SizedBox(height: 24),
                    
                    _buildMusclesWorkedGrid(context),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                text: "BACK TO DASHBOARD",
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelAllcaps),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.dataMedium),
          Text(unit, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMusclesWorkedGrid(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final completedExerciseNames = workoutProvider.sessionCompletedExerciseNames;

    if (completedExerciseNames.isEmpty || workoutDay == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('No muscle data available', style: AppTextStyles.bodySmall),
      );
    }

    // Map imageFilename -> set of specific muscle chips
    Map<String, Set<String>> imageToChips = {};

    for (var exercise in workoutDay!.exercises) {
      if (completedExerciseNames.contains(exercise.name)) {
        String targeted = exercise.targetedMuscle;
        String? filename = _getMuscleImageFilename(targeted);
        
        if (filename != null) {
          imageToChips.putIfAbsent(filename, () => {});
          imageToChips[filename]!.add(targeted);
        }
      }
    }

    if (imageToChips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('No muscle data available', style: AppTextStyles.bodySmall),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: imageToChips.length,
      itemBuilder: (context, index) {
        String imageFilename = imageToChips.keys.elementAt(index);
        Set<String> chips = imageToChips[imageFilename]!;

        String title = imageFilename.replaceAll('muscle_', '').replaceAll('.png', '');
        if (title.isNotEmpty) {
          title = title[0].toUpperCase() + title.substring(1);
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Image.asset('assets/muscles/$imageFilename', fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFFF0F0F0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: chips.map((chip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chip,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _getMuscleImageFilename(String targetedMuscle) {
    switch (targetedMuscle) {
      case 'Chest': return 'muscle_chest.png';
      case 'Back': return 'muscle_back.png';
      case 'Shoulders': return 'muscle_shoulders.png';
      case 'Biceps': return 'muscle_biceps.png';
      case 'Triceps': return 'muscle_triceps.png';
      case 'Core': return 'muscle_abdominals.png';
      case 'Quadriceps': return 'muscle_quadriceps.png';
      case 'Hamstrings': return 'muscle_hamstrings.png';
      case 'Calves': return 'muscle_calves.png';
      case 'Glutes': return 'muscle_glutes.png';
      case 'Traps': return 'muscle_back.png';
      case 'Cardiovascular': return null;
      default: return null;
    }
  }
}
