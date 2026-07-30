import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/theme.dart';
import 'providers/user_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/diet_provider.dart';
import 'providers/trainer_provider.dart';

import 'screens/s01_splash_screen.dart';
import 'screens/s02_login_screen.dart';
import 'screens/s03_register_screen.dart';
import 'screens/s04_personal_details_screen.dart';
import 'screens/s05_goal_intensity_screen.dart';
import 'screens/s05b_diet_preference_screen.dart';
import 'screens/s06_dashboard_screen.dart';
import 'screens/s07_workout_list_screen.dart';
import 'screens/s08_workout_detail_screen.dart';
import 'screens/s09_active_session_screen.dart';
import 'screens/s11_post_workout_screen.dart';
import 'screens/s12_diet_plan_screen.dart';
import 'screens/s13_meal_detail_screen.dart';
import 'screens/s14_nutrition_summary_screen.dart';
import 'screens/s15_profile_screen.dart';
import 'screens/s16_gym_id_entry_screen.dart';
import 'screens/s17_community_screen.dart';
import 'screens/s18_events_list_screen.dart';
import 'screens/s19_event_detail_screen.dart';
import 'screens/s20_subscription_status_screen.dart';
import 'screens/s21_song_request_screen.dart';
import 'screens/s22_past_workout_summary_screen.dart';
import 'screens/s05c_avatar_picker_screen.dart';
import 'screens/trainer_dashboard_screen.dart';
import 'screens/trainer_assigned_user_detail_screen.dart';
import 'screens/s16b_trainer_profile_setup_screen.dart';
import 'screens/trainer_profile_screen.dart';
import 'models/models.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://awcglgqwfisrmycuqwjo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3Y2dsZ3F3Zmlzcm15Y3Vxd2pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NTc3NjQsImV4cCI6MjA5NDIzMzc2NH0.Pdcm68gPO2_0Hf_EG21LBckMi632HfNPqY588_EFzRg',
  );

  await HiveService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => TrainerProvider()),
      ],
      child: const ForgeApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const S01SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const S02LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const S03RegisterScreen(),
    ),
    GoRoute(
      path: '/gym-id-entry',
      builder: (context, state) => const S16GymIdEntryScreen(),
    ),
    GoRoute(
      path: '/onboarding1',
      builder: (context, state) => const S04PersonalDetailsScreen(),
    ),
    GoRoute(
      path: '/onboarding2',
      builder: (context, state) => const S05GoalIntensityScreen(),
    ),
    GoRoute(
      path: '/onboarding3',
      builder: (context, state) => const S05BDietPreferenceScreen(),
    ),
    GoRoute(
      path: '/avatar-picker',
      builder: (context, state) => const S05CAvatarPickerScreen(),
    ),
    GoRoute(
      path: '/trainer-profile-setup',
      builder: (context, state) => const S16bTrainerProfileSetupScreen(),
    ),
    GoRoute(
      path: '/trainer-profile',
      builder: (context, state) => const TrainerProfileScreen(),
    ),
    GoRoute(
      path: '/trainer-dashboard',
      builder: (context, state) => const TrainerDashboardScreen(),
      routes: [
        GoRoute(
          path: 'user/:gymUserId',
          builder: (context, state) {
            final gymUserId = state.pathParameters['gymUserId']!;
            return TrainerAssignedUserDetailScreen(gymUserIdStr: gymUserId);
          },
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) => NoTransitionPage(
        child: Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.background,
            selectedItemColor: AppColors.primaryText,
            unselectedItemColor: AppColors.muted,
            currentIndex: _calculateSelectedIndex(state.matchedLocation),
            onTap: (int idx) => _onItemTapped(idx, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Diet'),
              BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
            ],
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: S06DashboardScreen()),
        ),
        GoRoute(
          path: '/workout',
          pageBuilder: (context, state) => const NoTransitionPage(child: S07WorkoutListScreen()),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) {
                final day = state.extra as WorkoutDay?;
                return S08WorkoutDetailScreen(workoutDay: day);
              },
            ),
            GoRoute(
              path: 'active',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final day = state.extra as WorkoutDay?;
                return S09ActiveSessionScreen(workoutDay: day);
              },
            ),
            GoRoute(
              path: 'summary',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final day = state.extra as WorkoutDay?;
                return S11PostWorkoutScreen(workoutDay: day);
              },
            ),
            GoRoute(
              path: 'past-summary',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final map = state.extra as Map<String, dynamic>?;
                if (map != null) {
                  return S22PastWorkoutSummaryScreen(
                    workoutDay: map['workoutDay'] as WorkoutDay?,
                    targetDate: map['targetDate'] as DateTime?,
                  );
                }
                return const S22PastWorkoutSummaryScreen();
              },
            ),
          ]
        ),
        GoRoute(
          path: '/diet',
          pageBuilder: (context, state) => const NoTransitionPage(child: S12DietPlanScreen()),
          routes: [
            GoRoute(
              path: 'meal',
              builder: (context, state) {
                final meal = state.extra as Meal?;
                return S13MealDetailScreen(meal: meal);
              },
            ),
            GoRoute(
              path: 'summary',
              builder: (context, state) => const S14NutritionSummaryScreen(),
            ),
          ]
        ),
        GoRoute(
          path: '/community',
          pageBuilder: (context, state) => const NoTransitionPage(child: S17CommunityScreen()),
          routes: [
            GoRoute(
              path: 'events',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const S18EventsListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id'];
                    return S19EventDetailScreen(eventId: id!);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'subscription',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const S20SubscriptionStatusScreen(),
            ),
            GoRoute(
              path: 'song-request',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const S21SongRequestScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const S15ProfileScreen(),
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/dashboard')) return 0;
  if (location.startsWith('/workout')) return 1;
  if (location.startsWith('/diet')) return 2;
  if (location.startsWith('/community')) return 3;
  return 0;
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go('/dashboard');
      break;
    case 1:
      context.go('/workout');
      break;
    case 2:
      context.go('/diet');
      break;
    case 3:
      context.go('/community');
      break;
  }
}

class ForgeApp extends StatelessWidget {
  const ForgeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FORGE',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
