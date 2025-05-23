import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../patient_home.dart';

const String apiBase = "http://192.168.1.35:5000";

class GlucoseTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const GlucoseTab({required this.user});

  @override
  State<GlucoseTab> createState() => _GlucoseTabState();
}

class _GlucoseTabState extends State<GlucoseTab> {
  final glucoseCtrl = TextEditingController();
  String glucoseContext = "Fasting";
  List<Map<String, dynamic>> glucoseLogs = [];
  bool loadingGlucose = false;
  int dailyCount = 0;
  int requiredLogs = 0;
  String diabetesType = '';
  String reminder = '';
  String extraInfo = '';
  bool isInsulin = false;

  @override
  void initState() {
    super.initState();
    fetchDiabetesTypeAndMedications();
    fetchGlucose();
    fetchDailyCount();
  }

  @override
  void dispose() {
    glucoseCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchDiabetesTypeAndMedications() async {
    // Get diabetes type
    final profileRes = await http
        .get(Uri.parse("$apiBase/patient_profile/${widget.user['id']}"));
    String foundType = '';
    if (profileRes.statusCode == 200) {
      final profile = jsonDecode(profileRes.body);
      foundType = (profile['diabetes_type'] ?? '').toString();
    }
    // Get medications to check for insulin
    bool insulin = false;
    final medsRes =
        await http.get(Uri.parse("$apiBase/medications/${widget.user['id']}"));
    if (medsRes.statusCode == 200) {
      final meds = List<Map<String, dynamic>>.from(jsonDecode(medsRes.body));
      insulin = meds.any((m) =>
          (m['med_type'] ?? '').toString().toLowerCase().contains('insulin'));
    }
    setState(() {
      diabetesType = foundType;
      isInsulin = insulin;
      requiredLogs = getRequiredLogsPerDay(diabetesType, insulin);
      extraInfo = getDiabetesLogInfo(diabetesType, insulin);
      reminder = getTimeBasedReminderText(diabetesType, insulin);
    });
    fetchDailyCount();
  }

  int getRequiredLogsPerDay(String type, bool insulin) {
    switch (type.toLowerCase()) {
      case 'prediabetes':
        return 0;
      case 'type 1':
        return 6;
      case 'type 2':
        return insulin ? 4 : 2;
      case 'gestational':
        return 4;
      default:
        return 0;
    }
  }

  String getDiabetesLogInfo(String type, bool insulin) {
    switch (type.toLowerCase()) {
      case 'prediabetes':
        return "🔸 Logging is optional, not required.";
      case 'type 1':
        return "🔸 Highly insulin-dependent; requires close monitoring.";
      case 'type 2':
        return insulin
            ? "🔸 Consistent logging to adjust insulin doses."
            : "🔸 For medication or lifestyle management tracking.";
      case 'gestational':
        return "🔸 Important for fetal health; typically non-insulin controlled.";
      default:
        return "";
    }
  }

  String getTimeBasedReminderText(String type, bool insulin) {
    switch (type.toLowerCase()) {
      case 'type 1':
        return "It’s time to log your post-lunch glucose level.";
      case 'type 2':
        return insulin
            ? "It’s time to log your before-bed glucose level."
            : "It’s time to log your 2-hour post-meal glucose level.";
      case 'gestational':
        return "It’s time to log your after-meal glucose level.";
      default:
        return "";
    }
  }

  void fetchGlucose() async {
    setState(() => loadingGlucose = true);
    final res =
        await http.get(Uri.parse("$apiBase/glucose/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          glucoseLogs = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingGlucose = false);
  }

  void fetchDailyCount() async {
    final res = await http
        .get(Uri.parse("$apiBase/glucose/daily_count/${widget.user['id']}"));
    if (res.statusCode == 200) {
      setState(() {
        dailyCount = jsonDecode(res.body)['count'] ?? 0;
      });
    }
  }

  Widget buildPrettyProgressBar(int done, int total) {
    if (total == 0) {
      return SizedBox();
    }
    int filled = done.clamp(0, total);
    int empty = (total - filled).clamp(0, total);
    List<Widget> dots = [];
    for (int i = 0; i < filled; i++) {
      dots.add(Icon(Icons.circle, color: Colors.green[500], size: 18));
    }
    for (int i = 0; i < empty; i++) {
      dots.add(Icon(Icons.circle_outlined, color: Colors.grey[400], size: 18));
    }
    return Row(
      children: [
        Text(
          "Today's logs: ",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.blueGrey[900]),
        ),
        ...dots,
        SizedBox(width: 10),
        Text(
          "($done/$total)",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: done < total ? Colors.orange : Colors.green[700]),
        ),
      ],
    );
  }

  void addGlucose() async {
    final val = double.tryParse(glucoseCtrl.text);
    if (val == null) return;
    final res = await http.post(
      Uri.parse("$apiBase/glucose"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": widget.user['id'],
        "glucose_level": val,
        "context": glucoseContext,
      }),
    );
    glucoseCtrl.clear();
    fetchGlucose();
    fetchDailyCount();
    if (res.statusCode == 200) {
      final resp = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Log recorded: ${resp["category"]}")),
      );
      final String category = resp["category"].toString().toLowerCase();
      if (category.contains("hyper") || category.contains("hypo")) {
        await http.post(
          Uri.parse("$apiBase/messages"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "sender_id": widget.user['id'],
            "receiver_id": resp["doctor_id"],
            "message":
                "ALERT: Patient logged $category (${val} mg/dL, $glucoseContext). Immediate attention may be needed."
          }),
        );
      }
    }
  }

  void deleteGlucose(int id) async {
    await http.delete(Uri.parse("$apiBase/glucose/$id"));
    fetchGlucose();
    fetchDailyCount();
  }

  @override
  Widget build(BuildContext context) {
    final chartLogs = glucoseLogs.take(7).toList().reversed.toList();
    final maxValue = chartLogs.isNotEmpty
        ? chartLogs
            .map((g) => (g['glucose_level'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b)
        : 1.0;
    final minValue = chartLogs.isNotEmpty
        ? chartLogs
            .map((g) => (g['glucose_level'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b)
        : 0.0;

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
        title: Text('Glucose Tab'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: EdgeInsets.all(18),
        children: [
          // Info box about required readings
          Card(
            color: Colors.amber[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 1,
            margin: EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Required Glucose Readings Per Day",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      color: Colors.deepOrange[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  diabetesType.isEmpty
                      ? Text(
                          "Loading diabetes type...",
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diabetesType.toLowerCase() == "type 2"
                                  ? (isInsulin
                                      ? "Type 2 Diabetes (On Insulin)"
                                      : "Type 2 Diabetes (Not on Insulin)")
                                  : diabetesType,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.deepOrange),
                            ),
                            SizedBox(height: 6),
                            if (diabetesType.toLowerCase() == "prediabetes") ...[
                              Text("Fasting: 0"),
                              Text("Not Fasting: 0"),
                              Text("Other: 0"),
                              Text("Total Required Logs per Day: 0"),
                              SizedBox(height: 2),
                            ] else if (diabetesType.toLowerCase() ==
                                "type 1") ...[
                              Text("Fasting: 1 (in the morning)"),
                              Text(
                                  "Not Fasting: 4 (before meals, 2 hours after meals)"),
                              Text("Other: 1 (before bed)"),
                              Text("Total Required Logs per Day: 6"),
                            ] else if (diabetesType.toLowerCase() == "type 2" &&
                                !isInsulin) ...[
                              Text("Fasting: 1 (in the morning)"),
                              Text("Not Fasting: 1 (2 hours after main meal)"),
                              Text("Other: 0"),
                              Text("Total Required Logs per Day: 2"),
                            ] else if (diabetesType.toLowerCase() == "type 2" &&
                                isInsulin) ...[
                              Text("Fasting: 1 (in the morning)"),
                              Text("Not Fasting: 2 (before meals)"),
                              Text("Other: 1 (before bed)"),
                              Text("Total Required Logs per Day: 4"),
                            ] else if (diabetesType.toLowerCase() ==
                                "gestational") ...[
                              Text("Fasting: 1 (in the morning)"),
                              Text("Not Fasting: 3 (after each main meal)"),
                              Text("Other: 0"),
                              Text("Total Required Logs per Day: 4"),
                            ],
                            SizedBox(height: 6),
                            Text(extraInfo,
                                style: TextStyle(
                                    fontSize: 13.2,
                                    color: Colors.deepOrange[800])),
                          ],
                        ),
                ],
              ),
            ),
          ),

          if (requiredLogs > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildPrettyProgressBar(dailyCount, requiredLogs),
            ),

          // Time-based Reminder
          if (reminder.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  reminder,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey[600],
                      fontSize: 15),
                ),
              ),
            ),

          // Input row
          Card(
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: glucoseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Glucose Level",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  DropdownButton<String>(
                    value: glucoseContext,
                    onChanged: (v) => setState(() => glucoseContext = v!),
                    items: [
                      DropdownMenuItem(value: "Fasting", child: Text("Fasting")),
                      DropdownMenuItem(
                          value: "Post-meal", child: Text("Post-meal")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: addGlucose,
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 22),

          if (chartLogs.length > 1)
            Card(
              color: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: ((maxValue - minValue) / 3)
                                .clamp(1, double.infinity),
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                v.toInt().toString(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= chartLogs.length)
                                return Container();
                              final t = chartLogs[idx]['timestamp'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  t.substring(5, 10),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          gradient:
                              LinearGradient(colors: [Colors.red, Colors.orange]),
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: Colors.red,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(colors: [
                              Colors.red.withOpacity(0.2),
                              Colors.orange.withOpacity(0.02)
                            ]),
                          ),
                        ),
                      ],
                      minY: (minValue - 10).clamp(0, double.infinity),
                      maxY: maxValue + 10,
                    ),
                  ),
                ),
              ),
            ),

          SizedBox(height: 22),

          // Logs Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Glucose Logs:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                  fontSize: 18),
            ),
          ),

          SizedBox(height: 8),

          // Glucose Logs List - Now scrollable with fixed height!
          if (loadingGlucose)
            Center(child: CircularProgressIndicator())
          else
            Container(
              height: 350, // Set a fixed height for scrollable logs list
              child: Scrollbar(
                child: ListView.separated(
                  itemCount: glucoseLogs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.4),
                  itemBuilder: (context, i) {
                    final g = glucoseLogs[i];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      child: ListTile(
                        leading: Icon(Icons.bloodtype, color: Colors.red[400]),
                        title: Text(
                          "Level: ${g['glucose_level']} (${g['context']})",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text("${g['timestamp']} — ${g['category']}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[300]),
                          tooltip: "Delete Log",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Delete Glucose Log"),
                                content: Text(
                                    "Are you sure you want to delete this glucose log?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text("Cancel")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) deleteGlucose(g['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}