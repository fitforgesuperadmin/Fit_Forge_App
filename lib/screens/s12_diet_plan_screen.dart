import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/diet_provider.dart';
import '../widgets/custom_progress.dart';

class S12DietPlanScreen extends StatelessWidget {
  const S12DietPlanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dietProvider = Provider.of<DietProvider>(context);
    final plan = dietProvider.currentPlan;

    if (plan == null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          context.go('/dashboard');
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final int consumedCals = dietProvider.currentConsumedCalories;
    final int remainingCals = plan.dailyTargetCalories - consumedCals;
    final double progress = consumedCals / plan.dailyTargetCalories;

    // Check if all meals have at least one item consumed to show the summary button
    bool showSummaryBtn = dietProvider.consumedItems.values.any((v) => v);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('DIET PLAN', style: AppTextStyles.labelAllcaps),
          centerTitle: true,
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TODAY', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Hit your macros to fuel your workout.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // Calorie Summary Card
              Container(
                padding: const EdgeInsets.all(24),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CONSUMED', style: AppTextStyles.labelAllcaps),
                            const SizedBox(height: 4),
                            Text('$consumedCals', style: AppTextStyles.dataLarge),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('REMAINING', style: AppTextStyles.labelAllcaps),
                            const SizedBox(height: 4),
                            Text('${remainingCals > 0 ? remainingCals : 0}', style: AppTextStyles.dataMedium.copyWith(color: AppColors.secondaryText)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomLinearProgress(progress: progress),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMacro('PROTEIN', dietProvider.currentConsumedProtein, plan.targetProtein, 'g'),
                        _buildMacro('CARBS', dietProvider.currentConsumedCarbs, plan.targetCarbs, 'g'),
                        _buildMacro('FATS', dietProvider.currentConsumedFats, plan.targetFats, 'g'),
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Text('MEALS', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              
              ...plan.meals.map((meal) {
                // Check if this meal is entirely done
                bool isCompleted = meal.items.every((i) => dietProvider.isItemConsumed(meal.name, i.name));
                return GestureDetector(
                  onTap: () => context.push('/diet/meal', extra: meal),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isCompleted ? AppColors.strongAccent : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isCompleted ? AppColors.strongAccent : AppColors.border),
                            color: isCompleted ? AppColors.strongAccent : Colors.transparent,
                          ),
                          child: isCompleted ? const Icon(Icons.check, size: 16, color: AppColors.background) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.name.toUpperCase(), style: AppTextStyles.labelLarge),
                              const SizedBox(height: 4),
                              Text('${meal.totalCalories} kcal', style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              if (showSummaryBtn) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/diet/summary'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('VIEW NUTRITION SUMMARY', style: AppTextStyles.labelLarge),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMacro(String label, int consumed, int target, String unit) {
    bool isExceeded = consumed > target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelAllcaps),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$consumed', 
              style: AppTextStyles.dataMedium.copyWith(
                fontSize: 16,
                color: isExceeded ? const Color(0xFFCE9E9E) : AppColors.primaryText,
              ),
            ),
            Text(
              ' / ', 
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
            Text(
              '$target$unit', 
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
          ],
        )
      ],
    );
  }
}
