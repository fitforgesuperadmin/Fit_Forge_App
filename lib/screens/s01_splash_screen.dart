import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/custom_progress.dart';
import '../widgets/atmospheric_background.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/diet_provider.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class S01SplashScreen extends StatefulWidget {
  const S01SplashScreen({Key? key}) : super(key: key);

  @override
  State<S01SplashScreen> createState() => _S01SplashScreenState();
}

class _S01SplashScreenState extends State<S01SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    
    Timer(const Duration(seconds: 2), () async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        
        if (HiveService.userRole == 'trainer') {
          if (mounted) {
            context.go('/trainer-dashboard');
          }
          return;
        }

        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', session.user.id)
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

            bool isLinked = HiveService.isGymLinked;
            
            if (!isLinked) {
              try {
                final response = await http.get(
                  Uri.parse('https://gymos-backend-production.up.railway.app/api/app/check-link'),
                  headers: {
                    'Authorization': 'Bearer ${session.accessToken}',
                  },
                ).timeout(const Duration(seconds: 5));
                
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['linked'] == true) {
                    await HiveService.setGymLinked(true);
                    isLinked = true;
                  } else if (data['linked'] == false) {
                    if (mounted) {
                      context.go('/gym-id-entry');
                      return;
                    }
                  } else {
                    isLinked = true;
                  }
                } else {
                  isLinked = true;
                }
              } catch (e) {
                isLinked = true;
              }
            }

            if (profileData['onboarding_complete'] == true) {
              context.go('/dashboard');
            } else {
              context.go('/onboarding1');
            }
          }
        } catch (e) {
          if (mounted) {
            context.go('/login');
          }
        }
      } else {
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AtmosphericBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FORGE',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 48,
                      letterSpacing: 48 * 0.12, // 0.12em
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomLinearProgress(progress: _animation.value);
                    },
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
