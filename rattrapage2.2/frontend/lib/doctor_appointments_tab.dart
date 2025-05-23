import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String apiBase = "http://192.168.1.35:5000";

DateTime? parseDate(dynamic input) {
  if (input == null) return null;
  if (input is DateTime) return input;
  try {
    return DateTime.parse(input);
  } catch (_) {
    return null;
  }
}

class DoctorAppointmentsTab extends StatefulWidget {
  final int doctorId;
  const DoctorAppointmentsTab({required this.doctorId, Key? key})
      : super(key: key);

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> {
  bool loadingAppointments = false, loadingPatients = false;
  List<Map<String, dynamic>> appointments = [], patients = [];

  Map<String, dynamic>? selectedPatient;
  DateTime? selectedDateTime;
  final notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_fetchPatients(), _fetchAppointments()]);
  }

  Future<void> _fetchPatients() async {
    setState(() => loadingPatients = true);
    final res =
        await http.get(Uri.parse("$apiBase/patients/${widget.doctorId}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      patients = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    setState(() => loadingPatients = false);
  }

  Future<void> _fetchAppointments() async {
    setState(() => loadingAppointments = true);
    final res =
        await http.get(Uri.parse("$apiBase/appointments/${widget.doctorId}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      // Fix: Ensure patient_name and status are present
      appointments = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    setState(() => loadingAppointments = false);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _schedule() async {
    if (selectedPatient == null || selectedDateTime == null) return;
    await http.post(
      Uri.parse("$apiBase/appointments"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctor_id': widget.doctorId,
        'patient_id': selectedPatient!['id'],
        'appointment_time': selectedDateTime!.toIso8601String(),
        'notes': notesCtrl.text,
      }),
    );
    notesCtrl.clear();
    selectedPatient = null;
    selectedDateTime = null;
    await _fetchAppointments();
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    await http.delete(Uri.parse("$apiBase/appointments/$appointmentId"));
    await _fetchAppointments();
  }

  Future<void> _rescheduleAppointment(
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
    await _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.deepPurple[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Schedule form ---
              Text(
                'Schedule Appointment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (loadingPatients)
                        Center(child: CircularProgressIndicator())
                      else ...[
                        _buildPatientDropdown(),
                        const SizedBox(height: 12),
                        _buildDateField(),
                        const SizedBox(height: 12),
                        _buildNotesField(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _schedule,
                            icon: Icon(Icons.add),
                            label: Text('Schedule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // --- Appointments list ---
              Text(
                'Ongoing Appointments',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                ),
              ),
              const SizedBox(height: 12),

              if (loadingAppointments)
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, i) {
                    final a = appointments[i];
                    final dt = parseDate(a['appointment_time']);
                    final display = dt != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal())
                        : a['appointment_time'] ?? '';
                    return _AppointmentCard(
                      patientName: a['patient_name'] ?? "Patient",
                      dateTime: display,
                      status: a['status'],
                      notes: a['notes'] ?? '',
                      onCancel: () => _cancelAppointment(a['id']),
                      onReschedule: () => _rescheduleAppointment(
                        a['id'],
                        dt ?? DateTime.now(),
                        a['notes'] ?? '',
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

  Widget _buildPatientDropdown() =>
      DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedPatient,
        hint: Text('Select Patient'),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        items: patients
            .map((p) => DropdownMenuItem(value: p, child: Text(p['name'])))
            .toList(),
        onChanged: (v) => setState(() => selectedPatient = v),
      );

  Widget _buildDateField() => TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: selectedDateTime == null
              ? ''
              : DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!),
        ),
        onTap: _pickDateTime,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
          hintText: 'Pick Date & Time',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );

  Widget _buildNotesField() => TextField(
        controller: notesCtrl,
        maxLines: 2,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.note, color: Colors.deepPurple),
          labelText: 'Notes',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  final String patientName;
  final String dateTime;
  final String status;
  final String notes;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  const _AppointmentCard({
    required this.patientName,
    required this.dateTime,
    required this.status,
    required this.notes,
    required this.onCancel,
    required this.onReschedule,
    Key? key,
  }) : super(key: key);

  Color getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: Icon(Icons.event, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateTime,
              style: TextStyle(color: Colors.deepPurple[400]),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: $status',
              style: TextStyle(fontSize: 14, color: getStatusColor(status)),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onReschedule,
                  icon: Icon(Icons.edit_calendar, size: 18),
                  label: Text('Reschedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    minimumSize: Size(100, 36),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onCancel,
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
  }
}
