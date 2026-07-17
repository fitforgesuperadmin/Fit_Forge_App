import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';

class S19EventDetailScreen extends StatefulWidget {
  final String eventId;

  const S19EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<S19EventDetailScreen> createState() => _S19EventDetailScreenState();
}

class _S19EventDetailScreenState extends State<S19EventDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _event;
  List<dynamic> _photos = [];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
  }

  String _formatEventTime(String timeString) {
    if (timeString.isEmpty) return '';
    final DateTime parsedUtc = DateTime.parse(timeString).toUtc();
    
    int hour = parsedUtc.hour;
    final int minute = parsedUtc.minute;
    
    final String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  String _formatDateIndian(String dateString) {
    if (dateString.isEmpty) return '';
    final DateTime date = DateTime.parse(dateString).toUtc();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _fetchEventDetail() async {
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
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/events/${widget.eventId}'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['event'] != null) {
          if (mounted) {
            setState(() {
              _event = data['event'];
              _photos = data['event']['event_photographs'] ?? [];
            });
          }
        } else {
          if (mounted) setState(() { _hasError = true; });
        }
      } else {
        if (mounted) setState(() { _hasError = true; });
      }
    } catch (e) {
      if (mounted) setState(() { _hasError = true; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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
        title: Text('EVENT DETAILS', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchEventDetail,
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

    if (_hasError || _event == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              "Couldn't load event details",
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEventDetail,
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

    final event = _event!;
    final isCompetition = event['is_competition'] == true;
    final dateStr = event['event_date'] != null ? _formatDateIndian(event['event_date'].toString()) : '';
    final startTimeStr = event['start_time'] != null ? _formatEventTime(event['start_time'].toString()) : '';
    final endTimeStr = event['end_time'] != null ? _formatEventTime(event['end_time'].toString()) : '';
    
    String timeDisplay = startTimeStr;
    if (endTimeStr.isNotEmpty) {
      timeDisplay += ' - $endTimeStr';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event['event_name'] ?? 'Unknown Event',
                  style: AppTextStyles.h1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompetition ? AppColors.primaryAccent.withOpacity(0.1) : AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompetition ? AppColors.primaryAccent : AppColors.border,
                  ),
                ),
                child: Text(
                  isCompetition ? 'Competition' : 'Regular Event',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCompetition ? AppColors.primaryAccent : AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                timeDisplay,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('ABOUT', style: AppTextStyles.labelAllcaps),
            const SizedBox(height: 8),
            Text(
              event['description'],
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ],
          
          if (isCompetition) ...[
            const SizedBox(height: 32),
            Text('RESULTS', style: AppTextStyles.labelAllcaps),
            const SizedBox(height: 16),
            if (event['first_prize_user_name'] == null && 
                event['second_prize_user_name'] == null && 
                event['third_prize_user_name'] == null)
              Text(
                'Results not declared yet.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (event['first_prize_user_name'] != null)
                      _ResultRow(position: '1st', name: event['first_prize_user_name'], color: const Color(0xFFFFD700)),
                    if (event['second_prize_user_name'] != null) ...[
                      if (event['first_prize_user_name'] != null)
                        const Divider(color: AppColors.border, height: 24),
                      _ResultRow(position: '2nd', name: event['second_prize_user_name'], color: const Color(0xFFC0C0C0)),
                    ],
                    if (event['third_prize_user_name'] != null) ...[
                      if (event['first_prize_user_name'] != null || event['second_prize_user_name'] != null)
                        const Divider(color: AppColors.border, height: 24),
                      _ResultRow(position: '3rd', name: event['third_prize_user_name'], color: const Color(0xFFCD7F32)),
                    ],
                  ],
                ),
              ),
          ],

          const SizedBox(height: 32),
          Text('PHOTOS', style: AppTextStyles.labelAllcaps),
          const SizedBox(height: 16),
          if (_photos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No photos uploaded yet.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photoUrl = _photos[index]['photo_url'];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.elevatedSurface,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? const Icon(Icons.image_not_supported, color: AppColors.muted)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String position;
  final String name;
  final Color color;

  const _ResultRow({
    Key? key,
    required this.position,
    required this.name,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            position,
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.h3,
          ),
        ),
      ],
    );
  }
}
