import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

class S17CommunityScreen extends StatefulWidget {
  const S17CommunityScreen({Key? key}) : super(key: key);

  @override
  State<S17CommunityScreen> createState() => _S17CommunityScreenState();
}

class _S17CommunityScreenState extends State<S17CommunityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  DateTime _normalizeApiDate(DateTime utcDate) {
    final u = utcDate.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  DateTime _normalizeCalendarDay(DateTime localDay) {
    return DateTime.utc(localDay.year, localDay.month, localDay.day);
  }

  Future<void> _fetchEvents() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('https://gymos-backend-production.up.railway.app/api/app/events'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['events'] is List) {
          final List events = data['events'];
          final Map<DateTime, List<dynamic>> newEvents = {};
          for (var item in events) {
            if (item['event_date'] != null) {
              final parsedDate = DateTime.tryParse(item['event_date'].toString());
              if (parsedDate != null) {
                final normalized = _normalizeApiDate(parsedDate);
                if (newEvents[normalized] == null) {
                  newEvents[normalized] = [];
                }
                newEvents[normalized]!.add(item);
              }
            }
          }
          if (mounted) {
            setState(() {
              _events = newEvents;
            });
          }
        }
      }
    } catch (e) {
      // Fail gracefully
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeCalendarDay(day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('COMMUNITY', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.primaryAccent),
                        ),
                      )
                    : TableCalendar(
                        firstDay: DateTime.now().toUtc().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().toUtc().add(const Duration(days: 365 * 2)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        eventLoader: _getEventsForDay,
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: AppTextStyles.bodyMedium,
                          weekendTextStyle: AppTextStyles.bodyMedium,
                          selectedTextStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.background),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primaryText,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: AppTextStyles.labelLarge,
                          todayDecoration: BoxDecoration(
                            color: AppColors.elevatedSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          outsideTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                          markerDecoration: const BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: AppTextStyles.h3,
                          formatButtonVisible: false,
                          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primaryText),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: AppTextStyles.labelAllcaps,
                          weekendStyle: AppTextStyles.labelAllcaps,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              
              Text('ACTIONS', style: AppTextStyles.labelAllcaps),
              const SizedBox(height: 16),
              
              _CommunityCard(
                title: 'Events',
                icon: Icons.event,
                onTap: () => context.push('/community/events'),
              ),
              _CommunityCard(
                title: 'Subscription Status',
                icon: Icons.card_membership,
                onTap: () => context.push('/community/subscription'),
              ),
              _CommunityCard(
                title: 'Live Song Request',
                icon: Icons.music_note,
                onTap: () => context.push('/community/song-request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _CommunityCard({
    Key? key,
    required this.title,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTextStyles.labelLarge),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 16),
          ],
        ),
      ),
    );
  }
}
