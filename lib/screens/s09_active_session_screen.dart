import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../widgets/custom_button.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';

class S09ActiveSessionScreen extends StatefulWidget {
  final WorkoutDay? workoutDay;

  const S09ActiveSessionScreen({Key? key, this.workoutDay}) : super(key: key);

  @override
  State<S09ActiveSessionScreen> createState() => _S09ActiveSessionScreenState();
}

class ActiveSetState {
  int reps;
  double weightKg;
  bool isCompleted;
  ActiveSetState({required this.reps, required this.weightKg, this.isCompleted = false});
}

class _S09ActiveSessionScreenState extends State<S09ActiveSessionScreen> {
  late Stopwatch _stopwatch;
  late Timer _timer;
  
  final Map<String, ActiveSetState> _activeSets = {};
  String? _editingWeightKey;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) setState(() {});
    });

    if (widget.workoutDay != null) {
      for (int exIndex = 0; exIndex < widget.workoutDay!.exercises.length; exIndex++) {
        final exercise = widget.workoutDay!.exercises[exIndex];
        for (int setIdx = 0; setIdx < exercise.sets.length; setIdx++) {
          final set = exercise.sets[setIdx];
          _activeSets["${exIndex}_$setIdx"] = ActiveSetState(
            reps: set.reps,
            weightKg: set.weight,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatTime(int milliseconds) {
    int secs = milliseconds ~/ 1000;
    int minutes = secs ~/ 60;
    int seconds = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _finishWorkout() {
    // Navigate to S10 finish modal as dialog or route.
    // In GoRouter we can show it as a dialog here, then route to summary.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFinishModal(),
    );
  }

  Widget _buildFinishModal() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Text('FINISH WORKOUT?', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to end this session?',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: "YES, FINISH",
            onPressed: () {
              Navigator.pop(context); // close modal
              
              if (widget.workoutDay != null) {
                final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                
                final today = DateTime.now();
                
                // Calculate accurate session data
                int durationSeconds = _stopwatch.elapsedMilliseconds ~/ 1000;
                double totalVolume = 0.0;
                int completedSetsCount = 0;
                Set<int> completedExerciseIndices = {};
                
                _activeSets.forEach((key, state) {
                  if (state.isCompleted) {
                    completedSetsCount++;
                    totalVolume += (state.reps * state.weightKg);
                    int exIndex = int.parse(key.split('_')[0]);
                    completedExerciseIndices.add(exIndex);
                  }
                });
                
                workoutProvider.sessionDurationSeconds = durationSeconds;
                workoutProvider.sessionTotalVolume = totalVolume;
                workoutProvider.sessionCompletedSets = completedSetsCount;
                
                List<String> completedNames = [];
                for (int exIndex in completedExerciseIndices) {
                  completedNames.add(widget.workoutDay!.exercises[exIndex].name);
                }
                workoutProvider.sessionCompletedExerciseNames = completedNames;
                
                // Pass fields directly to Hive as well
                workoutProvider.logWorkoutSession(
                  today, 
                  widget.workoutDay!.workoutName,
                  durationSeconds: durationSeconds,
                  totalVolume: totalVolume,
                  completedSets: completedSetsCount,
                  completedExerciseNames: completedNames,
                );
                
                // Streak Logic
                String todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                if (userProvider.lastStreakDate != todayStr) {
                  userProvider.updateStreak(userProvider.streak + 1, todayStr);
                }
              }

              context.go('/workout/summary', extra: widget.workoutDay);
            },
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: "RESUME",
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workoutDay == null) {
      return const Scaffold(body: Center(child: Text('Error: No workout data')));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text(
              "End Session?",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFFF0F0F0),
              ),
            ),
            content: const Text(
              "Are you sure you want to exit the session? Your progress will be lost.",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryText),
                child: const Text("Yes, Exit"),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.primaryText),
            onPressed: _finishWorkout,
          ),
          title: Text('ACTIVE SESSION', style: AppTextStyles.labelAllcaps),
          centerTitle: true,
        ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    _formatTime(_stopwatch.elapsedMilliseconds),
                    style: AppTextStyles.dataLarge.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.workoutDay!.workoutName, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: widget.workoutDay!.exercises.length,
                itemBuilder: (context, exIndex) {
                  final exercise = widget.workoutDay!.exercises[exIndex];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name.toUpperCase(), style: AppTextStyles.labelLarge),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(width: 32, child: Text('SET', style: AppTextStyles.labelAllcaps)),
                            Expanded(flex: 2, child: Text('REPS', style: AppTextStyles.labelAllcaps, textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('WEIGHT', style: AppTextStyles.labelAllcaps, textAlign: TextAlign.center)),
                            const SizedBox(width: 12),
                            const SizedBox(width: 32),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...exercise.sets.asMap().entries.map((entry) {
                          int setIdx = entry.key;
                          ExerciseSet set = entry.value;
                          String key = "${exIndex}_$setIdx";
                          ActiveSetState state = _activeSets[key] ?? ActiveSetState(reps: set.reps, weightKg: set.weight);
                          bool isCompleted = state.isCompleted;
                          bool isEditingWeight = _editingWeightKey == key;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 32, 
                                  child: Text('${setIdx + 1}', style: AppTextStyles.dataMedium)
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildStepperButton(Icons.remove, () {
                                        if (state.reps > 1) setState(() => state.reps--);
                                      }, size: 28),
                                      SizedBox(
                                        width: 32,
                                        child: Text('${state.reps}', style: AppTextStyles.dataMedium, textAlign: TextAlign.center),
                                      ),
                                      _buildStepperButton(Icons.add, () {
                                        if (state.reps < 99) setState(() => state.reps++);
                                      }, size: 28),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: isEditingWeight
                                      ? TextFormField(
                                          initialValue: state.weightKg.toString(),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: AppTextStyles.dataMedium.copyWith(color: AppColors.primaryText),
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF9E9E9E), width: 1)),
                                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF9E9E9E), width: 1)),
                                          ),
                                          onFieldSubmitted: (val) {
                                            double? newVal = double.tryParse(val);
                                            setState(() {
                                              if (newVal != null && newVal > 0) {
                                                state.weightKg = newVal;
                                              }
                                              _editingWeightKey = null;
                                            });
                                          },
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _editingWeightKey = key;
                                            });
                                          },
                                          child: Text('${state.weightKg}', style: AppTextStyles.dataMedium, textAlign: TextAlign.center),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      state.isCompleted = !isCompleted;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isCompleted ? const Color(0xFF9E9E9E) : Colors.transparent,
                                      border: Border.all(
                                        color: isCompleted ? const Color(0xFF9E9E9E) : const Color(0xFF3A3A3A),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: isCompleted
                                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                text: "FINISH WORKOUT",
                onPressed: _finishWorkout,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStepperButton(IconData icon, VoidCallback onTap, {double size = 32}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.elevatedSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primaryText, size: 20),
      ),
    );
  }
}
