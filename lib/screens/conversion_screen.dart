// lib/screens/conversion_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import '../providers/time_settings_provider.dart';

class ConversionScreen extends StatefulWidget {
  // Add key for state preservation
  const ConversionScreen({super.key});

  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

// Add the AutomaticKeepAliveClientMixin
class _ConversionScreenState extends State<ConversionScreen> with AutomaticKeepAliveClientMixin {
  // --- State variables ---
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _sourceTimeZoneId;
  String? _targetTimeZoneId;
  tz.TZDateTime? _convertedDateTime;

  String? _initialSourceTimeZoneId;
  String? _initialTargetTimeZoneId;

  // --- Curated Time Zone Data ---
  // Using late final is fine here as they are initialized from a final map
  late final Map<String, String> commonTimeZones;
  late final List<String> _commonTimeZoneIds;
  late final Map<String, String> _idToDisplayName;

  // --- Formatters ---
  final DateFormat _dateFormatter = DateFormat('MM-dd-yyyy');
  final DateFormat _resultDateTimeFormatter = DateFormat('MM-dd-yyyy HH:mm Z');

  // --- Add wantKeepAlive override ---
  @override
  bool get wantKeepAlive => true; // Keep the state alive!

  @override
  void initState() {
    super.initState(); // Don't forget super call!
    print("ConversionScreen: initState START");

    // Initialize the map directly here or reference from a constants file
    commonTimeZones = {
      'Pacific Time (PT)': 'America/Los_Angeles',
      'Mountain Time (MT)': 'America/Denver',
      'Central Time (CT)': 'America/Chicago',
      'Eastern Time (ET)': 'America/New_York',
      'Alaska Time (AKT)': 'America/Anchorage',
      'Hawaii Time (HT)': 'Pacific/Honolulu',
      'UTC / GMT': 'UTC',
      'London (GMT/BST)': 'Europe/London',
      'Paris (CET/CEST)': 'Europe/Paris',
      'Berlin (CET/CEST)': 'Europe/Berlin',
      'Athens (EET/EEST)': 'Europe/Athens',
      'India Standard (IST)': 'Asia/Kolkata',
      'Japan Standard (JST)': 'Asia/Tokyo',
      'Sydney (AEST/AEDT)': 'Australia/Sydney',
      // Add more...
    };

    try {
      // Initialize derived lists/maps first
      _idToDisplayName = commonTimeZones.map((key, value) => MapEntry(value, key));
      print("ConversionScreen: initState - Created reverse map");

      _commonTimeZoneIds = commonTimeZones.values.toList()
        ..sort((a, b) => _getDisplayName(a, fallbackToId: true)
            .compareTo(_getDisplayName(b, fallbackToId: true)));
      print("ConversionScreen: initState - Sorted IDs");

      // Determine and store initial defaults
      final initialProvider = Provider.of<TimeSettingsProvider>(context, listen: false);
      print("ConversionScreen: initState - Got provider");
      String defaultSourceId = 'America/Denver';
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
      _initialSourceTimeZoneId = _commonTimeZoneIds.contains(defaultSourceId) ? defaultSourceId : 'America/Denver';
      _initialTargetTimeZoneId = 'UTC';
      print("ConversionScreen: initState - Determined initial IDs: $_initialSourceTimeZoneId, $_initialTargetTimeZoneId");

      // Set initial state values
      _sourceTimeZoneId = _initialSourceTimeZoneId;
      _targetTimeZoneId = _initialTargetTimeZoneId;
      print("ConversionScreen: initState - Set state IDs");

    } catch (e, stackTrace) {
       print("ConversionScreen: ***** ERROR in initState *****");
       print(e);
       print(stackTrace);
       // Ensure defaults on error
       _idToDisplayName ??= {};
       _commonTimeZoneIds ??= ['UTC'];
       _sourceTimeZoneId ??= 'UTC';
       _targetTimeZoneId ??= 'UTC';
    }
    print("ConversionScreen: initState END");
  }

  // Helper to display the common name
  String _getDisplayName(String? id, {bool fallbackToId = false}) {
      if (id == null) return 'Select Time Zone';
      return _idToDisplayName[id] ?? (fallbackToId ? id : 'Unknown Zone');
  }

