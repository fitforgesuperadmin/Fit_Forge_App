import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';
import '../models/models.dart';

class S06DashboardScreen extends StatelessWidget {
  const S06DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final dietProvider = Provider.of<DietProvider>(context);

    // Calculate BMI Category
    String bmiCategory = "Normal weight";
    if (user.bmi < 18.5) {
      bmiCategory = "Underweight";
    } else if (user.bmi < 25.0) {
      bmiCategory = "Normal weight";
    } else if (user.bmi < 30.0) {
      bmiCategory = "Overweight";
    } else {
      bmiCategory = "Obese";
    }

    // Weekly workouts
    int weeklyWorkouts = workoutProvider.getWeeklyWorkoutCount();

    // Quick Actions - Workout
    final now = DateTime.now();
    final int weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final String todayName = dayNames[weekday - 1];

    bool isRestDay = weekday == 7;
    bool isWorkoutLoggedToday = workoutProvider.isWorkoutLogged(now);
    
    String workoutActionTitle;
    String workoutActionSubtitle;
    WorkoutDay? todayWorkout;
    
    if (isWorkoutLoggedToday) {
      workoutActionTitle = 'WORKOUT COMPLETE';
      workoutActionSubtitle = 'You\'ve already completed today\'s workout';
    } else if (isRestDay) {
      workoutActionTitle = 'REST DAY';
      workoutActionSubtitle = 'Enjoy your rest day';
    } else {
      workoutActionTitle = 'START TODAY\'S WORKOUT';
      if (workoutProvider.currentPlan != null) {
        todayWorkout = workoutProvider.currentPlan!.days.firstWhere(
          (d) => d.dayName == todayName, 
          orElse: () => workoutProvider.currentPlan!.days.first
        );
        workoutActionSubtitle = todayWorkout.workoutName;
      } else {
        workoutActionSubtitle = 'Loading...';
      }
    }

    // Quick Actions - Meal
    String? nextMeal = dietProvider.getNextMeal();
    String mealActionTitle = nextMeal == null ? 'ALL MEALS LOGGED' : 'LOG ${nextMeal.toUpperCase()}';
    String mealActionSubtitle = nextMeal == null ? 'Great job today!' : 'Next meal to log';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DASHBOARD', style: AppTextStyles.labelAllcaps),
                      const SizedBox(height: 4),
                      Text('Welcome, ${user.name}', style: AppTextStyles.h2),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text('OVERVIEW', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('WEIGHT', '${user.weight}', 'kg', '')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('BMI', user.bmi.toStringAsFixed(1), 'idx', bmiCategory)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard('WORKOUTS', '$weeklyWorkouts', '/ 6 days', '')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('STREAK', '${user.streak}', 'days', '')),
                ],
              ),
              
              const SizedBox(height: 32),
              Text('7-DAY CONSISTENCY', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              _buildBarChart(workoutProvider, dietProvider),
              
              const SizedBox(height: 32),
              Text('QUICK ACTIONS', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              _buildActionCard(
                icon: Icons.play_arrow,
                title: workoutActionTitle,
                subtitle: workoutActionSubtitle,
                onTap: () {
                  if (!isWorkoutLoggedToday && !isRestDay && todayWorkout != null) {
                    context.push('/workout/active', extra: todayWorkout);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.restaurant,
                title: mealActionTitle,
                subtitle: mealActionSubtitle,
                onTap: () {
                  if (nextMeal != null) {
                    context.go('/diet');
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatCard(String label, String value, String unit, String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelAllcaps),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.dataLarge),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: AppTextStyles.bodySmall),
              ),
            ],
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(category, style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText)),
          ],
        ],
      ),
    );
  }

  Widget _buildBarChart(WorkoutProvider wp, DietProvider dp) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final List<DateTime> weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    final List<double> chartData = weekDays.map((date) {
      bool workoutLogged = wp.isWorkoutLogged(date);
      bool dietLogged = dp.isAnyMealLogged(date);
      
      if (workoutLogged && dietLogged) return 1.0;
      if (workoutLogged || dietLogged) return 0.5;
      return 0.0;
    }).toList();
    
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Column(
            children: [
              Container(
                width: 28,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 28,
                  height: 120 * chartData[index],
                  decoration: BoxDecoration(
                    color: chartData[index] > 0 ? AppColors.progressFill : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(days[index], style: AppTextStyles.bodyMedium),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 16),
          ],
        ),
      ),
    );
  }
}
