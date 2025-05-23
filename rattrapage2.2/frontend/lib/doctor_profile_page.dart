import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'tabs/doctor_tab.dart'; // For InfoRow

class DoctorProfilePage extends StatefulWidget {
  final int doctorId;
  const DoctorProfilePage({required this.doctorId});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? doctorProfile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctorProfile();
  }

  void fetchDoctorProfile() async {
    setState(() => loading = true);
    final res = await http.get(
      Uri.parse("http://192.168.1.35:5000/doctor_profile/${widget.doctorId}"),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        doctorProfile = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() {
        doctorProfile = null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(
        appBar: AppBar(title: Text("Doctor Profile")),
        body: Center(child: CircularProgressIndicator()),
      );
    if (doctorProfile == null)
      return Scaffold(
        appBar: AppBar(title: Text("Doctor Profile")),
        body: Center(child: Text("No profile data.")),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(doctorProfile?['name'] ?? "Doctor Profile"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.blueGrey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.person,
                        size: 44,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: Text(
                        doctorProfile?['name'] ?? "",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Divider(),
                InfoRow(label: "Email", value: doctorProfile?['email']),
                InfoRow(label: "Phone", value: doctorProfile?['phone']),
                InfoRow(label: "Specialty", value: doctorProfile?['specialty']),
                InfoRow(label: "Clinic", value: doctorProfile?['clinic']),
                InfoRow(
                  label: "License Number",
                  value: doctorProfile?['license_number'],
                ),
                InfoRow(label: "City", value: doctorProfile?['city']),
                InfoRow(label: "Country", value: doctorProfile?['country']),
                SizedBox(height: 18),
                if (doctorProfile?['geo_lat'] != null &&
                    doctorProfile?['geo_lng'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            "Google Maps Placeholder\nLat: ${doctorProfile!['geo_lat']}, Lng: ${doctorProfile!['geo_lng']}",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // Google Maps widget could be placed here.
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const InfoRow({required this.label, this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value ?? "", style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}
