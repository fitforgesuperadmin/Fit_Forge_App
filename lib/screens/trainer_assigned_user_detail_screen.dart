import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';
import '../theme/theme.dart';

class TrainerAssignedUserDetailScreen extends StatefulWidget {
  final String gymUserIdStr;
  
  const TrainerAssignedUserDetailScreen({
    Key? key,
    required this.gymUserIdStr,
  }) : super(key: key);

  @override
  State<TrainerAssignedUserDetailScreen> createState() => _TrainerAssignedUserDetailScreenState();
}

class _TrainerAssignedUserDetailScreenState extends State<TrainerAssignedUserDetailScreen> {
  int? _gymUserId;
  bool _parseError = false;

  @override
  void initState() {
    super.initState();
    _gymUserId = int.tryParse(widget.gymUserIdStr);
    if (_gymUserId == null) {
      _parseError = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TrainerProvider>().fetchUserDetail(_gymUserId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text('MEMBER DETAIL', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _parseError 
            ? _buildErrorState('Invalid User ID. Please try again.', () => context.pop())
            : Consumer<TrainerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryAccent),
                    );
                  }

                  if (provider.error.isNotEmpty) {
                    return _buildErrorState(
                      provider.error,
                      () => provider.fetchUserDetail(_gymUserId!),
                    );
                  }

                  final detail = provider.selectedUserDetail;
                  if (detail == null) {
                    return const SizedBox.shrink();
                  }

                  final bool isComplete = detail['profileComplete'] == true;
                  final String fullName = detail['fullName'] ?? 'Unknown';
                  final String generatedId = detail['generatedId'] ?? '';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        Text(
                          generatedId, 
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText)
                        ),
                        const SizedBox(height: 32),

                        if (!isComplete)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.primaryText),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "This member hasn't completed their profile yet.",
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildProfileData(detail),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileData(Map<String, dynamic> detail) {
    final double weightKg = (detail['weightKg'] as num?)?.toDouble() ?? 0.0;
    final double heightCm = (detail['heightCm'] as num?)?.toDouble() ?? 0.0;
    double bmi = 0.0;
    if (heightCm > 0) {
      bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('WEIGHT', '$weightKg', 'kg')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('HEIGHT', '$heightCm', 'cm')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('BMI', bmi.toStringAsFixed(1), 'idx')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('AGE', '${detail['age'] ?? '-'}', 'yrs')),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailRow('GENDER', '${detail['gender'] ?? '-'}'),
        const SizedBox(height: 12),
        _buildDetailRow('GOAL', '${detail['goal'] ?? '-'}'),
        const SizedBox(height: 12),
        _buildDetailRow('INTENSITY', '${detail['intensity'] ?? '-'}'),
        const SizedBox(height: 12),
        _buildDetailRow('DIET TYPE', '${detail['dietType'] ?? '-'}'),
        const SizedBox(height: 12),
        _buildDetailRow('ACTIVITY LEVEL', '${detail['activityLevel'] ?? '-'}'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelAllcaps),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.dataLarge),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: AppTextStyles.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.labelAllcaps),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMsg, VoidCallback onTryAgain) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            errorMsg,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTryAgain,
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
}
