// lib/providers/world_clock_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection'; // For UnmodifiableListView

class WorldClockProvider with ChangeNotifier {
  List<String> _selectedLocationIds = []; // List of IANA IDs like "America/New_York"
  static const String _locationsKey = 'worldClockLocations';

  // Public getter for the list - prevents modifying the list directly from outside
  UnmodifiableListView<String> get selectedLocationIds => UnmodifiableListView(_selectedLocationIds);

  WorldClockProvider() {
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load the list, default to empty list if not found
      _selectedLocationIds = prefs.getStringList(_locationsKey) ?? [];
      print("WorldClockProvider: Loaded locations: $_selectedLocationIds");
      notifyListeners(); // Notify widgets after loading
    } catch (e) {
      print("WorldClockProvider: Error loading locations: $e");
    }
  }

  Future<void> _saveLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_locationsKey, _selectedLocationIds);
       print("WorldClockProvider: Saved locations: $_selectedLocationIds");
    } catch (e) {
        print("WorldClockProvider: Error saving locations: $e");
    }
  }

  void addLocation(String locationId) {
    if (!_selectedLocationIds.contains(locationId)) {
      _selectedLocationIds.add(locationId);
      _saveLocations(); // Save after modification
      notifyListeners(); // Update UI
       print("WorldClockProvider: Added $locationId");
    } else {
       print("WorldClockProvider: Location $locationId already exists.");
    }
  }

  void removeLocation(String locationId) {
    if (_selectedLocationIds.contains(locationId)) {
      _selectedLocationIds.remove(locationId);
      _saveLocations();
      notifyListeners();
       print("WorldClockProvider: Removed $locationId");
    }
  }

  // Optional: Add reordering logic if using ReorderableListView later
  void reorderLocations(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }
    final String item = _selectedLocationIds.removeAt(oldIndex);
    _selectedLocationIds.insert(newIndex, item);
    _saveLocations();
    notifyListeners();
     print("WorldClockProvider: Reordered locations.");
  }
}