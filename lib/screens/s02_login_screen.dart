import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';
import '../models/models.dart';
import '../widgets/atmospheric_background.dart';

class S02LoginScreen extends StatefulWidget {
  const S02LoginScreen({Key? key}) : super(key: key);

  @override
  State<S02LoginScreen> createState() => _S02LoginScreenState();
}

class _S02LoginScreenState extends State<S02LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordObscured = true;
  bool _showPasswordChecked = false;

  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user != null) {
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
            
        if (mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setPersonalDetails(
            profileData['name'],
            (profileData['weight_kg'] as num).toDouble(),
            (profileData['height_cm'] as num).toDouble(),
            profileData['age'],
            profileData['gender'],
            profileData['activity_level'],
          );
          
          final goal = Goal.values.firstWhere((e) => e.name == profileData['goal'], orElse: () => Goal.muscleGain);
          final intensity = Intensity.values.firstWhere((e) => e.name == profileData['intensity'], orElse: () => Intensity.medium);
          userProvider.setGoalAndIntensity(goal, intensity);
          
          final dietType = DietType.values.firstWhere((e) => e.name == profileData['diet_type'], orElse: () => DietType.hybrid);
          userProvider.setDietType(dietType);
          
          if (profileData['avatar_id'] != null) {
            userProvider.setAvatarId(profileData['avatar_id']);
          }

          Provider.of<WorkoutProvider>(context, listen: false).initializePlan(goal, intensity);
          Provider.of<DietProvider>(context, listen: false).initializePlan(goal, intensity, dietType);

          if (profileData['onboarding_complete'] == true) {
            context.go('/dashboard');
          } else {
            context.go('/onboarding1');
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        if (mounted) {
          context.go('/onboarding1');
        }
      } else {
        print('Login Error: $e');
        if (mounted) {
          setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text('WELCOME BACK', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to continue',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    hintText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: _passwordObscured,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordObscured ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF666666),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordObscured = !_passwordObscured;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPasswordChecked = !_showPasswordChecked;
                            _passwordObscured = !_showPasswordChecked;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _showPasswordChecked ? const Color(0xFF9E9E9E) : Colors.transparent,
                            border: Border.all(color: const Color(0xFF3A3A3A)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: _showPasswordChecked
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Show password',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: "LET'S GO",
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account? ', style: AppTextStyles.bodyMedium),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          'Register',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.strongAccent),
                        ),
                      ),
                    ],
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
