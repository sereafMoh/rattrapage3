import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  final Map<String, Color> lightTheme = {
    'background': Color(0xFFF7F8FA),
    'cardBackground': Colors.white,
    'textPrimary': Colors.black87,
    'textSecondary': Colors.grey[700]!,
    'accent': Colors.deepPurple[400]!,
    'accentLight': Colors.deepPurple[50]!,
    'iconPrimary': Colors.deepPurple[600]!,
    'iconSecondary': Colors.grey[700]!,
    'buttonText': Colors.white,
    'error': Colors.red,
    'inputDecoration': Colors.grey[200]!,
    'profileLineBackground': Colors.grey[100]!,
  };

  final Map<String, Color> darkTheme = {
    'background': Color(0xFF121212),
    'cardBackground': Color(0xFF1E1E1E),
    'textPrimary': Colors.white,
    'textSecondary': Colors.grey[400]!,
    'accent': Colors.deepPurple[300]!,
    'accentLight': Color(0xFF2A2135),
    'iconPrimary': Colors.deepPurple[200]!,
    'iconSecondary': Colors.grey[400]!,
    'buttonText': Colors.white,
    'error': Colors.red[400]!,
    'inputDecoration': Color(0xFF2A2A2A),
    'profileLineBackground': Color(0xFF2A2A2A),
  };

  Map<String, Color> get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}