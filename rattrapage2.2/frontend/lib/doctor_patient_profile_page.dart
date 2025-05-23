import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

const String apiBase = "http://192.168.1.35:5000";

class DoctorPatientProfilePage extends StatefulWidget {
  final int doctorId;
  final int patientId;
  const DoctorPatientProfilePage({
    required this.doctorId,
    required this.patientId,
  });
  @override
  State<DoctorPatientProfilePage> createState() =>
      _DoctorPatientProfilePageState();
}

class _DoctorPatientProfilePageState extends State<DoctorPatientProfilePage> {
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> meds = [];
  List<Map<String, dynamic>> glucoseLogs = [];
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> logs = [];

  bool loading = true;
  int? homeCardIndex;

  final newDoseCtrl = TextEditingController();
  String? medToEdit;

  // Controllers for new medication form
  final newMedNameCtrl = TextEditingController();
  final newMedDoseCtrl = TextEditingController();
  String newMedType = "Oral"; // Default value

  final List<Color> pastelColors = [
    Color(0xFFFFF1E6), // soft orange
    Color(0xFFE8F6EF), // very soft teal
    Color(0xFFFFF9E5), // pastel yellow
    Color(0xFFE6F0FF), // pastel blue
    Color(0xFFEDE7F6), // pastel lavender
  ];

  final List<Color> pastelTextColors = [
    Color(0xFFE1701A), // darker orange
    Color(0xFF009688), // teal
    Color(0xFFE6B800), // dark yellow
    Color(0xFF1976D2), // blue
    Color(0xFF7C5CCC), // soft lavender text
  ];

