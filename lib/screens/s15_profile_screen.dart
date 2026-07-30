import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/user_provider.dart';
import '../models/models.dart';
import '../widgets/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/hive_service.dart';
import '../widgets/avatar_picker_bottom_sheet.dart';

class S15ProfileScreen extends StatefulWidget {
  const S15ProfileScreen({Key? key}) : super(key: key);

  @override
  State<S15ProfileScreen> createState() => _S15ProfileScreenState();
}

class _S15ProfileScreenState extends State<S15ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: () => context.go('/dashboard'),
          ),
          title: Text('PROFILE', style: AppTextStyles.labelAllcaps),
          centerTitle: true,
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showAvatarPicker(
                    context,
                    currentAvatarId: userProvider.avatarId,
                    onAvatarSelected: (newAvatarId) {
                      userProvider.setAvatarId(newAvatarId);
                    },
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.elevatedSurface,
                    border: Border.all(
                      color: userProvider.avatarId != null ? AppColors.primaryAccent : AppColors.border, 
                      width: 2
                    ),
                  ),
                  child: userProvider.avatarId != null
                      ? ClipOval(
                          child: Image.asset(
                            'assets/avatars/avatar_${userProvider.avatarId.toString().padLeft(2, '0')}.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.primaryText, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(userProvider.name.toUpperCase(), style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(_getGoalName(userProvider.goal)),
                  const SizedBox(width: 8),
                  _buildBadge(_getIntensityName(userProvider.intensity)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Stats Strip
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('WEIGHT', '${userProvider.weight} kg'),
                    Container(width: 1, height: 40, color: AppColors.border),
                    _buildStat('AGE', '${userProvider.age} yrs'),
                    Container(width: 1, height: 40, color: AppColors.border),
                    _buildStat('HEIGHT', '${userProvider.height} cm'),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('SETTINGS', style: AppTextStyles.labelAllcaps),
              ),
              const SizedBox(height: 16),
              
              _buildNavigationTile('Change Goal', () => context.push('/onboarding2')),
              _buildNavigationTile('Change Intensity', () => context.push('/onboarding2')),
              _buildNavigationTile('Change Diet Type', () => context.push('/onboarding3')),
              
              _buildSettingTile('Push Notifications', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
              
              const SizedBox(height: 48),
              SecondaryButton(
                text: "SIGN OUT",
                onPressed: () async {
                  // Clear local Hive cache
                  await HiveService.userProfileBox.clear();
                  await HiveService.workoutLogsBox.clear();
                  await HiveService.dietLogsBox.clear();
                  
                  // Real Supabase sign out
                  await Supabase.instance.client.auth.signOut();
                  
                  if (context.mounted) {
                    context.go('/login');
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

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.bodySmall),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelAllcaps),
      ],
    );
  }
  
  Widget _buildSettingTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryText,
            activeTrackColor: AppColors.strongAccent,
            inactiveThumbColor: AppColors.secondaryText,
            inactiveTrackColor: AppColors.background,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.labelLarge),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
  
  String _getGoalName(Goal goal) {
    switch (goal) {
      case Goal.fatLoss: return 'Fat Loss';
      case Goal.muscleGain: return 'Muscle Gain';
      case Goal.leanRecomposition: return 'Lean Recomp';
      case Goal.strengthPower: return 'Strength & Power';
      case Goal.enduranceFitness: return 'Endurance';
    }
  }
  
  String _getIntensityName(Intensity intensity) {
    switch (intensity) {
      case Intensity.low: return 'Low';
      case Intensity.medium: return 'Medium';
      case Intensity.high: return 'High';
    }
  }
}
