import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';
import '../widgets/atmospheric_background.dart';

class S03RegisterScreen extends StatefulWidget {
  const S03RegisterScreen({Key? key}) : super(key: key);

  @override
  State<S03RegisterScreen> createState() => _S03RegisterScreenState();
}

class _S03RegisterScreenState extends State<S03RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  bool _showPasswordChecked = false;

  String _errorMessage = '';

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (response.user != null) {
        final identities = response.user!.identities;
        if (identities != null && identities.isEmpty) {
          // Email already registered — this is NOT a new account
          if (mounted) {
            setState(() {
              _errorMessage = 'An account with this email already exists. Please log in instead.';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          // Temporarily store the name in UserProvider so it's available after onboarding
          // S04 currently overrides this with 'User', we will adjust S04 to preserve it.
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setPersonalDetails(
            _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim(),
            userProvider.weight,
            userProvider.height,
            userProvider.age,
            userProvider.gender,
            userProvider.activityLevel,
          );
          
          context.go('/gym-id-entry');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      ),
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREATE ACCOUNT', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Join FORGE today',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    hintText: 'Full Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
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
                  CustomTextField(
                    hintText: 'Confirm password',
                    controller: _confirmPasswordController,
                    obscureText: _confirmPasswordObscured,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF666666),
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordObscured = !_confirmPasswordObscured;
                        });
                      },
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPasswordChecked = !_showPasswordChecked;
                            _passwordObscured = !_showPasswordChecked;
                            _confirmPasswordObscured = !_showPasswordChecked;
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
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: "REGISTER",
                    isLoading: _isLoading,
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
