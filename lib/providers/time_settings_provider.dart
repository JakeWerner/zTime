// lib/providers/time_settings_provider.dart
import 'package:flutter/foundation.dart'; // Use foundation instead of material
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeSettingsProvider with ChangeNotifier {
  bool _isLocalTimeAutomatic = true;
  String? _manualTimeZoneId; // e.g., "America/Denver", "Europe/London"

  static const String _isAutoKey = 'isLocalTimeAuto';
  static const String _manualZoneKey = 'manualTimeZoneId';

  bool get isLocalTimeAutomatic => _isLocalTimeAutomatic;
  String? get manualTimeZoneId => _manualTimeZoneId;
  // Helper to get the Location object for the manual timezone
  tz.Location? get manualLocation {
      if (_manualTimeZoneId != null) {
          try {
              return tz.getLocation(_manualTimeZoneId!);
          } catch (e) {
              // Handle error if ID is invalid (e.g., log it, default to UTC)
              debugPrint("Error getting location for $_manualTimeZoneId: $e");
              return tz.UTC; // Fallback safely
          }
      }
      return null;
  }


  TimeSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isLocalTimeAutomatic = prefs.getBool(_isAutoKey) ?? true; // Default to true
    _manualTimeZoneId = prefs.getString(_manualZoneKey);
    notifyListeners();
  }

  Future<void> setAutomaticLocalTime() async {
    if (!_isLocalTimeAutomatic) {
      _isLocalTimeAutomatic = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isAutoKey, true);
      notifyListeners();
    }
  }

  Future<void> setManualLocalTime(String timeZoneId) async {
    // Basic validation (optional, could check against tz.locations)
    try {
        tz.getLocation(timeZoneId); // Check if ID is valid
        _isLocalTimeAutomatic = false;
        _manualTimeZoneId = timeZoneId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isAutoKey, false);
        await prefs.setString(_manualZoneKey, timeZoneId);
        notifyListeners();
    } catch (e) {
        debugPrint("Invalid Timezone ID selected: $timeZoneId");
        // Optionally show an error to the user
    }
  }

  // Helper to get a display name for the current setting
  String get selectedLocalTimeZoneName {
    if (_isLocalTimeAutomatic) {
        // Get device's current time zone name (can be abbreviation like MDT)
        return DateTime.now().timeZoneName;
    } else if (_manualTimeZoneId != null) {
        // For manual, return the ID or potentially format it better later
        return _manualTimeZoneId!;
    } else {
        return "N/A"; // Should not happen if state is managed correctly
    }
  }
}