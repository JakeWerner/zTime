// lib/screens/timezone_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeZoneSelectionScreen extends StatefulWidget {
  const TimeZoneSelectionScreen({super.key});

  @override
  State<TimeZoneSelectionScreen> createState() => _TimeZoneSelectionScreenState();
}

class _TimeZoneSelectionScreenState extends State<TimeZoneSelectionScreen> {
  late final List<String> _allTimeZoneIds;
  List<String> _filteredTimeZoneIds = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load and sort all available time zone IDs
    _allTimeZoneIds = tz.timeZoneDatabase.locations.keys.toList();
    _allTimeZoneIds.sort(); // Sort alphabetically
    _filteredTimeZoneIds = _allTimeZoneIds; // Initially show all

    _searchController.addListener(_filterTimeZones);
  }

  void _filterTimeZones() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredTimeZoneIds = _allTimeZoneIds;
      });
    } else {
      setState(() {
        _filteredTimeZoneIds = _allTimeZoneIds
            .where((id) => id.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTimeZones);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Time Zone'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Time Zones',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTimeZoneIds.length,
              itemBuilder: (context, index) {
                final timeZoneId = _filteredTimeZoneIds[index];
                return ListTile(
                  title: Text(timeZoneId.replaceAll('_', ' ')), // Replace underscores for readability
                  onTap: () {
                    // Return the selected ID when tapped
                    Navigator.pop(context, timeZoneId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}