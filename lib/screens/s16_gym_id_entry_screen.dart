import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/atmospheric_background.dart';
import '../services/hive_service.dart';

class S16GymIdEntryScreen extends StatefulWidget {
  const S16GymIdEntryScreen({Key? key}) : super(key: key);

  @override
  State<S16GymIdEntryScreen> createState() => _S16GymIdEntryScreenState();
}

class _S16GymIdEntryScreenState extends State<S16GymIdEntryScreen> {
  final TextEditingController _gymIdController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _linkGymId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      setState(() {
        _errorMessage = 'Session expired. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/link-gym-id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'generatedId': _gymIdController.text.trim().toUpperCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final role = data['role'] ?? 'member';
          
          await HiveService.setGymLinked(true);
          await HiveService.setUserRole(role);
          if (data['fullName'] != null) {
            await HiveService.userProfileBox.put('name', data['fullName']);
          }

          if (mounted) {
            if (role == 'trainer') {
              context.go('/trainer-dashboard');
            } else {
              context.go('/onboarding1');
            }
          }
        } else {
          setState(() => _errorMessage = 'Failed to link gym. Please try again.');
        }
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage = 'Gym ID not found. Please check with your gym administrator.');
      } else if (response.statusCode == 409) {
        setState(() => _errorMessage = 'This Gym ID is already linked to another account.');
      } else {
        setState(() => _errorMessage = 'Something went wrong. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _gymIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('LINK YOUR GYM', style: AppTextStyles.labelAllcaps),
      ),
      body: Stack(
        children: [
          const AtmosphericBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Text('Enter Your Gym ID', style: AppTextStyles.h2, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    'Your gym administrator has provided you with a unique member ID. Enter it below to connect your account.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    hintText: 'e.g. TEST100-01-0001',
                    controller: _gymIdController,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorMessage,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: Colors.redAccent),
                      ),
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    text: 'LINK MY GYM',
                    isLoading: _isLoading,
                    onPressed: _linkGymId,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
