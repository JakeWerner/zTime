// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the list of selectable MaterialColors and their names
// Make this accessible, perhaps as a static member or top-level constant
class AppColors {
  // Using const for the map keys and values where possible
  static const Map<String, MaterialColor> primaryColorOptions = {
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Red': Colors.red,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Teal': Colors.teal,
    'Indigo': Colors.indigo,
    'Pink': Colors.pink,
    'Brown': Colors.brown,
    'Grey': Colors.grey,
  };

  // Helper to get MaterialColor from its primary value (int)
  static MaterialColor colorFromValue(int? value) {
    // Default to blue if no value saved or saved value is invalid
    if (value == null) return Colors.blue;
    // Find the MaterialColor whose primary shade value matches the saved int
    return primaryColorOptions.values.firstWhere(
          (color) => color.value == value,
          orElse: () => Colors.blue, // Fallback to default blue
        );
  }
}


class ThemeProvider with ChangeNotifier {
  // --- State ---
  ThemeMode _themeMode = ThemeMode.system; // Default to system preference
  MaterialColor _primaryColor = Colors.blue; // Default color

  // --- Constants for SharedPreferences ---
  static const String _themePrefKey = 'themeMode';
  static const String _colorPrefKey = 'primaryColorValue';

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  MaterialColor get primaryColor => _primaryColor;

  // Getter for dynamic light theme based on selected primary color
  ThemeData get lightThemeData => ThemeData.from(
    colorScheme: ColorScheme.fromSwatch(
        primarySwatch: _primaryColor,
        // You can optionally fine-tune other colors here:
        // accentColor: _primaryColor[400], // Example accent
        brightness: Brightness.light,
      ),
      // Add other global theme customizations for light mode if needed
      // e.g., appBarTheme, textTheme, etc.
      useMaterial3: true, // Recommended for modern look
  );

  // Getter for dynamic dark theme based on selected primary color
   ThemeData get darkThemeData => ThemeData.from(
     colorScheme: ColorScheme.fromSwatch(
        primarySwatch: _primaryColor,
        brightness: Brightness.dark, // Set brightness to dark
      ),
      // Add other global theme customizations for dark mode if needed
     useMaterial3: true,
   );

  // --- Initialization ---
  ThemeProvider() {
    print("ThemeProvider: Initializing and loading preferences...");
    _loadPreferences(); // Load saved preference on initialization
  }

  // --- Persistence ---
  Future<void> _loadPreferences() async {
    try {
        final prefs = await SharedPreferences.getInstance();

        // Load Theme Mode
        final themeString = prefs.getString(_themePrefKey) ?? 'system';
        if (themeString == 'light') _themeMode = ThemeMode.light;
        else if (themeString == 'dark') _themeMode = ThemeMode.dark;
        else _themeMode = ThemeMode.system;

        // Load Color
        final savedColorValue = prefs.getInt(_colorPrefKey);
        _primaryColor = AppColors.colorFromValue(savedColorValue);

        print("ThemeProvider: Preferences Loaded: ThemeMode=$_themeMode, PrimaryColor=${_primaryColor.toString()}");
    } catch (e) {
        print("ThemeProvider: Error loading preferences: $e");
        // Keep default values if loading fails
    }
    // Notify listeners even if loading fails to apply defaults
    notifyListeners();
  }

  Future<void> _saveThemePreference(String themeString) async {
    try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themePrefKey, themeString);
         print("ThemeProvider: Saved ThemeMode: $themeString");
    } catch (e) {
         print("ThemeProvider: Error saving theme preference: $e");
    }
  }

   Future<void> _saveColorPreference(MaterialColor color) async {
     try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_colorPrefKey, color.value); // Save the primary int value
        print("ThemeProvider: Saved PrimaryColor Value: ${color.value}");
     } catch (e) {
         print("ThemeProvider: Error saving color preference: $e");
     }
  }

  // --- Methods to change state ---
  void setLightMode() {
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      _saveThemePreference('light');
      notifyListeners();
    }
  }

  void setDarkMode() {
    if (_themeMode != ThemeMode.dark) {
      _themeMode = ThemeMode.dark;
      _saveThemePreference('dark');
      notifyListeners();
    }
  }

  void setSystemMode() {
    if (_themeMode != ThemeMode.system) {
      _themeMode = ThemeMode.system;
      _saveThemePreference('system');
      notifyListeners();
    }
  }

  void setPrimaryColor(MaterialColor color) {
     if (_primaryColor != color) {
        _primaryColor = color;
        _saveColorPreference(color);
        print("ThemeProvider: Primary Color Set: ${_primaryColor.toString()}");
        notifyListeners(); // Crucial: This triggers MyApp to rebuild with new theme data
     }
  }
}