import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';

class S20SubscriptionStatusScreen extends StatefulWidget {
  const S20SubscriptionStatusScreen({Key? key}) : super(key: key);

  @override
  State<S20SubscriptionStatusScreen> createState() => _S20SubscriptionStatusScreenState();
}

class _S20SubscriptionStatusScreenState extends State<S20SubscriptionStatusScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchSubscription();
  }

  Future<void> _fetchSubscription() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (mounted) setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final response = await http.get(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/subscription'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['subscription'] != null) {
          if (mounted) {
            setState(() {
              _subscription = data['subscription'];
              _isLoading = false;
            });
          }
        } else {
          // No subscription found (e.g. success: false or subscription is null)
          if (mounted) {
            setState(() {
              _subscription = null; // Mark as successfully fetched but empty
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() { _hasError = true; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  DateTime _normalizeDate(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  String _formatDateIndian(DateTime normalizedDate) {
    return '${normalizedDate.day.toString().padLeft(2, '0')}/${normalizedDate.month.toString().padLeft(2, '0')}/${normalizedDate.year}';
  }

  Color _getStatusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s == 'active') return AppColors.primaryAccent;
    if (s == 'expired') return AppColors.error;
    if (s == 'pending') return const Color(0xFFFFD700);
    return AppColors.muted;
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
        title: Text('SUBSCRIPTION', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchSubscription,
          color: AppColors.primaryAccent,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              "Couldn't load subscription details",
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSubscription,
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

    if (_subscription == null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_membership, size: 48, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text(
                    "No subscription details found",
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final sub = _subscription!;
    final String type = sub['subscription_type'] ?? 'Unknown';
    final String status = sub['status'] ?? 'Unknown';
    final bool isPaused = sub['is_paused'] == true;

    final DateTime today = _normalizeDate(DateTime.now());
    
    DateTime? start;
    DateTime? end;
    if (sub['start_date'] != null) {
      start = _normalizeDate(DateTime.parse(sub['start_date']));
    }
    if (sub['end_date'] != null) {
      end = _normalizeDate(DateTime.parse(sub['end_date']));
    }

    int totalDurationDays = 0;
    int daysRemaining = 0;
    int daysRemainingDisplay = 0;
    int daysElapsed = 0;
    double progress = 0.0;

    if (start != null && end != null) {
      totalDurationDays = end.difference(start).inDays;
      daysRemaining = end.difference(today).inDays;
      daysRemainingDisplay = daysRemaining < 0 ? 0 : daysRemaining;
      daysElapsed = today.difference(start).inDays;

      if (totalDurationDays > 0) {
        progress = (daysElapsed / totalDurationDays).clamp(0.0, 1.0);
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: AppTextStyles.h2,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPaused) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00).withOpacity(0.15), // Orange
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pause, size: 14, color: Color(0xFFFF8C00)),
                                const SizedBox(width: 4),
                                Text(
                                  'Paused',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFFF8C00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                if (start != null && end != null) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('START DATE', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateIndian(start),
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('END DATE', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateIndian(end),
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$daysRemainingDisplay Days Remaining',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
