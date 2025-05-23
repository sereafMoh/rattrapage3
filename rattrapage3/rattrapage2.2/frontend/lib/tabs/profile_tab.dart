import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../patient_home.dart';

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileTab({required this.user});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? profile;
  bool editing = false;
  bool loading = false;
  String error = "";

  // Controllers for editing
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  String gender = "M";
  String city = "";
  String country = "";
  String diabetesType = "Type 2";
  final healthBgCtrl = TextEditingController();
  final emContactNameCtrl = TextEditingController();
  final emContactPhoneCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final hydrationCtrl = TextEditingController();

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> allCities = [];

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadCountries();
    loadCities();
  }

  Future<void> loadCountries() async {
    final String data = await rootBundle.loadString('assets/countries.json');
    final List<dynamic> jsonResult = jsonDecode(data);
    setState(() {
      countries = List<Map<String, dynamic>>.from(jsonResult);
    });
  }

  Future<void> loadCities() async {
    final String data = await rootBundle.loadString('assets/cities.json');
    final List<dynamic> jsonResult = jsonDecode(data);
    allCities = List<Map<String, dynamic>>.from(jsonResult);
    setState(() {
      if (country.isNotEmpty) {
        filterCities(country);
      }
    });
  }

  void filterCities(String selectedCountry) {
    setState(() {
      if (selectedCountry.isNotEmpty) {
        cities = allCities
            .where((c) => c['country_name'] == selectedCountry)
            .toList();
      } else {
        cities = [];
      }
      city = '';
    });
  }

  void fetchProfile() async {
    setState(() => loading = true);
    final res = await http
        .get(Uri.parse("$apiBase/patient_profile/${widget.user['id']}"));
    if (!mounted) return;
    if (res.statusCode == 200) {
      profile = jsonDecode(res.body);
      nameCtrl.text = profile?['name'] ?? "";
      phoneCtrl.text = profile?['phone'] ?? "";
      dobCtrl.text = profile?['dob'] ?? "";
      gender = profile?['gender'] ?? "M";
      city = profile?['city'] ?? "";
      country = profile?['country'] ?? "";
      diabetesType = profile?['diabetes_type'] ?? "Type 2";
      healthBgCtrl.text = profile?['health_background'] ?? "";
      emContactNameCtrl.text = profile?['emergency_contact_name'] ?? "";
      emContactPhoneCtrl.text = profile?['emergency_contact_phone'] ?? "";
      weightCtrl.text = (profile?['weight_kg'] ?? "").toString();
      hydrationCtrl.text = (profile?['hydration_liters'] ?? "").toString();

      // Filter cities if country is set
      if (country.isNotEmpty && allCities.isNotEmpty) filterCities(country);

      setState(() {});
    }
    setState(() => loading = false);
  }

  void saveProfile() async {
    setState(() {
      error = "";
      loading = true;
    });
    final res = await http.put(
      Uri.parse("$apiBase/patient_profile/${widget.user['id']}"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "phone": phoneCtrl.text,
        "dob": dobCtrl.text,
        "gender": gender,
        "city": city,
        "country": country,
        "diabetes_type": diabetesType,
        "health_background": healthBgCtrl.text,
        "emergency_contact_name": emContactNameCtrl.text,
        "emergency_contact_phone": emContactPhoneCtrl.text,
        "weight_kg": weightCtrl.text,
        "hydration_liters": hydrationCtrl.text
      }),
    );
    if (res.statusCode == 200) {
      setState(() {
        editing = false;
      });
      fetchProfile();
    } else {
      setState(() {
        error = "Update failed";
      });
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading && profile == null)
      return Center(child: CircularProgressIndicator());
    if (profile == null) return Center(child: Text("No profile data."));
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            margin: EdgeInsets.only(top: 36, bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: editing ? buildEditForm() : buildProfileView(),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 12,
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 30, color: Colors.grey[700]),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: "Back",
          ),
        ),
      ],
    );
  }

  Widget buildProfileView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.purple[50],
              child: Icon(Icons.person, size: 46, color: Colors.deepPurple),
            ),
          ),
          SizedBox(height: 18),
          Center(
            child: Text(
              profile?['name'] ?? "",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[900],
                  fontFamily: "Montserrat"),
            ),
          ),
          SizedBox(height: 28),
          Column(
            children: [
              if (profile?['email'] != null &&
                  profile!['email'].toString().isNotEmpty)
                ProfileLine(
                    icon: Icons.email,
                    label: "Email",
                    value: profile?['email']),
              ProfileLine(
                  icon: Icons.phone, label: "Phone", value: profile?['phone']),
              ProfileLine(
                  icon: Icons.cake,
                  label: "Date of Birth",
                  value: profile?['dob']),
              ProfileLine(
                  icon: Icons.transgender,
                  label: "Gender",
                  value: genderString(profile?['gender'])),
              ProfileLine(
                  icon: Icons.flag,
                  label: "Country",
                  value: profile?['country']),
              ProfileLine(
                  icon: Icons.location_city,
                  label: "City",
                  value: profile?['city']),
              ProfileLine(
                  icon: Icons.opacity,
                  label: "Diabetes Type",
                  value: profile?['diabetes_type']),
              ProfileLine(
                  icon: Icons.monitor_weight,
                  label: "Weight (kg)",
                  value: (profile?['weight_kg'] ?? "").toString()),
              ProfileLine(
                  icon: Icons.water_drop,
                  label: "Hydration (L)",
                  value: (profile?['hydration_liters'] ?? "").toString()),
              if (profile?['health_background'] != null &&
                  profile!['health_background'].toString().trim().isNotEmpty)
                ProfileLine(
                    icon: Icons.favorite,
                    label: "Health Background",
                    value: profile?['health_background']),
              ProfileLine(
                  icon: Icons.person_pin,
                  label: "Emergency Contact",
                  value: profile?['emergency_contact_name']),
              ProfileLine(
                  icon: Icons.phone_in_talk,
                  label: "Emergency Phone",
                  value: profile?['emergency_contact_phone']),
            ],
          ),
          SizedBox(height: 34),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[400],
                  foregroundColor: Colors.white,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                ),
                icon: Icon(Icons.edit),
                label: Text("Edit Profile"),
                onPressed: () => setState(() => editing = true),
              ),
            ],
          )
        ],
      );

  Widget buildEditForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: "Name",
              prefixIcon: Icon(Icons.person, color: Colors.deepPurple[200]),
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            decoration: InputDecoration(
              labelText: "Phone",
              prefixIcon: Icon(Icons.phone, color: Colors.teal[200]),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: dobCtrl.text.isNotEmpty
                    ? DateTime.tryParse(dobCtrl.text) ?? DateTime(2000)
                    : DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                dobCtrl.text = picked.toIso8601String().split('T').first;
                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: dobCtrl,
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  prefixIcon: Icon(Icons.cake, color: Colors.pink[200]),
                  suffixIcon:
                      Icon(Icons.calendar_today, color: Colors.pink[200]),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: gender,
            decoration: InputDecoration(
              labelText: "Gender",
              prefixIcon: Icon(Icons.transgender, color: Colors.blue[200]),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem(value: "M", child: Text("Male")),
              DropdownMenuItem(value: "F", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (v) => setState(() => gender = v!),
          ),
          SizedBox(height: 12),
          // FIXED: Explicit <String> for DropdownMenuItem and value/country name extraction
          DropdownButtonFormField<String>(
            value: country.isNotEmpty ? country : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Country",
              prefixIcon: Icon(Icons.flag, color: Colors.orange[200]),
            ),
            items: countries
                .map((c) => DropdownMenuItem<String>(
                      value: c['name'] as String,
                      child: Text(c['name'] as String),
                    ))
                .toList(),
            onChanged: (v) {
              country = v ?? "";
              filterCities(country);
              setState(() {});
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: city.isNotEmpty ? city : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "City",
              prefixIcon: Icon(Icons.location_city, color: Colors.green[200]),
            ),
            items: cities
                .map((c) => DropdownMenuItem<String>(
                      value: c['name'] as String,
                      child: Text(c['name'] as String),
                    ))
                .toList(),
            onChanged: (v) {
              city = v ?? "";
              setState(() {});
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: diabetesType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Diabetes Type",
              prefixIcon: Icon(Icons.opacity, color: Colors.blueGrey[200]),
            ),
            items: [
              DropdownMenuItem(value: "Type 1", child: Text("Type 1")),
              DropdownMenuItem(value: "Type 2", child: Text("Type 2")),
              DropdownMenuItem(
                  value: "Prediabetes", child: Text("Prediabetes")),
              DropdownMenuItem(
                  value: "Gestational", child: Text("Gestational")),
            ],
            onChanged: (v) => setState(() => diabetesType = v!),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: weightCtrl,
            decoration: InputDecoration(
              labelText: "Weight (kg)",
              prefixIcon: Icon(Icons.monitor_weight, color: Colors.teal[200]),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: hydrationCtrl,
            decoration: InputDecoration(
              labelText: "Hydration (L)",
              prefixIcon: Icon(Icons.water_drop, color: Colors.lightBlue[200]),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: healthBgCtrl,
            decoration: InputDecoration(
              labelText: "Health Background (optional)",
              prefixIcon: Icon(Icons.favorite, color: Colors.pink[200]),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: emContactNameCtrl,
            decoration: InputDecoration(
              labelText: "Emergency Contact Name",
              prefixIcon: Icon(Icons.person_pin, color: Colors.deepOrange[200]),
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: emContactPhoneCtrl,
            decoration: InputDecoration(
              labelText: "Emergency Contact Phone",
              prefixIcon: Icon(Icons.phone_in_talk, color: Colors.red[200]),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 20),
          if (error.isNotEmpty)
            Text(error,
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[400],
                  foregroundColor: Colors.white,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                ),
                icon: Icon(Icons.save),
                label: Text("Save"),
                onPressed: saveProfile,
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.cancel, color: Colors.red),
                label: Text("Cancel", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red, width: 1.5),
                  shape: StadiumBorder(),
                ),
                onPressed: () => setState(() => editing = false),
              ),
            ],
          ),
        ],
      );

  String genderString(String? g) {
    switch (g) {
      case "M":
        return "Male";
      case "F":
        return "Female";
      case "Other":
        return "Other";
      default:
        return "";
    }
  }
}

class ProfileLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const ProfileLine({required this.icon, required this.label, this.value});
  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple, size: 26),
        title: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple[700],
              fontSize: 15,
              fontFamily: "Montserrat"),
        ),
        subtitle: Text(
          value!,
          style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w400,
              fontSize: 14,
              fontFamily: "Montserrat"),
        ),
      ),
    );
  }
}
