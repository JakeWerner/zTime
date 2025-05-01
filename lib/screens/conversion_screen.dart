// lib/screens/conversion_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import '../providers/time_settings_provider.dart'; // Adjust path as needed

class ConversionScreen extends StatefulWidget {
  const ConversionScreen({super.key});

  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  // --- State variables ---
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _sourceTimeZoneId; // Stores the LOCATION ID (e.g., "America/Denver")
  String? _targetTimeZoneId; // Stores the LOCATION ID (e.g., "Europe/London")
  tz.TZDateTime? _convertedDateTime; // Stores the result

  // Store initial defaults for resetting
  String? _initialSourceTimeZoneId;
  String? _initialTargetTimeZoneId;

  // --- Curated Time Zone Data ---
  // Define a curated map of display names to location IDs
  // Current Context: Wed, Apr 30, 2025 10:02 PM MDT (America/Denver is UTC-6)
  // UTC Equivalent: Thu, May 1, 2025 04:02 AM UTC
  final Map<String, String> commonTimeZones = {
    // North America
    'Pacific Time (PT)': 'America/Los_Angeles',      // UTC-08:00 / UTC-07:00 (PST/PDT)
    'Mountain Time (MT)': 'America/Denver',          // UTC-07:00 / UTC-06:00 (MST/MDT)
    'Mountain Time - Arizona': 'America/Phoenix',    // UTC-07:00 (No DST)
    'Central Time (CT)': 'America/Chicago',          // UTC-06:00 / UTC-05:00 (CST/CDT)
    'Eastern Time (ET)': 'America/New_York',         // UTC-05:00 / UTC-04:00 (EST/EDT)
    'Alaska Time (AKT)': 'America/Anchorage',        // UTC-09:00 / UTC-08:00 (AKST/AKDT)
    'Hawaii Time (HT)': 'Pacific/Honolulu',          // UTC-10:00 (No DST)
    'Atlantic Time (AT)': 'America/Halifax',         // UTC-04:00 / UTC-03:00 (AST/ADT)
    'Newfoundland Time (NT)': 'America/St_Johns',    // UTC-03:30 / UTC-02:30 (NST/NDT)
    // Europe
    'UTC / GMT': 'UTC',                                // UTC+00:00
    'London (GMT/BST)': 'Europe/London',              // UTC+00:00 / UTC+01:00
    'Dublin (GMT/IST)': 'Europe/Dublin',              // UTC+00:00 / UTC+01:00
    'Paris (CET/CEST)': 'Europe/Paris',               // UTC+01:00 / UTC+02:00
    'Berlin (CET/CEST)': 'Europe/Berlin',             // UTC+01:00 / UTC+02:00
    'Rome (CET/CEST)': 'Europe/Rome',                 // UTC+01:00 / UTC+02:00
    'Athens (EET/EEST)': 'Europe/Athens',             // UTC+02:00 / UTC+03:00
    'Moscow Standard (MSK)': 'Europe/Moscow',         // UTC+03:00 (No DST)
    // Africa / Middle East
     'Johannesburg (SAST)': 'Africa/Johannesburg',     // UTC+02:00 (No DST)
    'Dubai (GST)': 'Asia/Dubai',                      // UTC+04:00 (No DST)
    // Asia / Pacific
    'India Standard (IST)': 'Asia/Kolkata',           // UTC+05:30 (No DST)
    'Bangkok (ICT)': 'Asia/Bangkok',                  // UTC+07:00 (No DST)
    'Singapore (SGT)': 'Asia/Singapore',              // UTC+08:00 (No DST)
    'Hong Kong (HKT)': 'Asia/Hong_Kong',              // UTC+08:00 (No DST)
    'China Standard (CST)': 'Asia/Shanghai',          // UTC+08:00 (No DST)
    'Japan Standard (JST)': 'Asia/Tokyo',             // UTC+09:00 (No DST)
    'Korea Standard (KST)': 'Asia/Seoul',             // UTC+09:00 (No DST)
    'Perth (AWST)': 'Australia/Perth',                // UTC+08:00 (No DST)
    'Adelaide (ACST/ACDT)': 'Australia/Adelaide',     // UTC+09:30 / UTC+10:30
    'Brisbane (AEST)': 'Australia/Brisbane',          // UTC+10:00 (No DST)
    'Sydney (AEST/AEDT)': 'Australia/Sydney',         // UTC+10:00 / UTC+11:00
    'Auckland (NZST/NZDT)': 'Pacific/Auckland',       // UTC+12:00 / UTC+13:00
     // South America
    'Buenos Aires (ART)': 'America/Argentina/Buenos_Aires', // UTC-03:00 (No DST currently)
    'Sao Paulo (BRT/BRST)': 'America/Sao_Paulo',      // UTC-03:00 / UTC-02:00 (DST varies historically)
  };

