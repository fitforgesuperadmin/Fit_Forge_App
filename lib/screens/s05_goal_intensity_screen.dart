import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';
import '../models/models.dart';
import '../widgets/atmospheric_background.dart';

class S05GoalIntensityScreen extends StatefulWidget {
  const S05GoalIntensityScreen({Key? key}) : super(key: key);

  @override
  State<S05GoalIntensityScreen> createState() => _S05GoalIntensityScreenState();
}

class _S05GoalIntensityScreenState extends State<S05GoalIntensityScreen> {
  Goal _selectedGoal = Goal.muscleGain;
  Intensity _selectedIntensity = Intensity.medium;

  final Map<Goal, String> _goalLabels = {
    Goal.fatLoss: 'Fat Loss',
    Goal.muscleGain: 'Muscle Gain',
    Goal.leanRecomposition: 'Lean Recomp',
    Goal.strengthPower: 'Strength & Power',
    Goal.enduranceFitness: 'Endurance',
  };

  final Map<Intensity, String> _intensityLabels = {
    Intensity.low: 'Low',
    Intensity.medium: 'Medium',
    Intensity.high: 'High',
  };

  bool _isNavigating = false;

  void _nextStep() {
    setState(() {
      _isNavigating = true;
    });
    
    // Save to user provider
    Provider.of<UserProvider>(context, listen: false)
        .setGoalAndIntensity(_selectedGoal, _selectedIntensity);
        
    context.push('/onboarding3');
    
    setState(() {
      _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text('STEP 2 OF 3', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GOALS & INTENSITY', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Define your targets',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              Text('PRIMARY GOAL', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              ...Goal.values.map((goal) {
                final isSelected = _selectedGoal == goal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGoal = goal),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAccent : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _goalLabels[goal]!,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.strongAccent),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 24),
              Text('WORKOUT INTENSITY', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              Row(
                children: Intensity.values.map((intensity) {
                  final isSelected = _selectedIntensity == intensity;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIntensity = intensity),
                      child: Container(
                        margin: EdgeInsets.only(right: intensity != Intensity.high ? 8 : 0),
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.border : AppColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.strongAccent : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _intensityLabels[intensity]!,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 48),
              PrimaryButton(
                text: "CONTINUE",
                isLoading: _isNavigating,
                onPressed: _nextStep,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
