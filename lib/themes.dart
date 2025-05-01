// lib/themes.dart (Optional file)
import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue, // Or another color
    // Customize other properties like scaffoldBackgroundColor, textTheme, etc.
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue, // Adjust for dark theme if needed
    // Customize for dark mode, e.g., scaffoldBackgroundColor: Colors.black
  );
}