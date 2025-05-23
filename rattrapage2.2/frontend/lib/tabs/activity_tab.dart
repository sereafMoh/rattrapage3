import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../patient_home.dart';

class PhysicalActivityTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const PhysicalActivityTab({required this.user});
  @override
  State<PhysicalActivityTab> createState() => _PhysicalActivityTabState();
}

class _PhysicalActivityTabState extends State<PhysicalActivityTab> {
  List<Map<String, dynamic>> presetActivities = [];
  List<Map<String, dynamic>> activities = [];
  bool loading = false;

  String? selectedActivity;
  int? selectedCaloriesPerMin;
  final durationCtrl = TextEditingController();
  final caloriesCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchActivities();
    loadPresetActivities();
    durationCtrl.addListener(_autoCalculateCalories);
  }

  Future<void> loadPresetActivities() async {
    final data = await rootBundle.loadString('assets/physical_activities.json');
    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      presetActivities = decoded.cast<Map<String, dynamic>>();
    });
  }

  void fetchActivities() async {
    setState(() => loading = true);
    final res =
        await http.get(Uri.parse("$apiBase/activities/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          activities = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loading = false);
  }

  void addActivity() async {
    final activity = selectedActivity ?? notesCtrl.text;
    final duration = int.tryParse(durationCtrl.text) ?? 0;
    int? calories = int.tryParse(caloriesCtrl.text);
    if (activity.isEmpty || duration == 0) return;

    if ((calories == null || calories == 0) && selectedCaloriesPerMin != null) {
      calories = duration * selectedCaloriesPerMin!;
    }
    await http.post(
      Uri.parse("$apiBase/activities"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": widget.user['id'],
        "activity_type": activity,
        "duration_minutes": duration,
        "calories_burned": calories,
        "notes": notesCtrl.text
      }),
    );
    setState(() {
      selectedActivity = null;
      selectedCaloriesPerMin = null;
    });
    durationCtrl.clear();
    caloriesCtrl.clear();
    notesCtrl.clear();
    fetchActivities();
  }

  void deleteActivity(int id) async {
    await http.delete(Uri.parse("$apiBase/activities/$id"));
    fetchActivities();
  }

  void _autoCalculateCalories() {
    final duration = int.tryParse(durationCtrl.text) ?? 0;
    if (selectedCaloriesPerMin != null && duration > 0) {
      final calc = duration * selectedCaloriesPerMin!;
      caloriesCtrl.text = calc.toString();
    }
  }

  @override
  void dispose() {
    durationCtrl.removeListener(_autoCalculateCalories);
    durationCtrl.dispose();
    caloriesCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartLogs = activities.isNotEmpty
        ? activities.take(7).toList().reversed.toList()
        : [];

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
        title: Text('Physical Activity Tab'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(12), // Reduced padding to maximize space
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Input Widget (First)
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0), // Slightly reduced padding
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedActivity,
                            hint: Text("Preset Activity"),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: presetActivities
                                .map<
                                    DropdownMenuItem<
                                        String>>((a) => DropdownMenuItem<String>(
                                    value: a['type'] as String,
                                    child: Text(
                                        "${a['type']} (${a['calories_per_min']} cal/min)")))
                                .toList(),
                            onChanged: (v) {
                              final activity = presetActivities
                                  .firstWhere((a) => a['type'] == v);
                              setState(() {
                                selectedActivity = v;
                                selectedCaloriesPerMin =
                                    activity['calories_per_min'] as int;
                                notesCtrl.text = "";
                              });
                              _autoCalculateCalories();
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Text("or"),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              labelText: "Other Activity",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v.isNotEmpty) {
                                  selectedActivity = null;
                                  selectedCaloriesPerMin = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Reduced spacing
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Minutes",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 8), // Reduced spacing
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: caloriesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Calories (auto)",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            enabled: selectedCaloriesPerMin == null,
                          ),
                        ),
                        SizedBox(width: 8), // Reduced spacing
                        ElevatedButton.icon(
                          onPressed: addActivity,
                          icon: Icon(Icons.add_circle),
                          label: Text("Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12), // Reduced spacing
            // Chart Widget (Second)
            if (chartLogs.length > 1) ...[
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 14.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Calories Burned (last 7 activities)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                              fontSize: 16)),
                      SizedBox(
                        height: 180, // Slightly reduced chart height
                        child: LineChart(
                          LineChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                                show: true,
                                horizontalInterval: 50,
                                getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[300]!, strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true, reservedSize: 38),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= chartLogs.length)
                                      return Container();
                                    final t = chartLogs[idx]['timestamp'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        t.length > 10 ? t.substring(5, 10) : t,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                  interval: 1,
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            minY: 0,
                            maxY: chartLogs
                                    .map((a) =>
                                        (a['calories_burned'] as num?)
                                            ?.toDouble() ??
                                        0)
                                    .fold<double>(0,
                                        (prev, el) => el > prev ? el : prev) +
                                50,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  chartLogs.length,
                                  (i) => FlSpot(
                                      i.toDouble(),
                                      (chartLogs[i]['calories_burned'] as num?)
                                              ?.toDouble() ??
                                          0),
                                ),
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 4,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.withOpacity(0.3),
                                      Colors.teal.withOpacity(0.05)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12), // Reduced spacing
            ],
            // Activity Log (Third)
            Divider(height: 1, thickness: 0.7),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_run,
                    color: Colors.teal, size: 20), // Smaller icon
                SizedBox(width: 6), // Reduced spacing
                Text("Activity Log",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Smaller font
                        color: Colors.teal[900])),
              ],
            ),
            SizedBox(height: 4),
            if (loading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                flex: 2, // Increased flex to give more space to logs
                child: ListView.separated(
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 0.3),
                  itemCount: activities.length,
                  itemBuilder: (context, i) {
                    final a = activities[i];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 2), // Reduced margin
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      child: ListTile(
                        leading: Icon(Icons.run_circle,
                            color: Colors.teal[300], size: 24), // Smaller icon
                        title: Text(
                          "${a['activity_type']} (${a['duration_minutes']} min)",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14), // Smaller font
                        ),
                        subtitle: Text(
                          "Calories: ${a['calories_burned'] ?? '-'} • ${a['timestamp']}\n${a['notes'] ?? ''}",
                          style: TextStyle(fontSize: 12), // Smaller font
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete,
                              color: Colors.red[300], size: 20), // Smaller icon
                          tooltip: "Delete Log",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Delete Activity Log"),
                                content: Text(
                                    "Are you sure you want to delete this activity log?"),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                            if (confirm == true) deleteActivity(a['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
