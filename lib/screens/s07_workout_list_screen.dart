import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../providers/workout_provider.dart';

class S07WorkoutListScreen extends StatelessWidget {
  const S07WorkoutListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final plan = workoutProvider.currentPlan;

    if (plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('WORKOUT PLAN', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WEEK 1', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Stick to the plan to see results.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // 7-day streak strip
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final monday = now.subtract(Duration(days: now.weekday - 1));
                  final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final date = weekDays[index];
                      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                      final isRestDay = index == 6; // Sunday is index 6
                      final isCompleted = !isRestDay && workoutProvider.isWorkoutLogged(date);
                      
                      return Container(
                        width: isToday ? 32 : 28,
                        height: isToday ? 32 : 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.progressFill
                              : (isToday ? AppColors.elevatedSurface : Colors.transparent),
                          border: Border.all(
                            color: isCompleted || isToday ? AppColors.progressFill : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: AppColors.background)
                            : Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                                style: AppTextStyles.labelAllcaps.copyWith(
                                  color: isToday ? AppColors.primaryText : AppColors.secondaryText,
                                ),
                              ),
                      );
                    }),
                  );
                }
              ),
              const SizedBox(height: 32),
              
              ...plan.days.asMap().entries.map((entry) {
                final int index = entry.key;
                final WorkoutDay day = entry.value;
                
                final now = DateTime.now();
                final monday = now.subtract(Duration(days: now.weekday - 1));
                final dateForCard = monday.add(Duration(days: index));
                
                final isRest = day.durationMinutes == 0 || index == 6;
                final isCompleted = !isRest && workoutProvider.isWorkoutLogged(dateForCard);
                return GestureDetector(
                  onTap: () {
                    if (!isRest) {
                      context.push('/workout/detail', extra: day);
                    }
                  },
                  child: Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day.dayName.toUpperCase(), style: AppTextStyles.labelAllcaps),
                            if (isCompleted)
                              Row(
                                children: [
                                  Text('Completed', style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.progressFill)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle_outline, color: AppColors.progressFill, size: 16),
                                ],
                              )
                            else if (!isRest)
                              const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.workoutName,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isRest ? AppColors.secondaryText : AppColors.primaryText,
                          ),
                        ),
                        if (!isRest) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildChip(Icons.timer, '${day.durationMinutes} min'),
                              const SizedBox(width: 8),
                              _buildChip(Icons.fitness_center, '${day.exercises.length} Exercises'),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
