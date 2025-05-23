import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../patient_home.dart';

const String apiBase = "http://192.168.100.53:5000";

class MedicationsTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const MedicationsTab({required this.user});
  @override
  State<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<MedicationsTab> {
  List<Map<String, dynamic>> myMedications = [];
  bool loadingMeds = false;
  List<Map<String, dynamic>> presetMeds = [];
  String? selectedMedName;
  String? selectedMedType;
  final customMedCtrl = TextEditingController();
  final customDoseCtrl = TextEditingController();
  String medType = "Oral";

  @override
  void initState() {
    super.initState();
    fetchMedications();
    loadPresetMeds();
  }

  Future<void> loadPresetMeds() async {
    final data = await rootBundle.loadString('assets/diabetes_meds.json');
    setState(() {
      presetMeds = List<Map<String, dynamic>>.from(jsonDecode(data));
    });
  }

  void fetchMedications() async {
    setState(() => loadingMeds = true);
    final res =
        await http.get(Uri.parse("$apiBase/medications/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => myMedications =
          List<Map<String, dynamic>>.from(jsonDecode(res.body)));
    }
    setState(() => loadingMeds = false);
  }

  void addMedication() async {
    String name = selectedMedName ?? customMedCtrl.text;
    String type = selectedMedType ?? medType;
    String dose = customDoseCtrl.text;
    if (name.isEmpty || dose.isEmpty || type.isEmpty) return;
    await http.post(
      Uri.parse("$apiBase/medications"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patient_id": widget.user['id'],
        "doctor_id": null,
        "med_name": name,
        "dosage": dose,
        "med_type": type,
        "added_by_patient": 1
      }),
    );
    customMedCtrl.clear();
    customDoseCtrl.clear();
    setState(() {
      selectedMedName = null;
      selectedMedType = null;
    });
    fetchMedications();
  }

  void deleteMedication(int medId) async {
    await http.delete(
      Uri.parse("$apiBase/medications/$medId"),
    );
    fetchMedications();
  }

  void editMedicationDialog(Map<String, dynamic> med) {
    final doseCtrl = TextEditingController(text: med['dosage'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Dosage"),
        content: TextField(
          controller: doseCtrl,
          decoration: InputDecoration(labelText: "Dosage"),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text("Save"),
            onPressed: () async {
              await http.put(
                Uri.parse("$apiBase/medications/${med['id']}"),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  "dosage": doseCtrl.text,
                  // you can send other fields if needed
                }),
              );
              Navigator.pop(ctx);
              fetchMedications();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    customMedCtrl.dispose();
    customDoseCtrl.dispose();
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
        title: Text('Medications Tab'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: loadingMeds
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Add Medication",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                  fontSize: 18)),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedMedName,
                                  hint: Text("Select Medication"),
                                  items: presetMeds
                                      .map<DropdownMenuItem<String>>((m) =>
                                          DropdownMenuItem<String>(
                                              value: m['name'] as String,
                                              child: Text(m['name'] as String)))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedMedName = v;
                                      selectedMedType = presetMeds.firstWhere(
                                          (m) => m['name'] == v)['type'];
                                      customMedCtrl.clear();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Text("or"),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: customMedCtrl,
                                  decoration: InputDecoration(
                                      labelText: "Other Medication"),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v.isNotEmpty) selectedMedName = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: customDoseCtrl,
                                  decoration:
                                      InputDecoration(labelText: "Dosage"),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedMedType ?? medType,
                                  items: [
                                    DropdownMenuItem(
                                        value: "Oral", child: Text("Oral")),
                                    DropdownMenuItem(
                                        value: "Insulin",
                                        child: Text("Insulin")),
                                    DropdownMenuItem(
                                        value: "Both", child: Text("Both")),
                                    DropdownMenuItem(
                                        value: "Other", child: Text("Other")),
                                  ],
                                  onChanged: (v) => setState(() {
                                    if (selectedMedName != null)
                                      selectedMedType = v;
                                    else
                                      medType = v!;
                                  }),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: addMedication,
                                icon: Icon(Icons.add),
                                label: Text("Add"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("My Medications:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                          fontSize: 18)),
                  SizedBox(height: 8),
                  Expanded(
                    child: myMedications.isEmpty
                        ? Center(child: Text("No medications assigned."))
                        : ListView.separated(
                            itemCount: myMedications.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, thickness: 0.4),
                            itemBuilder: (context, i) {
                              final m = myMedications[i];
                              return Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 1,
                                child: ListTile(
                                  leading: Icon(Icons.medical_services,
                                      color: m['is_active'] == 1
                                          ? Colors.green
                                          : Colors.red),
                                  title: Text(
                                      "${m['med_name']} (${m['med_type']})",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      "Dosage: ${m['dosage']}\nPrescribed on: ${m['prescribed_at']}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        tooltip: "Edit Dosage",
                                        onPressed: () =>
                                            editMedicationDialog(m),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red[300]),
                                        tooltip: "Delete Medication",
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text("Delete Medication"),
                                            content: Text(
                                                "Are you sure you want to delete this medication?"),
                                            actions: [
                                              TextButton(
                                                child: Text("Cancel"),
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                              ),
                                              ElevatedButton(
                                                child: Text("Delete"),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  deleteMedication(m['id']);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
