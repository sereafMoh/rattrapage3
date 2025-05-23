import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'location_data.dart';

const String apiBase = "http://192.168.100.53:5000";

class RegisterDoctorScreen extends StatefulWidget {
  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final regNameCtrl = TextEditingController();
  final regEmailCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();
  final docPhoneCtrl = TextEditingController();
  final docClinicCtrl = TextEditingController();
  final docLicenseCtrl = TextEditingController();

  String? docSpecialtyId;
  String? docCountryIso2;
  String? docCountryName;
  String? docCity;

  String error = '';
  bool loading = false;
  List<Country> countries = [];
  List<City> cities = [];
  List<Map<String, dynamic>> specialties = [];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
    LocationDataProvider.loadCountries().then((list) {
      setState(() {
        countries = list;
      });
    });
  }

  Future<void> _loadSpecialties() async {
    try {
      final res = await http.get(Uri.parse("$apiBase/specialties"));
      print("Specialties response: ${res.body}"); // Debug
      if (res.statusCode == 200) {
        setState(() {
          specialties = List<Map<String, dynamic>>.from(jsonDecode(res.body));
          // Reset docSpecialtyId if it’s invalid
          if (specialties.isNotEmpty &&
              !specialties.any((s) => s["id"].toString() == docSpecialtyId)) {
            docSpecialtyId = null;
          }
        });
      } else {
        setState(() {
          error = "Failed to load specialties: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = "Error loading specialties: $e";
      });
      specialties = [];
    }
  }

  Future<void> pickCity(String? countryIso2) async {
    if (countryIso2 == null) {
      setState(() {
        cities = [];
        docCity = null;
        error = "Please select a country first";
      });
      return;
    }
    try {
      setState(() {
        cities = [];
        docCity = null;
        loading = true;
      });
      cities = await LocationDataProvider.loadCities(countryIso2);
      setState(() {
        loading = false;
        if (cities.isEmpty) {
          error = "No cities found for the selected country";
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "Error loading cities: $e";
        cities = [];
        docCity = null;
      });
    }
  }

  void autofillClinic() {
    if (docClinicCtrl.text.isEmpty && docCity != null) {
      docClinicCtrl.text = "General Clinic, $docCity";
      setState(() {});
    }
  }

  void register() async {
    if (docSpecialtyId == null || docCity == null) {
      setState(() {
        error = "Please select a specialty and city";
        loading = false;
      });
      return;
    }
    setState(() {
      error = "";
      loading = true;
    });
    try {
      final res = await http.post(
        Uri.parse("$apiBase/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": regNameCtrl.text.trim(),
          "email": regEmailCtrl.text.trim(),
          "password": regPassCtrl.text,
          "confirm_password": regPass2Ctrl.text,
          "role": "doctor",
          "phone": docPhoneCtrl.text,
          "specialty_id": docSpecialtyId,
          "clinic": docClinicCtrl.text,
          "city": docCity,
          "country": docCountryName,
          "license_number": docLicenseCtrl.text,
        }),
      );
      setState(() => loading = false);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          error = "Registration successful! Please login.";
        });
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(
          () =>
              error =
                  "Registration failed: ${jsonDecode(res.body)["error"].toString()}",
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = "Error during registration: $e";
      });
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
            height: 300,
            child:
                countries.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: countries.length,
                      itemBuilder: (context, index) {
                        final country = countries[index];
                        return ListTile(
                          title: Text(country.name),
                          onTap: () {
                            setState(() {
                              docCountryIso2 = country.iso2;
                              docCountryName = country.name;
                              docCity = null;
                              cities = [];
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
                Text(
                  'REGISTER AS DOCTOR',
                  style: GoogleFonts.jockeyOne(
                    color: const Color(0xFF333333),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your doctor account to get started',
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
                        // Full Name
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Email
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Phone Number
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
                          controller: docPhoneCtrl,
                          decoration: _inputDecoration(
                            'Enter your phone number',
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Medical Specialty
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Medical Specialty',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: docSpecialtyId,
                          decoration: _inputDecoration(
                            specialties.isEmpty
                                ? 'No specialties available'
                                : 'Select your specialty',
                          ),
                          items:
                              specialties.isEmpty
                                  ? [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text('No specialties available'),
                                    ),
                                  ]
                                  : specialties
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s["id"].toString(),
                                          child: Text(s["name"]),
                                        ),
                                      )
                                      .toList(),
                          onChanged:
                              specialties.isEmpty
                                  ? null
                                  : (v) => setState(() => docSpecialtyId = v),
                        ),
                        const SizedBox(height: 18),
                        // Clinic/Hospital Name
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Clinic/Hospital Name',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: docClinicCtrl,
                          decoration: _inputDecoration(
                            'Enter your clinic/hospital name',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Country
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
                                  docCountryName ?? 'Select your country',
                                  style: TextStyle(
                                    color:
                                        docCountryName == null
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
                        // City
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
                          value: docCity,
                          decoration: _inputDecoration(
                            docCountryIso2 == null
                                ? 'Select a country first'
                                : 'Select your city',
                          ),
                          items:
                              cities
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              docCountryIso2 == null
                                  ? null
                                  : (v) {
                                    setState(() => docCity = v);
                                    autofillClinic();
                                  },
                        ),
                        const SizedBox(height: 18),
                        // Professional License/ID Number
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Professional License/ID Number',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: docLicenseCtrl,
                          decoration: _inputDecoration(
                            'Enter your license/ID number',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Password
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        // Confirm Password
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
                          textInputAction: TextInputAction.done,
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
                            textAlign: TextAlign.center,
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

  @override
  void dispose() {
    regNameCtrl.dispose();
    regEmailCtrl.dispose();
    regPassCtrl.dispose();
    regPass2Ctrl.dispose();
    docPhoneCtrl.dispose();
    docClinicCtrl.dispose();
    docLicenseCtrl.dispose();
    super.dispose();
  }
}
