import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/atmospheric_background.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';

class S05CAvatarPickerScreen extends StatefulWidget {
  const S05CAvatarPickerScreen({Key? key}) : super(key: key);

  @override
  State<S05CAvatarPickerScreen> createState() => _S05CAvatarPickerScreenState();
}

class _S05CAvatarPickerScreenState extends State<S05CAvatarPickerScreen> with SingleTickerProviderStateMixin {
  int? _selectedAvatarId;
  
  late AnimationController _blinkController;
  late Animation<double> _beamIntensity;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _beamIntensity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 3.0), weight: 150.0),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 3.0), weight: 300.0),
    ]).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _triggerBlinkAndFinish() {
    if (_selectedAvatarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an avatar to continue.')),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });
    
    _blinkController.forward().then((_) {
      _finishOnboarding();
    });
  }

  Future<void> _finishOnboarding() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': session.user.id,
          'name': userProvider.name,
          'weight_kg': userProvider.weight,
          'height_cm': userProvider.height,
          'age': userProvider.age,
          'gender': userProvider.gender,
          'activity_level': userProvider.activityLevel,
          'goal': userProvider.goal.name,
          'intensity': userProvider.intensity.name,
          'diet_type': userProvider.dietType.name,
          'avatar_id': _selectedAvatarId,
          'onboarding_complete': true,
        });
      } catch (e) {
        print('Error saving profile: $e');
        // silently handle or log if needed
      }
    }

    if (mounted) {
      // Initialize plans
      Provider.of<WorkoutProvider>(context, listen: false)
          .initializePlan(userProvider.goal, userProvider.intensity);
      Provider.of<DietProvider>(context, listen: false)
          .initializePlan(userProvider.goal, userProvider.intensity, userProvider.dietType);

      userProvider.setAvatarId(_selectedAvatarId!);
      context.go('/dashboard');
    }
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
        title: Text('STEP 4 OF 4', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          AtmosphericBackground(beamIntensity: _beamIntensity),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHOOSE AVATAR', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text(
                        'Select a profile picture to represent you.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final avatarId = index + 1;
                      final isSelected = _selectedAvatarId == avatarId;
                      final imagePath = 'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatarId = avatarId),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryAccent : AppColors.border,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: PrimaryButton(
                    text: "LET'S BUILD YOUR PLAN",
                    isLoading: _isNavigating,
                    onPressed: _selectedAvatarId != null ? _triggerBlinkAndFinish : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
