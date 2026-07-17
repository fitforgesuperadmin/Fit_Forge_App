import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/theme.dart';

class S18EventsListScreen extends StatefulWidget {
  const S18EventsListScreen({Key? key}) : super(key: key);

  @override
  State<S18EventsListScreen> createState() => _S18EventsListScreenState();
}

class _S18EventsListScreenState extends State<S18EventsListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _allEvents = [];
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
          final Map<DateTime, List<dynamic>> newEventsMap = {};
          
          for (var item in events) {
            if (item['event_date'] != null) {
              final parsedDate = DateTime.tryParse(item['event_date'].toString());
              if (parsedDate != null) {
                final normalized = _normalizeApiDate(parsedDate);
                if (newEventsMap[normalized] == null) {
                  newEventsMap[normalized] = [];
                }
                newEventsMap[normalized]!.add(item);
              }
            }
          }
          if (mounted) {
            setState(() {
              _events = newEventsMap;
              _allEvents = events;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text('EVENTS', style: AppTextStyles.labelAllcaps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent),
              )
            : SingleChildScrollView(
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
                      child: TableCalendar(
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
                    Text('ALL EVENTS', style: AppTextStyles.labelAllcaps),
                    const SizedBox(height: 16),
                    if (_allEvents.isEmpty)
                      Center(
                        child: Text(
                          'No events found.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allEvents.length,
                        itemBuilder: (context, index) {
                          final event = _allEvents[index];
                          final isCompetition = event['is_competition'] == true;
                          final dateStr = event['event_date'] != null ? _formatDateIndian(event['event_date'].toString()) : '';
                          final startTimeStr = event['start_time'] != null ? _formatEventTime(event['start_time'].toString()) : '';
                          final endTimeStr = event['end_time'] != null ? _formatEventTime(event['end_time'].toString()) : '';
                          
                          String timeDisplay = startTimeStr;
                          if (endTimeStr.isNotEmpty) {
                            timeDisplay += ' - $endTimeStr';
                          }

                          return GestureDetector(
                            onTap: () {
                              context.push('/community/events/${event['id']}');
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event['event_name'] ?? 'Unknown Event',
                                          style: AppTextStyles.h3,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCompetition ? AppColors.primaryAccent.withOpacity(0.1) : AppColors.elevatedSurface,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isCompetition ? AppColors.primaryAccent : AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          isCompetition ? 'Competition' : 'Regular Event',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: isCompetition ? AppColors.primaryAccent : AppColors.primaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: AppColors.muted),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: AppColors.muted),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeDisplay,
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
