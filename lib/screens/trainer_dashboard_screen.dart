import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';
import '../services/hive_service.dart';
import '../theme/theme.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TrainerProvider>();
      if (provider.assignedUsers.isEmpty && !provider.isLoading) {
        provider.fetchAssignedUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read trainer's name directly from Hive (saved during S16 link)
    final trainerName = HiveService.userProfileBox.get('name', defaultValue: 'Trainer');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<TrainerProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRAINER DASHBOARD', style: AppTextStyles.labelAllcaps),
                      const SizedBox(height: 4),
                      Text('Welcome, $trainerName', style: AppTextStyles.h2),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(TrainerProvider provider) {
    if (provider.isLoading && provider.assignedUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      );
    }

    if (provider.error.isNotEmpty && provider.assignedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              provider.error,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchAssignedUsers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.elevatedSurface,
                foregroundColor: AppColors.primaryText,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchAssignedUsers,
      color: AppColors.primaryAccent,
      child: provider.count == 0
          ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group, size: 48, color: AppColors.muted),
                        const SizedBox(height: 16),
                        Text(
                          "No members assigned yet",
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              itemCount: provider.assignedUsers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASSIGNED MEMBERS', style: AppTextStyles.labelAllcaps),
                        const SizedBox(height: 8),
                        Text('${provider.count}', style: AppTextStyles.dataLarge),
                      ],
                    ),
                  );
                }

                final user = provider.assignedUsers[index - 1];
                return GestureDetector(
                  onTap: () {
                    context.push('/trainer-dashboard/user/${user['gymUserId']}');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['fullName'] ?? 'Unknown User',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['generatedId'] ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
