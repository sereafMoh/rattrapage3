import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
