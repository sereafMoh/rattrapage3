import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'doctor_patient_profile_page.dart';

import 'doctor_profile_dialog.dart';

const String apiBase = "http://192.168.100.53:5000";

class DoctorPatientsTab extends StatefulWidget {
  final int doctorId;
  final Function(Map<String, dynamic>) onPatientChatSelected;
  const DoctorPatientsTab({
    required this.doctorId,
    required this.onPatientChatSelected,
  });

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  List<Map<String, dynamic>> patients = [];
  bool loading = false;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  void fetchPatients() async {
    setState(() => loading = true);
    final res = await http.get(
      Uri.parse("$apiBase/patients/${widget.doctorId}"),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(
        () => patients = List<Map<String, dynamic>>.from(jsonDecode(res.body)),
      );
    }
    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredPatients {
    if (searchText.isEmpty) return patients;
    return patients.where((p) {
      final name = (p['name'] ?? '').toLowerCase();
      final email = (p['email'] ?? '').toLowerCase();
      final city = (p['city'] ?? '').toLowerCase();
      return name.contains(searchText.toLowerCase()) ||
          email.contains(searchText.toLowerCase()) ||
          city.contains(searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Patients",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.deepPurple[900],
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by name, email, or city',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.deepPurple.shade100),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => searchText = v),
            ),
            SizedBox(height: 14),
            Expanded(
              child:
                  loading
                      ? Center(child: CircularProgressIndicator())
                      : filteredPatients.isEmpty
                      ? Center(
                        child: Text(
                          "No patients assigned.",
                          style: TextStyle(
                            color: Colors.deepPurple[200],
                            fontSize: 18,
                          ),
                        ),
                      )
                      : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width < 800 ? 1 : 2,
                          childAspectRatio: 2.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, i) {
                          final p = filteredPatients[i];
                          return Material(
                            color: Colors.white,
                            elevation: 2,
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple[100],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.deepPurple[900],
                                ),
                              ),
                              title: Text(
                                p['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${p['email']}\n${p['city'] ?? ''}, ${p['country'] ?? ''}",
                                style: TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_red_eye,
                                      color: Colors.deepPurple[400],
                                    ),
                                    tooltip: "View Profile",
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) =>
                                                DoctorPatientProfilePage(
                                                  doctorId: widget.doctorId,
                                                  patientId: p['id'],
                                                ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chat,
                                      color: Colors.deepPurple,
                                    ),
                                    tooltip: "Chat",
                                    onPressed:
                                        () => widget.onPatientChatSelected(p),
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
