import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../patient_home.dart';

const String apiBase = "http://192.168.100.53:5000";

class PatientAppointmentsTab extends StatefulWidget {
  final int patientId;
  const PatientAppointmentsTab({required this.patientId, Key? key})
      : super(key: key);

  @override
  State<PatientAppointmentsTab> createState() => _PatientAppointmentsTabState();
}

class _PatientAppointmentsTabState extends State<PatientAppointmentsTab> {
  bool loading = false;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() => loading = true);
    final res = await http
        .get(Uri.parse("$apiBase/appointments/patient/${widget.patientId}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      appointments = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    setState(() => loading = false);
  }

  Future<void> cancelAppointment(int appointmentId) async {
    await http.delete(Uri.parse("$apiBase/appointments/$appointmentId"));
    await fetchAppointments();
  }

  Future<void> rescheduleAppointment(
      int appointmentId, DateTime currentDate, String currentNotes) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (newDate == null) return;
    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: currentDate.hour, minute: currentDate.minute),
    );
    if (newTime == null) return;
    final newDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );
    await http.put(
      Uri.parse("$apiBase/appointments/$appointmentId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'appointment_time': newDateTime.toIso8601String(),
        'notes': currentNotes,
        'status': 'rescheduled',
      }),
    );
    await fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PatientHome(user: {'id': widget.patientId}),
              ),
            );
          },
        ),
        title: Text('My Appointments'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchAppointments,
          child: ListView(
            padding: EdgeInsets.all(18),
            children: [
              SizedBox(height: 2),
              if (loading)
                Center(child: CircularProgressIndicator())
              else if (appointments.isEmpty)
                Center(
                  child: Text(
                    'No appointments scheduled.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple[300],
                    ),
                  ),
                )
              else
                ...appointments.map((a) {
                  final dt =
                      DateTime.tryParse(a['appointment_time'] ?? "")?.toLocal();
                  final display = dt != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(dt)
                      : a['appointment_time'] ?? '';
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.deepPurple[100],
                                child:
                                    Icon(Icons.event, color: Colors.deepPurple),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  a['doctor_name'] ?? 'Doctor',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(display,
                              style: TextStyle(color: Colors.deepPurple[400])),
                          SizedBox(height: 4),
                          Text('Status: ${a['status']}',
                              style: TextStyle(fontSize: 14)),
                          if ((a['notes'] ?? '').isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(a['notes'],
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87)),
                          ],
                          SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => rescheduleAppointment(
                                  a['id'],
                                  dt ?? DateTime.now(),
                                  a['notes'] ?? '',
                                ),
                                icon: Icon(Icons.edit_calendar, size: 18),
                                label: Text('Reschedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[400],
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(100, 36),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () => cancelAppointment(a['id']),
                                icon: Icon(Icons.cancel, size: 18),
                                label: Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(90, 36),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                })
            ],
          ),
        ),
      ),
    );
  }
}
