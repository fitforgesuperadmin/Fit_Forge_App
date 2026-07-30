import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';
import '../models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/atmospheric_background.dart';

class S05BDietPreferenceScreen extends StatefulWidget {
  const S05BDietPreferenceScreen({Key? key}) : super(key: key);

  @override
  State<S05BDietPreferenceScreen> createState() => _S05BDietPreferenceScreenState();
}

class _S05BDietPreferenceScreenState extends State<S05BDietPreferenceScreen> with SingleTickerProviderStateMixin {
  DietType _selectedDietType = DietType.hybrid;

  final Map<DietType, String> _dietLabels = {
    DietType.pureVegetarian: 'Pure Vegetarian',
    DietType.vegetarianPlusEggs: 'Vegetarian + Eggs',
    DietType.nonVegetarian: 'Non Vegetarian',
    DietType.hybrid: 'Hybrid',
  };

  final Map<DietType, String> _dietDescriptions = {
    DietType.pureVegetarian: 'No meat, no eggs. Dairy and plant-based only.',
    DietType.vegetarianPlusEggs: 'Plant-based diet with eggs allowed.',
    DietType.nonVegetarian: 'All foods including chicken, fish and eggs.',
    DietType.hybrid: 'Mix of vegetarian and non-vegetarian meals.',
  };

  void _navigateToAvatarPicker() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setDietType(_selectedDietType);
    context.push('/avatar-picker');
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
        title: Text('STEP 3 OF 4', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          AtmosphericBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIET PREFERENCE', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your diet type.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  ...DietType.values.map((dietType) {
                    final isSelected = _selectedDietType == dietType;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDietType = dietType),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dietLabels[dietType]!,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dietDescriptions[dietType]!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: AppColors.strongAccent),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 48),
                  PrimaryButton(
                    text: "CONTINUE",
                    onPressed: _navigateToAvatarPicker,
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
