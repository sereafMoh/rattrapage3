import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../patient_home.dart';

const String apiBase = "http://192.168.1.35:5000";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class RemindersTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const RemindersTab({required this.user});
  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  final remTitleCtrl = TextEditingController();
  String remType = 'medication';
  String remFreq = 'daily';
  final remTimeCtrl = TextEditingController();
  TimeOfDay? selectedTime;
  List<Map<String, dynamic>> reminders = [];
  bool loadingRems = false;
  int? editingId;

  static const freqOptions = [
    'daily',
    'hourly',
    'every 6 hours',
    'every 8 hours',
    'weekly',
    'monthly',
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    fetchReminders();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> fetchReminders() async {
    setState(() => loadingRems = true);
    try {
      final res = await http.get(
        Uri.parse("$apiBase/reminders/${widget.user['id']}"),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() => reminders = List<Map<String, dynamic>>.from(decoded));
      } else {
        setState(() => reminders = []);
      }
    } catch (e) {
      setState(() => reminders = []);
    }
    setState(() => loadingRems = false);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        remTimeCtrl.text = picked.format(context);
      });
    }
  }

  void addOrUpdateReminder() async {
    if (remTitleCtrl.text.isEmpty || remTimeCtrl.text.isEmpty) return;
    String timeStr = remTimeCtrl.text;

    // Parse time to 24hr
    try {
      final parsed = DateFormat.jm().parse(timeStr);
      timeStr = DateFormat('HH:mm').format(parsed);
    } catch (_) {}

    if (editingId != null) {
      // UPDATE
      await http.put(
        Uri.parse("$apiBase/reminders/$editingId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "title": remTitleCtrl.text,
          "type": remType,
          "time": timeStr,
          "frequency": remFreq,
        }),
      );
      setState(() {
        editingId = null;
      });
    } else {
      // ADD
      await http.post(
        Uri.parse("$apiBase/reminders"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": widget.user['id'],
          "title": remTitleCtrl.text,
          "type": remType,
          "time": timeStr,
          "frequency": remFreq,
        }),
      );
    }

    // Schedule notification
    _scheduleNotification(remTitleCtrl.text, timeStr);

    remTitleCtrl.clear();
    remTimeCtrl.clear();
    setState(() {
      remFreq = 'daily';
      remType = 'medication';
      selectedTime = null;
    });
    await fetchReminders();
  }

  void editReminder(Map<String, dynamic> rem) {
    setState(() {
      remTitleCtrl.text = rem['title'];
      remType = rem['type'];
      remFreq = rem['frequency'];
      remTimeCtrl.text = rem['time'];
      editingId = rem['id'];
      try {
        final timeParts = (rem['time'] as String).split(':');
        if (timeParts.length >= 2) {
          selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (_) {}
    });
  }

  void deleteReminder(int id) async {
    await http.delete(Uri.parse("$apiBase/reminders/$id"));
    await fetchReminders();
  }

  Future<void> _scheduleNotification(String title, String timeStr) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final timeParts = timeStr.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        scheduled.hashCode,
        "Reminder: $title",
        "It's time for your $remType reminder.",
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            importance: Importance.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  @override
  void dispose() {
    remTitleCtrl.dispose();
    remTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PatientHome(user: widget.user),
              ),
            );
          },
        ),
        title: Text('Reminders Tab'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 22,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 700;
                      final inputWidgets = [
                        // Title
                        Expanded(
                          child: TextField(
                            controller: remTitleCtrl,
                            decoration: InputDecoration(
                              labelText: "Title",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isNarrow ? 0 : 8,
                          height: isNarrow ? 10 : 0,
                        ),
                        // Type
                        DropdownButton<String>(
                          value: remType,
                          onChanged: (v) => setState(() => remType = v!),
                          items: [
                            DropdownMenuItem(
                              value: "medication",
                              child: Text("Medication"),
                            ),
                            DropdownMenuItem(
                                value: "meal", child: Text("Meal")),
                            DropdownMenuItem(
                              value: "exercise",
                              child: Text("Exercise"),
                            ),
                            DropdownMenuItem(
                              value: "glucose",
                              child: Text("Glucose"),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: isNarrow ? 0 : 8,
                          height: isNarrow ? 10 : 0,
                        ),
                        // Time (with picker)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: remTimeCtrl,
                                decoration: InputDecoration(
                                  labelText: "Time",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: Icon(Icons.access_time),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isNarrow ? 0 : 8,
                          height: isNarrow ? 10 : 0,
                        ),
                        // Frequency
                        DropdownButton<String>(
                          value: remFreq,
                          onChanged: (v) => setState(() => remFreq = v!),
                          items: freqOptions
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(
                          width: isNarrow ? 0 : 8,
                          height: isNarrow ? 10 : 0,
                        ),
                        // Add/Save Button
                        ElevatedButton.icon(
                          onPressed: addOrUpdateReminder,
                          icon: Icon(Icons.add_alert),
                          label: Text(editingId != null ? "Save" : "Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: StadiumBorder(),
                          ),
                        ),
                      ];
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: inputWidgets
                              .map(
                                (w) => w is SizedBox
                                    ? w
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: w,
                                      ),
                              )
                              .toList(),
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: inputWidgets,
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Divider(height: 1, thickness: 0.7),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.alarm, color: Colors.deepPurple, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Reminders",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              if (loadingRems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 70.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Container(
                  constraints: BoxConstraints(maxHeight: 350),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, thickness: 0.3),
                      itemCount: reminders.length,
                      itemBuilder: (context, i) {
                        final r = reminders[i];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.alarm,
                              color: Colors.deepPurple[300],
                            ),
                            title: Text(
                              "${r['title']} (${r['type']})",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "At ${r['time']}, ${r['frequency']}",
                              style: TextStyle(fontSize: 13),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  tooltip: "Edit",
                                  onPressed: () => editReminder(r),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[300],
                                  ),
                                  tooltip: "Delete",
                                  onPressed: () => deleteReminder(r['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
