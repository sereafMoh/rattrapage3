import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'location_data.dart';

const String apiBase = "http://192.168.100.53:5000";

class RegisterPatientScreen extends StatefulWidget {
  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final regNameCtrl = TextEditingController();
  final regEmailCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();
  final patPhoneCtrl = TextEditingController();
  DateTime? patDob;
  String patGender = "M";
  String? patCountryIso2;
  String? patCountryName;
  String? patCity;
  String patDiabetesType = "Prediabetes";
  final patHealthBgCtrl = TextEditingController();
  final patEmergencyNameCtrl = TextEditingController();
  final patEmergencyPhoneCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String error = '';
  bool loading = false;
  List<Country> countries = [];
  List<City> cities = [];

  @override
  void initState() {
    super.initState();
    LocationDataProvider.loadCountries().then((list) {
      setState(() {
        countries = list;
      });
    });
  }

  Future<void> pickCity(String? countryIso2) async {
    if (countryIso2 == null) return;
    setState(() {
      cities = [];
      patCity = null;
    });
    cities = await LocationDataProvider.loadCities(countryIso2);
    setState(() {});
  }

  void pickDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => patDob = picked);
  }

  void autofillEmergency() {
    if (patEmergencyNameCtrl.text.isEmpty && regNameCtrl.text.isNotEmpty) {
      patEmergencyNameCtrl.text = regNameCtrl.text.split(" ").first;
    }
    if (patEmergencyPhoneCtrl.text.isEmpty && patPhoneCtrl.text.isNotEmpty) {
      patEmergencyPhoneCtrl.text = patPhoneCtrl.text;
    }
    setState(() {});
  }

  void register() async {
    setState(() {
      error = "";
      loading = true;
    });
    final res = await http.post(
      Uri.parse("$apiBase/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": regNameCtrl.text.trim(),
        "email": regEmailCtrl.text.trim(),
        "password": regPassCtrl.text,
        "confirm_password": regPass2Ctrl.text,
        "role": "patient",
        "phone": patPhoneCtrl.text,
        "dob": patDob?.toIso8601String().split("T").first,
        "gender": patGender,
        "city": patCity,
        "country": patCountryName,
        "diabetes_type": patDiabetesType,
        "health_background": patHealthBgCtrl.text,
        "emergency_contact_name": patEmergencyNameCtrl.text,
        "emergency_contact_phone": patEmergencyPhoneCtrl.text,
      }),
    );
    setState(() => loading = false);
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        error = "Registration successful! Please login.";
      });
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } else {
      setState(
        () =>
            error =
                "Registration failed: ${jsonDecode(res.body)["error"].toString()}",
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  void showCountryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Country'),
          content: Container(
            width: double.maxFinite,
            height: 300, // Fixed height for scrollable list
            child: ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                return ListTile(
                  title: Text(country.name),
                  onTap: () {
                    setState(() {
                      patCountryIso2 = country.iso2;
                      patCountryName = country.name;
                    });
                    pickCity(country.iso2);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9F8FEF),
              Color(0xFFB8A5F2),
              Color(0xFFB8A5F2),
              Color(0x00000000),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(top: 28),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/icon.png",
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  'REGISTER AS PATIENT',
                  style: GoogleFonts.jockeyOne(
                    color: const Color(0xFF333333),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account to get started',
                  style: GoogleFonts.jockeyOne(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  color: Colors.transparent,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Full Name',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: regNameCtrl,
                          decoration: _inputDecoration('Enter your full name'),
                          onChanged: (_) => autofillEmergency(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: regEmailCtrl,
                          decoration: _inputDecoration('Enter your email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: patPhoneCtrl,
                          decoration: _inputDecoration(
                            'Enter your phone number',
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => autofillEmergency(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.cake, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Date of Birth',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            patDob == null
                                ? 'Select your date of birth'
                                : patDob!.toIso8601String().split("T").first,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: Colors.black54,
                              ),
                              onPressed: () => pickDob(context),
                            ),
                          ),
                          onTap: () => pickDob(context),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.wc, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Gender',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: patGender,
                          decoration: _inputDecoration('Select your gender'),
                          items: [
                            DropdownMenuItem(value: "M", child: Text("Male")),
                            DropdownMenuItem(value: "F", child: Text("Female")),
                            DropdownMenuItem(
                              value: "Other",
                              child: Text("Other"),
                            ),
                          ],
                          onChanged: (v) => setState(() => patGender = v!),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Country',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: showCountryDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  patCountryName ?? 'Select your country',
                                  style: TextStyle(
                                    color:
                                        patCountryName == null
                                            ? Colors.grey
                                            : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.location_city,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'City',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: patCity,
                          decoration: _inputDecoration('Select your city'),
                          items:
                              cities
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => patCity = v),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.bloodtype,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Diabetes Type',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: patDiabetesType,
                          decoration: _inputDecoration(
                            'Select your diabetes type',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "Prediabetes",
                              child: Text("Prediabetes"),
                            ),
                            DropdownMenuItem(
                              value: "Type 1",
                              child: Text("Type 1"),
                            ),
                            DropdownMenuItem(
                              value: "Type 2",
                              child: Text("Type 2"),
                            ),
                            DropdownMenuItem(
                              value: "Gestational",
                              child: Text("Gestational"),
                            ),
                          ],
                          onChanged:
                              (v) => setState(() => patDiabetesType = v!),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Health Background (optional)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: patHealthBgCtrl,
                          decoration: _inputDecoration(
                            'Enter your health background',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.person_pin,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Contact Name',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: patEmergencyNameCtrl,
                          decoration: _inputDecoration(
                            'Enter emergency contact name',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Contact Phone',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: patEmergencyPhoneCtrl,
                          decoration: _inputDecoration(
                            'Enter emergency contact phone',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(Icons.lock, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: regPassCtrl,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration(
                            'Enter your password',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confirm Password',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: regPass2Ctrl,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _inputDecoration(
                            'Confirm your password',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (error.isNotEmpty)
                          Text(
                            error,
                            style: TextStyle(
                              color:
                                  error.contains("success")
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (loading)
                          Center(child: CircularProgressIndicator())
                        else ...[
                          ElevatedButton(
                            onPressed: register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Back to Login',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