  final Color lightBeige = Color(0xFFFFFBF7);
  final Color pastelLavenderBar = Color(0xFFD6C9F7);

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  void dispose() {
    newDoseCtrl.dispose();
    newMedNameCtrl.dispose();
    newMedDoseCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    final pRes = await http.get(
      Uri.parse("$apiBase/patient_profile/${widget.patientId}"),
    );
    final mRes = await http.get(
      Uri.parse("$apiBase/medications/${widget.patientId}"),
    );
    final gRes = await http.get(
      Uri.parse("$apiBase/glucose/${widget.patientId}"),
    );
    final mealRes = await http.get(
      Uri.parse("$apiBase/meals/${widget.patientId}"),
    );
    final actRes = await http.get(
      Uri.parse("$apiBase/activities/${widget.patientId}"),
    );
    final appRes = await http.get(
      Uri.parse("$apiBase/appointments/patient/${widget.patientId}"),
    );
    setState(() {
      profile = pRes.statusCode == 200 ? jsonDecode(pRes.body) : null;
      meds = mRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(mRes.body))
          : [];
      glucoseLogs = gRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(gRes.body))
          : [];
      meals = mealRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(mealRes.body))
          : [];
      activities = actRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(actRes.body))
          : [];
      appointments = appRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(appRes.body))
          : [];
      logs = [
        ...glucoseLogs
            .take(2)
            .map((g) => {"type": "Glucose", "log": g, "time": g['timestamp']}),
        ...meals
            .take(2)
            .map((m) => {"type": "Meal", "log": m, "time": m['timestamp']}),
        ...activities
            .take(2)
            .map((a) => {"type": "Activity", "log": a, "time": a['timestamp']}),
      ];
      logs.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
      loading = false;
    });
  }

  void updateMedication(String medId) async {
    if (newDoseCtrl.text.isEmpty) return;
    await http.put(
      Uri.parse("$apiBase/medications/$medId"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "doctor_id": widget.doctorId,
        "dosage": newDoseCtrl.text,
      }),
    );
    newDoseCtrl.clear();
    setState(() => medToEdit = null);
    fetchAll();
  }

  void addNewMedication() async {
    if (newMedNameCtrl.text.isEmpty || newMedDoseCtrl.text.isEmpty) return;
    await http.post(
      Uri.parse("$apiBase/medications"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patient_id": widget.patientId,
        "doctor_id": widget.doctorId,
        "med_name": newMedNameCtrl.text,
        "dosage": newMedDoseCtrl.text,
        "med_type": newMedType,
        "added_by_patient": 0,
      }),
    );
    newMedNameCtrl.clear();
    newMedDoseCtrl.clear();
    setState(() {}); // closes the modal if used with showModalBottomSheet
    fetchAll();
  }

  Widget buildHomeCard(
    int idx,
    IconData icon,
    String title,
    String desc,
  ) {
    return InkWell(
      onTap: () => setState(() => homeCardIndex = idx),
      borderRadius: BorderRadius.circular(24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 1,
        color: pastelColors[idx % pastelColors.length],
        child: Container(
          height: 140,
          width: 210,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    pastelColors[idx % pastelColors.length].withOpacity(0.8),
                child: Icon(icon,
                    color: pastelTextColors[idx % pastelTextColors.length],
                    size: 32),
              ),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: pastelTextColors[idx % pastelTextColors.length],
                ),
              ),
              SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: pastelTextColors[idx % pastelTextColors.length]
                        .withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: lightBeige,
        appBar: AppBar(
          backgroundColor: pastelLavenderBar,
          foregroundColor: Colors.white,
          elevation: 0.5,
          title: Text("Patient"),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (homeCardIndex == null) {
      return Scaffold(
        backgroundColor: lightBeige,
        appBar: AppBar(
          backgroundColor: pastelLavenderBar,
          foregroundColor: Colors.white,
          elevation: 0.5,
          title: Text(profile?['name'] ?? "Patient"),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: pastelColors[4].withOpacity(0.8),
                  child: Icon(
                    Icons.person,
                    size: 52,
                    color: pastelTextColors[4],
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  profile?['name'] ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 27,
                    color: pastelTextColors[4],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${profile?['email'] ?? ""}  ·  ${profile?['city'] ?? ""}",
                  style: TextStyle(
                    color: pastelTextColors[4].withOpacity(0.45),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 28),
                // Just one container for the cards!
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    buildHomeCard(
                      0,
                      Icons.info_outline,
                      "Profile",
                      "View patient's full profile details.",
                    ),
                    buildHomeCard(
                      1,
                      Icons.medical_services,
                      "Manage Medications",
                      "View, edit, remove or prescribe medications.",
                    ),
                    buildHomeCard(
                      2,
                      Icons.list_alt,
                      "Recent Logs",
                      "See the last 6 logs (glucose, meals, activity).",
                    ),
                    buildHomeCard(
                      3,
                      Icons.show_chart,
                      "Charts",
                      "Visualize glucose, meals, and activity data.",
                    ),
                    buildHomeCard(
                      4,
                      Icons.date_range,
                      "Appointments",
                      "See upcoming appointments.",
                    ),
                  ],
                ),
                SizedBox(height: 36),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        backgroundColor: pastelLavenderBar,
        foregroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          [
            "Profile",
            "Medications",
            "Logs",
            "Charts",
            "Appointments",
          ][homeCardIndex!],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => homeCardIndex = null),
        ),
      ),
      body: [
        _buildProfileCard(),
        _buildMedicationsCard(),
        _buildLogsCard(),
        _buildChartsCard(),
        _buildAppointmentsCard(),
      ][homeCardIndex!],
    );
  }

  Widget _buildProfileCard() {
    if (profile == null) return Center(child: Text("No profile data"));
    return SingleChildScrollView(
      padding: EdgeInsets.all(22),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: pastelColors[0],
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: pastelColors[0].withOpacity(0.7),
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: pastelTextColors[0],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  profile?['name'] ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                    color: pastelTextColors[0],
                  ),
                ),
              ),
              SizedBox(height: 18),
              _profileRow("Email", profile?['email']),
              _profileRow("Phone", profile?['phone']),
              _profileRow("DOB", profile?['dob']),
              _profileRow("Gender", profile?['gender']),
              _profileRow("City", profile?['city']),
              _profileRow("Country", profile?['country']),
              _profileRow("Diabetes Type", profile?['diabetes_type']),
              _profileRow("Weight (kg)", profile?['weight']),
              _profileRow("Health Background", profile?['health_background']),
              _profileRow("Emergency Contact", profile?['emergency_contact']),
              _profileRow("Emergency Phone", profile?['emergency_phone']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 142,
              child: Text(
                "$label:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: pastelTextColors[0].withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value == null || value.toString().isEmpty
                    ? "-"
                    : value.toString(),
                style: TextStyle(
                  color: pastelTextColors[0].withOpacity(0.96),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMedicationsCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Prescribe New Medication"),
              style: ElevatedButton.styleFrom(
                backgroundColor: pastelTextColors[1],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text("Prescribe New Medication"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: newMedNameCtrl,
                          decoration:
                              InputDecoration(labelText: "Medication Name"),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: newMedDoseCtrl,
                          decoration: InputDecoration(labelText: "Dosage"),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: newMedType,
                          decoration: InputDecoration(labelText: "Type"),
                          items: [
                            DropdownMenuItem(
                                value: "Oral", child: Text("Oral")),
                            DropdownMenuItem(
                                value: "Insulin", child: Text("Insulin")),
                            DropdownMenuItem(
                                value: "Injection", child: Text("Injection")),
                            DropdownMenuItem(
                                value: "Other", child: Text("Other")),
                          ],
                          onChanged: (v) {
                            setState(() {
                              newMedType = v!;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text("Cancel"),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pastelTextColors[1],
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Add"),
                        onPressed: () {
                          Navigator.pop(ctx);
                          addNewMedication();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          ...meds.isEmpty
              ? [
                  Center(
                    child: Text(
                      "No medications.",
                      style:
                          TextStyle(color: pastelTextColors[1], fontSize: 16),
                    ),
                  ),
                ]
              : meds.map(
                  (m) => Card(
                    elevation: 2,
                    color: pastelColors[1],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        "${m['med_name']} (${m['med_type']})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pastelTextColors[1],
                        ),
                      ),
                      subtitle: Text(
                        "Dosage: ${m['dosage']}",
                        style: TextStyle(
                          fontSize: 15,
                          color: pastelTextColors[1].withOpacity(0.8),
                        ),
                      ),
                      trailing: medToEdit == m['id'].toString()
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 70,
                                  child: TextField(
                                    controller: newDoseCtrl,
                                    decoration: InputDecoration(
                                      hintText: "New dosage",
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () =>
                                      updateMedication(m['id'].toString()),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: pastelTextColors[1],
                                  ),
                                  onPressed: () =>
                                      setState(() => medToEdit = null),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: pastelTextColors[1].withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    newDoseCtrl.text = m['dosage'] ?? '';
                                    setState(
                                        () => medToEdit = m['id'].toString());
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: pastelTextColors[1],
                                  ),
                                  onPressed: () async {
                                    await http.delete(
                                      Uri.parse(
                                        "$apiBase/medications/${m['id']}",
                                      ),
                                    );
                                    fetchAll();
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLogsCard() {
    if (logs.isEmpty) return Center(child: Text("No recent logs."));
    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: logs.length.clamp(0, 6),
      itemBuilder: (context, idx) {
        final l = logs[idx];
        final type = l['type'];
        final data = l['log'];
        final colorIdx = type == "Glucose"
            ? 0
            : type == "Meal"
                ? 2
                : 3;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: pastelColors[colorIdx],
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              type == "Glucose"
                  ? Icons.bloodtype
                  : type == "Meal"
                      ? Icons.restaurant
                      : Icons.directions_run,
              color: pastelTextColors[colorIdx],
              size: 32,
            ),
            title: Text(
              type == "Glucose"
                  ? "Glucose: ${data['glucose_level']} (${data['context']})"
                  : type == "Meal"
                      ? "${data['description']} (${data['meal_type']})"
                      : "${data['activity_type']} (${data['duration_minutes']} min)",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: pastelTextColors[colorIdx],
              ),
            ),
            subtitle: Text(
              type == "Glucose"
                  ? "${data['timestamp']} — ${data['category']}"
                  : type == "Meal"
                      ? "${data['timestamp']}, ${data['calories']} cal, ${data['carbs']}g carbs"
                      : "${data['timestamp']} | Calories: ${data['calories_burned'] ?? '-'}",
              style: TextStyle(
                  fontSize: 13,
                  color: pastelTextColors[colorIdx].withOpacity(0.75)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsCard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Glucose Chart",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: pastelTextColors[0],
            ),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            height: 220,
            child: _buildGlucoseChart(glucoseLogs),
          ),
          SizedBox(height: 22),
          Text(
            "Meal Calories Chart",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: pastelTextColors[2],
            ),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            height: 220,
            child: _buildMealChart(meals),
          ),
          SizedBox(height: 22),
          Text(
            "Activity Calories Chart",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: pastelTextColors[3],
            ),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            height: 220,
            child: _buildActivityChart(activities),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsCard() {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          "No appointments scheduled.",
          style: TextStyle(color: pastelTextColors[4], fontSize: 17),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.all(24),
      children: appointments.map((a) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: pastelColors[4],
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(Icons.event, color: pastelTextColors[4], size: 32),
            title: Text(
              "With Dr. ${a['doctor_name']} on ${a['appointment_time'].replaceAll('T', ' ').substring(0, 16)}",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: pastelTextColors[4]),
            ),
            subtitle: Text(
              "Status: ${a['status']}\n${a['notes'] ?? ''}",
              style: TextStyle(
                  fontSize: 13, color: pastelTextColors[4].withOpacity(0.75)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlucoseChart(List<Map<String, dynamic>> logs) {
    if (logs.length < 2) return Center(child: Text("Not enough data"));
    final chartLogs = logs.take(7).toList().reversed.toList();
    final maxValue = chartLogs
        .map((g) => (g['glucose_level'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final minValue = chartLogs
        .map((g) => (g['glucose_level'] as num).toDouble())
        .reduce((a, b) => a < b ? a : b);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                ((maxValue - minValue) / 4).clamp(1, double.infinity)),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= chartLogs.length) return Container();
                final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                    style: TextStyle(fontSize: 12, color: pastelTextColors[0]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: ((maxValue - minValue) / 4).clamp(1, double.infinity),
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(v.toInt().toString(),
                    style: TextStyle(fontSize: 12, color: pastelTextColors[0])),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chartLogs.length,
              (i) => FlSpot(
                i.toDouble(),
                (chartLogs[i]['glucose_level'] as num).toDouble(),
              ),
            ),
            isCurved: true,
            color: pastelTextColors[0],
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  pastelColors[0].withOpacity(0.25),
                  pastelColors[0].withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
        minY: (minValue - 10).clamp(0, double.infinity),
        maxY: maxValue + 10,
      ),
    );
  }

  Widget _buildMealChart(List<Map<String, dynamic>> logs) {
    if (logs.length < 2) return Center(child: Text("Not enough data"));
    final chartLogs = logs.take(7).toList().reversed.toList();
    final maxVal = chartLogs
        .map((m) => (m['calories'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxVal / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: pastelColors[2].withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= chartLogs.length) return Container();
                final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                    style: TextStyle(fontSize: 11, color: pastelTextColors[2]),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: (maxVal / 4).clamp(1, double.infinity),
                getTitlesWidget: (v, meta) => Text(
                      v.toInt().toString(),
                      style:
                          TextStyle(fontSize: 11, color: pastelTextColors[2]),
                    )),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 0,
        maxY: maxVal + 50,
        barGroups: List.generate(
          chartLogs.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (chartLogs[i]['calories'] as num?)?.toDouble() ?? 0,
                color: pastelTextColors[2],
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart(List<Map<String, dynamic>> logs) {
    if (logs.length < 2) return Center(child: Text("Not enough data"));
    final chartLogs = logs.take(7).toList().reversed.toList();
    final maxVal = chartLogs
        .map((a) => (a['calories_burned'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxVal / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: pastelColors[3].withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: (maxVal / 4).clamp(1, double.infinity),
                getTitlesWidget: (v, meta) => Text(
                      v.toInt().toString(),
                      style:
                          TextStyle(fontSize: 11, color: pastelTextColors[3]),
                    )),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= chartLogs.length) return Container();
                final t = chartLogs[idx]['timestamp']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    t.length > 10 ? t.substring(5, 10) : (t.isEmpty ? '-' : t),
                    style: TextStyle(fontSize: 11, color: pastelTextColors[3]),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 0,
        maxY: maxVal + 50,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chartLogs.length,
              (i) => FlSpot(
                i.toDouble(),
                (chartLogs[i]['calories_burned'] as num?)?.toDouble() ?? 0,
              ),
            ),
            isCurved: true,
            color: pastelTextColors[3],
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  pastelColors[3].withOpacity(0.25),
                  pastelColors[3].withOpacity(0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