  // Derived lists/maps
  late final List<String> _commonTimeZoneIds;
  late final Map<String, String> _idToDisplayName;

  // --- Formatters ---
  final DateFormat _dateFormatter = DateFormat('MM-dd-yyyy');
  final DateFormat _resultDateTimeFormatter = DateFormat('MM-dd-yyyy HH:mm:ss Z'); // Includes offset

  @override
  void initState() {
    super.initState();
    print("ConversionScreen: initState START");
    try {
      // --- FIX: Initialize _idToDisplayName FIRST ---
      _idToDisplayName = commonTimeZones.map((key, value) => MapEntry(value, key));
      print("ConversionScreen: initState - Created reverse map");

      // --- Now initialize _commonTimeZoneIds (which uses _getDisplayName -> _idToDisplayName) ---
      _commonTimeZoneIds = commonTimeZones.values.toList()
        ..sort((a, b) => _getDisplayName(a, fallbackToId: true)
            .compareTo(_getDisplayName(b, fallbackToId: true))); // Sort by display name
      print("ConversionScreen: initState - Sorted IDs");
      // --- End Fix ---

      // Determine and store initial defaults
      final initialProvider = Provider.of<TimeSettingsProvider>(context, listen: false);
      print("ConversionScreen: initState - Got provider");
      String defaultSourceId = 'America/Denver'; // Default relevant to user location
      if (!initialProvider.isLocalTimeAutomatic && initialProvider.manualTimeZoneId != null) {
        if (_commonTimeZoneIds.contains(initialProvider.manualTimeZoneId!)){
             defaultSourceId = initialProvider.manualTimeZoneId!;
        }
      } else {
        String deviceLocalName = tz.local.name;
        if (_commonTimeZoneIds.contains(deviceLocalName)) {
             defaultSourceId = deviceLocalName;
        }
      }
      // Ensure default is in our curated list, otherwise fallback
      _initialSourceTimeZoneId = _commonTimeZoneIds.contains(defaultSourceId) ? defaultSourceId : 'America/Denver';
      _initialTargetTimeZoneId = 'UTC'; // Default target
      print("ConversionScreen: initState - Determined initial IDs: $_initialSourceTimeZoneId, $_initialTargetTimeZoneId");

      // Set initial state values
      _sourceTimeZoneId = _initialSourceTimeZoneId;
      _targetTimeZoneId = _initialTargetTimeZoneId;
      print("ConversionScreen: initState - Set state IDs");

    } catch (e, stackTrace) {
       print("ConversionScreen: ***** ERROR in initState *****");
       print(e);
       print(stackTrace);
       // Handle error state appropriately if needed, maybe set default IDs here too
       _idToDisplayName ??= {}; // Ensure maps/lists are not null even on error
       _commonTimeZoneIds ??= [];
       _sourceTimeZoneId ??= 'UTC';
       _targetTimeZoneId ??= 'UTC';
    }
    print("ConversionScreen: initState END");
  }

  // Helper to display the common name
  String _getDisplayName(String? id, {bool fallbackToId = false}) {
      if (id == null) return 'Select Time Zone';
      // Return common name from map, or the ID itself as fallback if not found
      return _idToDisplayName[id] ?? (fallbackToId ? id : 'Unknown Zone');
  }

