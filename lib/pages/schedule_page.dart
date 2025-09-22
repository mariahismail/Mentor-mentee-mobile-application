import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SchedulePage extends StatefulWidget {
  final bool isMentor;
  final String currentUserEmail;

  const SchedulePage({
    Key? key,
    required this.isMentor,
    required this.currentUserEmail,
  }) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _userSchedule = {};

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // fallback to UTC if timezone not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _initializeNotifications();
    _loadUserEvents();
  }

  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(String title, DateTime scheduledDateTime) async {
    final androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Event Notifications',
      channelDescription: 'Notifications for upcoming scheduled events.',
      importance: Importance.max,
      priority: Priority.high,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final tz.TZDateTime notificationTime = scheduledTZDate.subtract(const Duration(minutes: 10));

    if (notificationTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notificationsPlugin.zonedSchedule(
        scheduledDateTime.hashCode,
        'Upcoming Event',
        title,
        notificationTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  Future<void> _loadUserEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserEmail)
        .collection('events')
        .where('role', isEqualTo: widget.isMentor ? 'mentor' : 'mentee')
        .get();

    final Map<DateTime, List<Map<String, dynamic>>> schedule = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] != null && data['event'] != null) {
        final date = (data['date'] as Timestamp).toDate();
        final key = DateTime.utc(date.year, date.month, date.day);
        final time = data['time'] ?? '';
        schedule.putIfAbsent(key, () => []).add({
          'event': data['event'],
          'time': time,
        });

        // Schedule notification for this event
        final eventDateTime = _combineDateAndTime(date, time);
        if (eventDateTime != null) {
          _scheduleNotification('${data['event']} at $time', eventDateTime);
        }
      }
    }

    setState(() {
      _userSchedule = schedule;
    });
  }

  DateTime? _combineDateAndTime(DateTime date, String timeStr) {
    try {
      final timeParts = timeStr.split(RegExp(r'[: ]'));
      if (timeParts.length < 2) return null;
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final isPM = timeStr.toLowerCase().contains('pm');
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime.utc(day.year, day.month, day.day);
    return _userSchedule[dateKey] ?? [];
  }

  List<Map<String, dynamic>> _getEventsForMonth(DateTime month) {
    final now = DateTime.now();
    return _userSchedule.entries
        .where((entry) =>
    entry.key.year == month.year &&
        entry.key.month == month.month &&
        entry.key.isAfter(DateTime(now.year, now.month, now.day)))
        .expand((e) => e.value)
        .toList();
  }

  Future<void> _addEvent(String event, String time) async {
    if (_selectedDay == null) return;
    final dateKey = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserEmail)
        .collection('events')
        .add({
      'date': Timestamp.fromDate(_selectedDay!),
      'event': event,
      'time': time,
      'role': widget.isMentor ? 'mentor' : 'mentee',
    });

    if (_userSchedule.containsKey(dateKey)) {
      _userSchedule[dateKey]!.add({'event': event, 'time': time});
    } else {
      _userSchedule[dateKey] = [{'event': event, 'time': time}];
    }

    // Schedule notification for new event
    final eventDateTime = _combineDateAndTime(_selectedDay!, time);
    if (eventDateTime != null) {
      _scheduleNotification('$event at $time', eventDateTime);
    }

    setState(() {});
  }

  Future<void> _deleteEvent(Map<String, dynamic> eventData) async {
    if (_selectedDay == null) return;
    final dateKey = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${eventData['event']} at ${eventData['time']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserEmail)
        .collection('events')
        .where('event', isEqualTo: eventData['event'])
        .where('date', isEqualTo: Timestamp.fromDate(_selectedDay!))
        .where('time', isEqualTo: eventData['time'])
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    _userSchedule[dateKey]?.removeWhere(
            (e) => e['event'] == eventData['event'] && e['time'] == eventData['time']);
    if (_userSchedule[dateKey]?.isEmpty ?? false) {
      _userSchedule.remove(dateKey);
    }

    setState(() {});
  }

  Future<void> _editEvent(Map<String, dynamic> oldData) async {
    final eventController = TextEditingController(text: oldData['event']);
    TimeOfDay selectedTime = _parseTimeOfDay(oldData['time']);
    if (_selectedDay == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eventController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Event name'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final picked =
                await showTimePicker(context: context, initialTime: selectedTime);
                if (picked != null) {
                  selectedTime = picked;
                }
              },
              child: const Text("Pick Time"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newEvent = eventController.text.trim();
              if (newEvent.isEmpty) return;
              final newTime = selectedTime.format(context);
              Navigator.pop(context);

              final dateKey =
              DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

              final snapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserEmail)
                  .collection('events')
                  .where('event', isEqualTo: oldData['event'])
                  .where('date', isEqualTo: Timestamp.fromDate(_selectedDay!))
                  .where('time', isEqualTo: oldData['time'])
                  .get();

              for (var doc in snapshot.docs) {
                await doc.reference.update({'event': newEvent, 'time': newTime});
              }

              _userSchedule[dateKey]?.removeWhere(
                      (e) => e['event'] == oldData['event'] && e['time'] == oldData['time']);
              _userSchedule[dateKey]?.add({'event': newEvent, 'time': newTime});
              setState(() {});

              final eventDateTime = _combineDateAndTime(_selectedDay!, newTime);
              if (eventDateTime != null) {
                _scheduleNotification('$newEvent at $newTime', eventDateTime);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final format = TimeOfDayFormat.h_colon_mm_space_a;
      final time = TimeOfDay.fromDateTime(DateTime.parse("2000-01-01 " + _convertTo24h(timeStr)));
      return time;
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  // Convert 'hh:mm am/pm' to 'HH:mm:ss'
  String _convertTo24h(String timeStr) {
    final time = timeStr.toLowerCase().replaceAll(' ', '');
    final regex = RegExp(r'(\d{1,2}):(\d{2})(am|pm)');
    final match = regex.firstMatch(time);
    if (match == null) return '00:00:00';

    int hour = int.parse(match.group(1)!);
    final min = match.group(2)!;
    final ampm = match.group(3)!;

    if (ampm == 'pm' && hour != 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:$min:00';
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMentor ? 'Mentor Schedule' : 'Mentee Schedule'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: eventsForSelectedDay.isEmpty
                ? const Center(child: Text('No events for this day.'))
                : ListView.builder(
              itemCount: eventsForSelectedDay.length,
              itemBuilder: (context, index) {
                final event = eventsForSelectedDay[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(event['event'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(event['time']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _editEvent(event),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteEvent(event),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              onPressed: () async {
                final eventController = TextEditingController();
                TimeOfDay selectedTime = TimeOfDay.now();

                if (_selectedDay == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a day first')));
                  return;
                }

                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add New Event'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: eventController,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Event name'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final picked =
                            await showTimePicker(context: context, initialTime: selectedTime);
                            if (picked != null) {
                              selectedTime = picked;
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          if (eventController.text.trim().isEmpty) return;
                          final formattedTime = selectedTime.format(context);
                          _addEvent(eventController.text.trim(), formattedTime);
                          Navigator.pop(context);
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
