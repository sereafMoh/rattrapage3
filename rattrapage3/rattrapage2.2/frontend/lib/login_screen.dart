import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'patient_home.dart';
import 'doctor_home.dart';
import 'register_patient.dart';
import 'register_doctor.dart';

const String apiBase = "http://192.168.100.53:5000";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Please enter both email and password.");
      return;
    }

    setState(() {
      _error = '';
      _isLoading = true;
    });

    try {
      final res = await http.post(
        Uri.parse("$apiBase/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final user = jsonDecode(res.body);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                user['role'] == 'doctor' ? DoctorHome(user: user) : PatientHome(user: user),
          ),
          (route) => false,
        );
      } else {
        final err = jsonDecode(res.body);
        setState(() => _error = err['message'] ?? 'Invalid login.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double logoSize = 110;
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
                // Top logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(blurRadius: 18, color: Colors.black12, spreadRadius: 2)
                    ],
                  ),
                  margin: const EdgeInsets.only(bottom: 28),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/icon.png",
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Title
                Text(
                  'WELCOME BACK!',
                  style: GoogleFonts.jockeyOne(
                    color: const Color(0xFF333333),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your Diabetes Companion',
                  style: GoogleFonts.jockeyOne(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // Transparent card containing form and register buttons
                Card(
                  color: Colors.transparent, // <-- Added to make the card transparent
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text('Email', style: const TextStyle(color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: _inputDecoration('Enter your email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text('Password', style: const TextStyle(color: Colors.black, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration('Enter your password').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (_error.isNotEmpty)
                          Text(
                            _error,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        if (_error.isNotEmpty) const SizedBox(height: 14),

                        GestureDetector(
                          onTap: _login,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>  RegisterPatientScreen()),
                          ),
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('REGISTER AS PATIENT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>  RegisterDoctorScreen()),
                          ),
                          icon: const Icon(Icons.medical_services),
                          label: const Text('REGISTER AS DOCTOR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Removed bottom illustration as requested
              ],
            ),
          ),
        ),
      ),
    );
  }
}