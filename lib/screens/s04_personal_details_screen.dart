import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../providers/user_provider.dart';
import '../widgets/atmospheric_background.dart';

class S04PersonalDetailsScreen extends StatefulWidget {
  const S04PersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<S04PersonalDetailsScreen> createState() => _S04PersonalDetailsScreenState();
}

class _S04PersonalDetailsScreenState extends State<S04PersonalDetailsScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedActivity = 'Active';

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _activities = ['Sedentary', 'Lightly Active', 'Active', 'Very Active'];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Save to provider
    final provider = Provider.of<UserProvider>(context, listen: false);
    provider.setPersonalDetails(
      provider.name, // Use the name from S03 instead of overriding with 'User'
      double.tryParse(_weightController.text) ?? 70.0,
      double.tryParse(_heightController.text) ?? 175.0,
      int.tryParse(_ageController.text) ?? 25,
      _selectedGender,
      _selectedActivity,
    );
    context.push('/onboarding2');
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
        title: Text('STEP 1 OF 3', style: AppTextStyles.labelAllcaps),
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
                  Text('PERSONAL DETAILS', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Help us customize your experience',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  Text('GENDER', style: AppTextStyles.labelAllcaps),
                  const SizedBox(height: 8),
                  Row(
                    children: _genders.map((gender) {
                      final isSelected = _selectedGender == gender;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = gender),
                          child: Container(
                            margin: EdgeInsets.only(right: gender != _genders.last ? 8 : 0),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.border : AppColors.elevatedSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.strongAccent : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              gender,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AGE', style: AppTextStyles.labelAllcaps),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'Years',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WEIGHT', style: AppTextStyles.labelAllcaps),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'kg',
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HEIGHT', style: AppTextStyles.labelAllcaps),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'cm',
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text('ACTIVITY LEVEL', style: AppTextStyles.labelAllcaps),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedActivity,
                        dropdownColor: AppColors.elevatedSurface,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryText),
                        isExpanded: true,
                        style: AppTextStyles.bodyLarge,
                        items: _activities.map((act) {
                          return DropdownMenuItem(
                            value: act,
                            child: Text(act),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedActivity = val);
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  PrimaryButton(
                    text: "CONTINUE",
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
