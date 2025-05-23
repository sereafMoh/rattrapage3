import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../patient_home.dart';

const String apiBase = "http://192.168.100.53:5000";

class MealsTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const MealsTab({required this.user});
  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> {
  final mealDescCtrl = TextEditingController();
  final mealCaloriesCtrl = TextEditingController();
  final mealCarbsCtrl = TextEditingController();
  String mealType = "other";
  List<Map<String, dynamic>> mealLogs = [];
  bool loadingMeals = false;

  // Preset meals
  List<Map<String, dynamic>> presetMeals = [];
  List<Map<String, dynamic>> filteredMeals = [];
  String searchText = "";

  @override
  void initState() {
    super.initState();
    fetchMeals();
    loadPresetMeals();
  }

  Future<void> loadPresetMeals() async {
    final data = await rootBundle.loadString('assets/diabetes_meals.json');
    final List<dynamic> decoded = jsonDecode(data);
    setState(() {
      presetMeals = decoded.cast<Map<String, dynamic>>();
      filteredMeals = presetMeals;
    });
  }

  void fetchMeals() async {
    setState(() => loadingMeals = true);
    final res =
        await http.get(Uri.parse("$apiBase/meals/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() =>
          mealLogs = List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingMeals = false);
  }

  void addMeal() async {
    final desc = mealDescCtrl.text;
    final cal = int.tryParse(mealCaloriesCtrl.text) ?? 0;
    final carbs = int.tryParse(mealCarbsCtrl.text) ?? 0;
    if (desc.isEmpty) return;
    await http.post(Uri.parse("$apiBase/meals"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": widget.user['id'],
          "description": desc,
          "meal_type": mealType,
          "calories": cal,
          "carbs": carbs,
        }));
    mealDescCtrl.clear();
    mealCaloriesCtrl.clear();
    mealCarbsCtrl.clear();
    setState(() {
      mealType = "other";
    });
    fetchMeals();
  }

  void deleteMeal(int mealId) async {
    await http.delete(Uri.parse("$apiBase/meals/$mealId"));
    fetchMeals();
  }

  void showPresetMealsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "Search meal",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onChanged: (v) {
                      setState(() {
                        searchText = v.toLowerCase();
                        filteredMeals = presetMeals
                            .where((m) => (m['name'] as String)
                                .toLowerCase()
                                .contains(searchText))
                            .toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredMeals.isEmpty
                      ? Center(
                          child: Text("No meals found",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filteredMeals.length,
                          itemBuilder: (ctx, i) {
                            final meal = filteredMeals[i];
                            return ListTile(
                              leading: Icon(Icons.fastfood,
                                  color: Colors.orange[400]),
                              title: Text(meal['name'] ?? '',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${(meal['meal_type'] ?? '').toString().capitalize()} • ${meal['calories']} cal • ${meal['carbs']}g carbs",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                              onTap: () {
                                setState(() {
                                  mealDescCtrl.text = meal['name'] ?? '';
                                  mealType = meal['meal_type'] ?? 'other';
                                  mealCaloriesCtrl.text =
                                      (meal['calories'] ?? '').toString();
                                  mealCarbsCtrl.text =
                                      (meal['carbs'] ?? '').toString();
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    mealDescCtrl.dispose();
    mealCaloriesCtrl.dispose();
    mealCarbsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartLogs =
        mealLogs.isNotEmpty ? mealLogs.take(7).toList().reversed.toList() : [];

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
        title: Text('Meals Tab'),
        backgroundColor: Colors.orange,
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
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 24.0),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isNarrow = constraints.maxWidth < 700;
                          final inputWidgets = [
                            Flexible(
                              flex: 2,
                              child: TextField(
                                controller: mealDescCtrl,
                                decoration: InputDecoration(
                                  labelText: "Meal Description",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            SizedBox(
                                width: isNarrow ? 0 : 8,
                                height: isNarrow ? 10 : 0),
                            ElevatedButton.icon(
                              icon: Icon(Icons.restaurant_menu,
                                  color: Colors.orange[100]),
                              label: Text("Preset",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                shape: StadiumBorder(),
                              ),
                              onPressed: showPresetMealsSheet,
                            ),
                            SizedBox(
                                width: isNarrow ? 0 : 8,
                                height: isNarrow ? 10 : 0),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                value: mealType,
                                decoration: InputDecoration(
                                  labelText: "Type",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                items: [
                                  DropdownMenuItem(
                                      value: "breakfast",
                                      child: Text("Breakfast")),
                                  DropdownMenuItem(
                                      value: "lunch", child: Text("Lunch")),
                                  DropdownMenuItem(
                                      value: "snack", child: Text("Snack")),
                                  DropdownMenuItem(
                                      value: "dinner", child: Text("Dinner")),
                                  DropdownMenuItem(
                                      value: "other", child: Text("Other")),
                                ],
                                onChanged: (v) => setState(() => mealType = v!),
                              ),
                            ),
                            SizedBox(
                                width: isNarrow ? 0 : 8,
                                height: isNarrow ? 10 : 0),
                            SizedBox(
                              width: 85,
                              child: TextField(
                                controller: mealCaloriesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Cal",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            SizedBox(
                                width: isNarrow ? 0 : 8,
                                height: isNarrow ? 10 : 0),
                            SizedBox(
                              width: 85,
                              child: TextField(
                                controller: mealCarbsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Carbs",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            SizedBox(
                                width: isNarrow ? 0 : 8,
                                height: isNarrow ? 10 : 0),
                            ElevatedButton(
                              onPressed: addMeal,
                              child: Text("Add"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: StadiumBorder(),
                              ),
                            ),
                          ];
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: inputWidgets
                                  .map((w) => w is SizedBox
                                      ? w
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: w,
                                        ))
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: 22),
              Divider(height: 1, thickness: 0.7),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.fastfood, color: Colors.orange, size: 22),
                  SizedBox(width: 8),
                  Text("Meal Logs",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.orange[900])),
                ],
              ),
              SizedBox(height: 8),
              if (loadingMeals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 70.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 370, // <--- Controls how much is visible at once
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, thickness: 0.3),
                      itemCount: mealLogs.length,
                      itemBuilder: (context, i) {
                        final m = mealLogs[i];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 7),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 18),
                            leading: Icon(Icons.restaurant,
                                color: Colors.orange[300]),
                            title: Text(
                              "${m['description']} (${m['meal_type']})",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 17),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${m['timestamp']}\n${m['calories']} cal • ${m['carbs']}g carbs",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[300]),
                              tooltip: "Delete Log",
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("Delete Meal Log"),
                                    content: Text(
                                        "Are you sure you want to delete this meal log?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text("Cancel")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) deleteMeal(m['id']);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (chartLogs.length > 1) ...[
                SizedBox(height: 22),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Calories (last 7 meals)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                fontSize: 16)),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 50,
                                getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[300]!, strokeWidth: 1),
                              ),
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
                                      final t =
                                          chartLogs[idx]['timestamp'] ?? '';
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          t.length > 10
                                              ? t.substring(5, 10)
                                              : t,
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
                                      .map((m) =>
                                          (m['calories'] as num?)?.toDouble() ??
                                          0)
                                      .fold<double>(0,
                                          (prev, el) => el > prev ? el : prev) +
                                  50,
                              barGroups: List.generate(
                                chartLogs.length,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (chartLogs[i]['calories'] as num?)
                                              ?.toDouble() ??
                                          0,
                                      color: Colors.orange,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange,
                                          Colors.deepOrangeAccent
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension for capitalizing meal type
extension StringCasingExtension on String {
  String capitalize() =>
      this.length > 0 ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}