  // --- Input Handlers (_pickDate, _pickTime) ---
  // Keep these methods as they were in the previous full file example

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(2000), lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; _convertedDateTime = null; });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() { _selectedTime = picked; _convertedDateTime = null; });
    }
  }


  // --- Action Handlers (_performConversion, _swapTimeZones, _clearConversion) ---
   // Keep these methods as they were in the previous full file example

  void _performConversion() {
     if (_sourceTimeZoneId == null || _targetTimeZoneId == null) { /* ... */ return; }
     if (_sourceTimeZoneId == _targetTimeZoneId) { /* ... */ return; }
     print("Performing conversion from $_sourceTimeZoneId to $_targetTimeZoneId");
     try {
       final sourceLocation = tz.getLocation(_sourceTimeZoneId!);
       final targetLocation = tz.getLocation(_targetTimeZoneId!);
       final sourceDateTime = tz.TZDateTime(sourceLocation, _selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
       print("Source DateTime interpreted as: ${sourceDateTime.toString()}");
       final resultDateTime = tz.TZDateTime.from(sourceDateTime, targetLocation);
       print("Conversion Result: ${resultDateTime.toString()}");
       setState(() { _convertedDateTime = resultDateTime; });
     } catch (e) {
        debugPrint("Time conversion error: $e");
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error during conversion: $e')), );
        setState(() { _convertedDateTime = null; });
     }
  }

  void _swapTimeZones() {
    if (_sourceTimeZoneId == null || _targetTimeZoneId == null) return;
    print("Swapping zones: $_sourceTimeZoneId <-> $_targetTimeZoneId");
    setState(() {
      final String? temp = _sourceTimeZoneId;
      _sourceTimeZoneId = _targetTimeZoneId;
      _targetTimeZoneId = temp;
      _convertedDateTime = null;
    });
  }

  void _clearConversion() {
     print("Clearing conversion fields.");
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _sourceTimeZoneId = _initialSourceTimeZoneId;
      _targetTimeZoneId = _initialTargetTimeZoneId;
      _convertedDateTime = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    // --- Add super.build(context) for the mixin ---
    super.build(context);
    // --- End Add ---

    // Ensure defaults are set if somehow null
    _sourceTimeZoneId ??= _initialSourceTimeZoneId;
    _targetTimeZoneId ??= _initialTargetTimeZoneId;

    // Return ONLY the body content (no Scaffold/AppBar here)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Date Input ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(_dateFormatter.format(_selectedDate)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDate(context),
          ),
          const Divider(),

          // --- Time Input ---
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            subtitle: Text(_selectedTime.format(context)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickTime(context),
          ),
          const Divider(),
          const SizedBox(height: 10),

          // --- Source Time Zone ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>( /* ... Dropdown config ... */
              value: _sourceTimeZoneId,
              decoration: const InputDecoration(labelText: 'From Time Zone', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),),
              items: _commonTimeZoneIds.map((id) => DropdownMenuItem(value: id, child: Text(_getDisplayName(id), overflow: TextOverflow.ellipsis,))).toList(),
              onChanged: (String? newValue) { setState(() { _sourceTimeZoneId = newValue; _convertedDateTime = null; }); },
              isExpanded: true,
            ),
          ),

          // --- Swap Button ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: IconButton( /* ... Swap Button config ... */
              icon: const Icon(Icons.swap_vert), iconSize: 30.0, tooltip: 'Swap Time Zones',
              onPressed: _swapTimeZones, color: Theme.of(context).colorScheme.primary,
            ),
          ),

          // --- Target Time Zone ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>( /* ... Dropdown config ... */
              value: _targetTimeZoneId,
              decoration: const InputDecoration(labelText: 'To Time Zone', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),),
              items: _commonTimeZoneIds.map((id) => DropdownMenuItem(value: id, child: Text(_getDisplayName(id), overflow: TextOverflow.ellipsis,))).toList(),
              onChanged: (String? newValue) { setState(() { _targetTimeZoneId = newValue; _convertedDateTime = null; }); },
              isExpanded: true,
            ),
          ),
          const SizedBox(height: 20),

          // --- Convert Button ---
          ElevatedButton.icon( /* ... Convert Button config ... */
            icon: const Icon(Icons.sync_alt), label: const Text('Convert'),
            onPressed: _performConversion,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16),),
          ),
          const SizedBox(height: 30),

          // --- Result Display ---
          AnimatedOpacity( /* ... Result Display config ... */
            opacity: _convertedDateTime != null ? 1.0 : 0.0, duration: const Duration(milliseconds: 400),
            child: _convertedDateTime == null ? const SizedBox(height: 50) : Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(8.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Text('Converted Time:', style: Theme.of(context).textTheme.titleMedium,),
                  const SizedBox(height: 10),
                  Text(_resultDateTimeFormatter.format(_convertedDateTime!), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                   Text('${_getDisplayName(_targetTimeZoneId)}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center,),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}