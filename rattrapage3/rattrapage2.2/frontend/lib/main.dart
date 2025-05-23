import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  // Preserve the splash screen while initialization occurs
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize timezone data (synchronous)
    tz.initializeTimeZones();
    debugPrint('Timezone initialization successful');
  } catch (e, stackTrace) {
    // Log the error and continue running the app
    debugPrint('Error initializing timezone: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Remove the splash screen after initialization
  try {
    FlutterNativeSplash.remove();
    debugPrint('Splash screen removed');
  } catch (e) {
    debugPrint('Error removing splash screen: $e');
  }

  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
