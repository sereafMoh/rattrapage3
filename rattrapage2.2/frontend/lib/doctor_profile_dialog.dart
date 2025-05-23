import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBase = "http://192.168.1.35:5000";

class DoctorProfileDialog extends StatelessWidget {
  final Map<String, dynamic>? doctorProfile;
  final bool loading;
  final VoidCallback? onRefresh;

  const DoctorProfileDialog({
    Key? key,
    required this.doctorProfile,
    required this.loading,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    if (doctorProfile == null) {
      return AlertDialog(
        title: Text("Doctor Profile"),
        content: Text("No profile data found."),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        width: 420,
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.06),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // center children
            children: [
              // Name
              Text(
                doctorProfile!['name'] ?? "",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                ),
              ),
              const SizedBox(height: 16),

              // User icon
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.deepPurple[50],
                child: Icon(
                  Icons.person,
                  size: 44,
                  color: Colors.deepPurple[700],
                ),
              ),
              const SizedBox(height: 16),

              // Specialty
              Text(
                doctorProfile!['specialty'] ?? "-",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.deepPurple[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Refresh and Close buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: "Refresh Profile",
                    onPressed: onRefresh,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(),

              // Info rows
              ..._infoRow("Email", doctorProfile!['email']),
              ..._infoRow("Phone", doctorProfile!['phone']),
              ..._infoRow("Clinic", doctorProfile!['clinic']),
              ..._infoRow("License", doctorProfile!['license_number']),
              ..._infoRow("City", doctorProfile!['city']),
              ..._infoRow("Country", doctorProfile!['country']),

              const SizedBox(height: 14),
              if (doctorProfile!['geo_lat'] != null &&
                  doctorProfile!['geo_lng'] != null)
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: Text(
                      "Google Maps Placeholder\n"
                      "Lat: ${doctorProfile!['geo_lat']}, "
                      "Lng: ${doctorProfile!['geo_lng']}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.deepPurple[400]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _infoRow(String label, String? value) => [
    const SizedBox(height: 6),
    Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        Expanded(
          child: Text(
            value ?? "-",
            style: TextStyle(
              color: Colors.deepPurple[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ];
}
