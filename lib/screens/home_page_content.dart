// lib/screens/home_page_content.dart
import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'package:intl/intl.dart'; // For formatting dates/times
import 'package:provider/provider.dart'; // For state management
import 'package:timezone/timezone.dart' as tz; // For timezone library functionalities
// Removed: import 'package:flutter_timezone/flutter_timezone.dart';

// Import your other project files
import '../providers/time_settings_provider.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  Timer? _timer;
  DateTime? _displayUtcTime;
  DateTime? _displayLocalTime;
  String? _displayLocalTimeZoneIdentifier; // Can be name or abbreviation

  // Removed: _autoDetectedTimeZoneId state variable
  // Removed: _isFetchingTimeZone state variable

  // Formatters
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss');
  final DateFormat _dateFormatter = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    print("HomePageContent: initState - Calling _startTimer");
    // Removed: Call to _fetchLocalTimeZone()
    _startTimer();
    // Initial update triggered by didChangeDependencies or first timer tick
  }

  // Removed: _fetchLocalTimeZone() function

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("HomePageContent: didChangeDependencies called.");
    // Trigger initial update if needed
    if (_displayUtcTime == null) {
      print("HomePageContent: didChangeDependencies - Calling initial _updateDisplayedTime");
      _updateDisplayedTime();
    }
  }

  void _startTimer() {
     print("HomePageContent: _startTimer called");
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _updateDisplayedTime();
    });
  }

  void _updateDisplayedTime() {
    if (!mounted) return;

    // print("HomePageContent: ---> Entering _updateDisplayedTime"); // Keep for debug if needed

    final timeSettings = Provider.of<TimeSettingsProvider>(context, listen: false);
    final DateTime nowUtc = DateTime.now().toUtc();

    DateTime calculatedLocalTime;
    String calculatedLocalZoneIdentifier;

    try {
      if (timeSettings.isLocalTimeAutomatic) {
        // --- AUTOMATIC MODE (REVERTED to simple version) ---
        //print("HomePageContent: Using Automatic Mode (Standard DateTime)");
        final DateTime nowLocal = DateTime.now();
        calculatedLocalTime = nowLocal;
        // Use the standard timeZoneName provided by DateTime
        calculatedLocalZoneIdentifier = nowLocal.timeZoneName; // e.g., "Mountain Daylight Time"
        //print("HomePageContent: Identifier (Auto): '$calculatedLocalZoneIdentifier'");
        // --- END REVERT ---

      } else {
        // --- MANUAL MODE --- (Uses TZDateTime and should provide abbreviation)
        final location = timeSettings.manualLocation;
        // print("HomePageContent: Using Manual Location: ${location?.name}");
        if (location != null) {
            final tz.TZDateTime manualTzTime = tz.TZDateTime.from(nowUtc, location);
            calculatedLocalTime = manualTzTime;
            // Use the abbreviation from TZDateTime directly
            calculatedLocalZoneIdentifier = manualTzTime.timeZone.abbreviation;
            // print("DEBUG: TZDateTime timeZone.abbreviation (Manual): '$calculatedLocalZoneIdentifier'");

            // Fallback if abbreviation property is empty
            if (calculatedLocalZoneIdentifier.isEmpty) {
                 // print("DEBUG: TZDateTime abbreviation empty (Manual), using timeZoneName fallback.");
                 calculatedLocalZoneIdentifier = manualTzTime.timeZoneName; // Fallback to ID/Name
            }
        } else {
            // Fallback for manual mode if location is invalid/not set
            print("HomePageContent: Manual location invalid, using standard fallback.");
            calculatedLocalTime = nowUtc.toLocal();
            calculatedLocalZoneIdentifier = calculatedLocalTime.timeZoneName;
        }
      }
    } catch (e, stackTrace) {
        print("HomePageContent: ***** ERROR during time calculation *****");
        print("HomePageContent: Error: $e");
        // Fallback safely
        calculatedLocalTime = nowUtc.toLocal();
        calculatedLocalZoneIdentifier = calculatedLocalTime.timeZoneName;
    }

    // Prepare final values for setState
    final DateTime finalUtcTime = nowUtc;
    final DateTime finalLocalTime = calculatedLocalTime;
    final String finalLocalZoneName = calculatedLocalZoneIdentifier;

    // Update state only if values changed
    if (_displayUtcTime != finalUtcTime ||
        _displayLocalTime != finalLocalTime ||
        _displayLocalTimeZoneIdentifier != finalLocalZoneName) { // Updated variable name
      setState(() {
         _displayUtcTime = finalUtcTime;
         _displayLocalTime = finalLocalTime;
         _displayLocalTimeZoneIdentifier = finalLocalZoneName; // Updated variable name
         // print("HomePageContent: setState completed with new values.");
      });
    }
     // print("HomePageContent: ---> Exiting _updateDisplayedTime");
  }

  @override
  void dispose() {
    print("HomePageContent: dispose - Cancelling timer");
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     // print("HomePageContent: build method running");

    // Handle initial loading state (simpler now, no async fetch)
    if (_displayUtcTime == null || _displayLocalTime == null || _displayLocalTimeZoneIdentifier == null) {
      // print("HomePageContent: build - Times/Zone null, showing loader");
      return const Center(child: CircularProgressIndicator());
    }

    // print("HomePageContent: build - Displaying times ($_displayLocalTimeZoneIdentifier)");
    // Main UI content
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Zulu Time Display
            const Text('Zulu Time (UTC)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(_dateFormatter.format(_displayUtcTime!), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text('${_timeFormatter.format(_displayUtcTime!)} Z', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 40),

            // Local Time Display
            // Will show name like "Mountain Daylight Time" in Auto, Abbr like "PDT" in Manual
            Text('Local Time ($_displayLocalTimeZoneIdentifier)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(_dateFormatter.format(_displayLocalTime!), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(_timeFormatter.format(_displayLocalTime!), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}