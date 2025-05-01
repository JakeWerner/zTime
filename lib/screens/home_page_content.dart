// lib/screens/home_page_content.dart
import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'package:intl/intl.dart'; // For formatting dates/times
import 'package:provider/provider.dart'; // For state management
import 'package:timezone/timezone.dart' as tz; // For timezone library functionalities
import 'package:flutter_timezone/flutter_timezone.dart';

// Import your other project files
import '../providers/time_settings_provider.dart';

class HomePageContent extends StatefulWidget {
  // Add key for state preservation if needed by parent (like MainScreen's list)
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

// Add the AutomaticKeepAliveClientMixin
class _HomePageContentState extends State<HomePageContent> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  DateTime? _displayUtcTime;
  DateTime? _displayLocalTime;
  String? _displayLocalTimeZoneAbbr;

  String? _autoDetectedTimeZoneId;
  bool _isFetchingTimeZone = false;

  // Formatters
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss');
  final DateFormat _dateFormatter = DateFormat('EEE, MMM d, yyyy'); // Example: Wed, Apr 30, 2025

  // --- Add wantKeepAlive override ---
  @override
  bool get wantKeepAlive => true; // Keep the state alive!

  @override
  void initState() {
    super.initState(); // Don't forget super call!
    print("HomePageContent: initState - Calling _fetchLocalTimeZone and _startTimer");
    _fetchLocalTimeZone();
    _startTimer();
  }

  Future<void> _fetchLocalTimeZone() async {
     // ... (Keep the _fetchLocalTimeZone implementation from previous step) ...
      if (_isFetchingTimeZone || _autoDetectedTimeZoneId != null) return;
      setState(() { _isFetchingTimeZone = true; });
      print("HomePageContent: Fetching local timezone ID...");
      try {
        final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
        print("HomePageContent: ---> Detected Timezone ID: $currentTimeZone <---");
        if (mounted) {
          setState(() {
            _autoDetectedTimeZoneId = currentTimeZone;
            _isFetchingTimeZone = false;
            _updateDisplayedTime();
          });
        }
      } catch (e) {
        print("HomePageContent: ERROR fetching timezone: $e");
        if (mounted) {
          setState(() {
            _autoDetectedTimeZoneId = tz.local.name;
            _isFetchingTimeZone = false;
            print("HomePageContent: Using tz.local.name as fallback: $_autoDetectedTimeZoneId");
            _updateDisplayedTime();
          });
        }
      }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies(); // Don't forget super call!
    print("HomePageContent: didChangeDependencies called.");
    if (_displayUtcTime == null && !_isFetchingTimeZone && _autoDetectedTimeZoneId != null) {
         print("HomePageContent: didChangeDependencies - Calling initial update (zone ready)");
        _updateDisplayedTime();
    } else if (_displayUtcTime == null) {
         print("HomePageContent: didChangeDependencies - Waiting for timezone fetch or already initialized");
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
     // ... (Keep the full _updateDisplayedTime implementation from previous step,
     //      using .timeZone.abbreviation) ...
      if (!mounted || _isFetchingTimeZone) return;
      final timeSettings = Provider.of<TimeSettingsProvider>(context, listen: false);
      final DateTime nowUtc = DateTime.now().toUtc();
      DateTime calculatedLocalTime;
      String calculatedLocalZoneIdentifier;
      try {
        if (timeSettings.isLocalTimeAutomatic) {
          if (_autoDetectedTimeZoneId != null) {
              final location = tz.getLocation(_autoDetectedTimeZoneId!);
              final tz.TZDateTime nowTzLocal = tz.TZDateTime.from(nowUtc, location); // Use .from or .now
              calculatedLocalTime = nowTzLocal;
              calculatedLocalZoneIdentifier = nowTzLocal.timeZone.abbreviation;
              if (calculatedLocalZoneIdentifier.isEmpty) {
                  calculatedLocalZoneIdentifier = nowTzLocal.timeZoneName;
              }
          } else {
              calculatedLocalTime = nowUtc.toLocal();
              calculatedLocalZoneIdentifier = calculatedLocalTime.timeZoneName;
          }
        } else {
          final location = timeSettings.manualLocation;
          if (location != null) {
              final tz.TZDateTime manualTzTime = tz.TZDateTime.from(nowUtc, location);
              calculatedLocalTime = manualTzTime;
              calculatedLocalZoneIdentifier = manualTzTime.timeZone.abbreviation;
              if (calculatedLocalZoneIdentifier.isEmpty) {
                   calculatedLocalZoneIdentifier = manualTzTime.timeZoneName;
              }
          } else {
              calculatedLocalTime = nowUtc.toLocal();
              calculatedLocalZoneIdentifier = calculatedLocalTime.timeZoneName;
          }
        }
      } catch (e) {
          print("HomePageContent: ***** ERROR during time calculation *****");
          print("HomePageContent: Error: $e");
          calculatedLocalTime = nowUtc.toLocal();
          calculatedLocalZoneIdentifier = calculatedLocalTime.timeZoneName;
      }
      final DateTime finalUtcTime = nowUtc;
      final DateTime finalLocalTime = calculatedLocalTime;
      final String finalLocalZoneName = calculatedLocalZoneIdentifier;
      if (mounted && (_displayUtcTime != finalUtcTime || _displayLocalTime != finalLocalTime || _displayLocalTimeZoneAbbr != finalLocalZoneName)) {
        setState(() {
           _displayUtcTime = finalUtcTime;
           _displayLocalTime = finalLocalTime;
           _displayLocalTimeZoneAbbr = finalLocalZoneName;
        });
      }
  }

  @override
  void dispose() {
    print("HomePageContent: dispose - Cancelling timer");
    _timer?.cancel();
    super.dispose(); // Don't forget super call!
  }

  @override
  Widget build(BuildContext context) {
    // --- Add super.build(context) for the mixin ---
    super.build(context);
    // --- End Add ---

    print("HomePageContent: build method running");

    // Handle initial loading state
    if (_displayUtcTime == null || _displayLocalTime == null || _displayLocalTimeZoneAbbr == null || _isFetchingTimeZone) {
      print("HomePageContent: build - Times/Zone null or fetching, showing loader");
      return const Center(child: CircularProgressIndicator());
    }

    print("HomePageContent: build - Displaying times ($_displayLocalTimeZoneAbbr)");
    // Main UI content - Return ONLY the body content
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
            // Current Context: Wed Apr 30, 2025 10:57 PM MDT
            Text('Local Time ($_displayLocalTimeZoneAbbr)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(_dateFormatter.format(_displayLocalTime!), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(_timeFormatter.format(_displayLocalTime!), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}