  // --- Input Handlers ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Allow reasonable range
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _convertedDateTime = null; // Reset result when input changes
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
         _convertedDateTime = null; // Reset result when input changes
      });
    }
  }

  // --- Action Handlers ---
  void _performConversion() {
    if (_sourceTimeZoneId == null || _targetTimeZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and target time zones.')),
      );
      return;
    }
    // Add check to prevent converting same zone to itself
    if (_sourceTimeZoneId == _targetTimeZoneId) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Source and target zones are the same.')),
         );
         // Optionally set result to the input time directly
         // setState(() { _convertedDateTime = sourceDateTime; });
         return;
    }

    print("Performing conversion from $_sourceTimeZoneId to $_targetTimeZoneId");
    try {
      final sourceLocation = tz.getLocation(_sourceTimeZoneId!);
      final targetLocation = tz.getLocation(_targetTimeZoneId!);

      // Create TZDateTime in the SOURCE location first
      final sourceDateTime = tz.TZDateTime(
        sourceLocation,
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      print("Source DateTime interpreted as: ${sourceDateTime.toString()}");

      // Convert to the target location
      final resultDateTime = tz.TZDateTime.from(sourceDateTime, targetLocation);
      print("Conversion Result: ${resultDateTime.toString()}");

      setState(() {
        _convertedDateTime = resultDateTime;
      });
    } catch (e) {
       debugPrint("Time conversion error: $e");
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during conversion: $e')),
      );
       setState(() {
        _convertedDateTime = null; // Clear result on error
      });
    }
  }

  void _swapTimeZones() {
    if (_sourceTimeZoneId == null || _targetTimeZoneId == null) return;
    print("Swapping zones: $_sourceTimeZoneId <-> $_targetTimeZoneId");
    setState(() {
      final String? temp = _sourceTimeZoneId;
      _sourceTimeZoneId = _targetTimeZoneId;
      _targetTimeZoneId = temp;
      _convertedDateTime = null; // Reset result after swapping
    });
  }

  void _clearConversion() {
     print("Clearing conversion fields.");
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      // Reset to initial defaults determined in initState
      _sourceTimeZoneId = _initialSourceTimeZoneId;
      _targetTimeZoneId = _initialTargetTimeZoneId;
      _convertedDateTime = null; // Clear result
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure defaults are set if somehow null (should be handled by initState)
    _sourceTimeZoneId ??= _initialSourceTimeZoneId;
    _targetTimeZoneId ??= _initialTargetTimeZoneId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Fields',
            onPressed: _clearConversion,
          ),
        ],
      ),
      body: SingleChildScrollView( // Allow scrolling on small screens
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
          children: [
            // --- Date Input ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(_dateFormatter.format(_selectedDate)),
              trailing: const Icon(Icons.edit_calendar_outlined), // Icon indicating action
              onTap: () => _pickDate(context),
            ),
            const Divider(),

            // --- Time Input ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)), // Use locale-aware formatting
              trailing: const Icon(Icons.edit_outlined), // Icon indicating action
              onTap: () => _pickTime(context),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // --- Source Time Zone ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _sourceTimeZoneId, // Uses the ID as value
                decoration: const InputDecoration(
                  labelText: 'From Time Zone',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                ),
                items: _commonTimeZoneIds.map((id) { // Iterate curated IDs
                  return DropdownMenuItem(
                    value: id, // Value remains the ID
                    child: Text(
                      _getDisplayName(id), // Display user-friendly name
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sourceTimeZoneId = newValue; // Store selected ID
                    _convertedDateTime = null;
                  });
                },
                isExpanded: true,
              ),
            ),

            // --- Swap Button ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0), // Reduced padding
              child: IconButton(
                icon: const Icon(Icons.swap_vert), // Vertical swap icon
                iconSize: 30.0,
                tooltip: 'Swap Time Zones',
                onPressed: _swapTimeZones,
                color: Theme.of(context).colorScheme.primary, // Use theme color
              ),
            ),
            // --- End Swap Button ---

            // --- Target Time Zone ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _targetTimeZoneId, // Uses the ID as value
                 decoration: const InputDecoration(
                   labelText: 'To Time Zone',
                   border: OutlineInputBorder(),
                   contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                 ),
                items: _commonTimeZoneIds.map((id) { // Iterate curated IDs
                  return DropdownMenuItem(
                    value: id, // Value remains the ID
                    child: Text(
                      _getDisplayName(id), // Display user-friendly name
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _targetTimeZoneId = newValue; // Store selected ID
                    _convertedDateTime = null;
                  });
                },
                 isExpanded: true,
              ),
            ),
            const SizedBox(height: 20),

            // --- Convert Button ---
            ElevatedButton.icon( // Use icon for better visual cue
              icon: const Icon(Icons.sync_alt),
              label: const Text('Convert'),
              onPressed: _performConversion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),

            // --- Result Display ---
            AnimatedOpacity(
              opacity: _convertedDateTime != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400), // Slightly longer fade
              child: _convertedDateTime == null
                  ? const SizedBox(height: 50) // Reserve space even when hidden
                  : Container( // Add some visual distinction for the result
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8.0)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                           Text(
                            'Converted Time:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            // Formatter includes offset, e.g., 2025-05-01 04:02:49 +0000
                            _resultDateTimeFormatter.format(_convertedDateTime!),
                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                             textAlign: TextAlign.center,
                          ),
                           Text(
                            // Display the user-friendly name of the target zone
                            '(${_getDisplayName(_targetTimeZoneId)})', // e.g., (London (GMT/BST))
                             style: Theme.of(context).textTheme.bodyMedium,
                             textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}