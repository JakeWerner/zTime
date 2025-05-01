// lib/screens/world_clock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../providers/world_clock_provider.dart';
import './timezone_selection_screen.dart'; // For adding new locations

// This widget displays the list of world clocks
class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> with AutomaticKeepAliveClientMixin { // Keep state
  Timer? _timer;

  // Formatters (consider moving to a shared place if used often)
  final DateFormat _timeFormatter = DateFormat('HH:mm'); // Maybe without seconds?
  final DateFormat _dateFormatter = DateFormat('MMM d, EEE'); // e.g., May 1, Thu

  // --- Add wantKeepAlive override ---
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Start timer to update displayed times periodically
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) { // Update every minute
      if (mounted) {
        setState(() {}); // Trigger rebuild to update times
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Function to navigate and add a new time zone
  Future<void> _navigateAddLocation(BuildContext context) async {
      final worldClockProvider = context.read<WorldClockProvider>(); // Use read for one-off action
      final selectedZone = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const TimeZoneSelectionScreen()), // Use your full list picker
      );
      if (selectedZone != null && context.mounted) {
        worldClockProvider.addLocation(selectedZone);
      }
  }

  // Function to format time for a specific location ID
  String _formatLocationTime(String locationId) {
    try {
       final location = tz.getLocation(locationId);
       final nowInLocation = tz.TZDateTime.now(location);
       return _timeFormatter.format(nowInLocation);
    } catch (e) {
        print("Error formatting time for $locationId: $e");
        return "--:--"; // Error indicator
    }
  }

    // Function to format date for a specific location ID
  String _formatLocationDate(String locationId) {
    try {
       final location = tz.getLocation(locationId);
       final nowInLocation = tz.TZDateTime.now(location);
       return _dateFormatter.format(nowInLocation);
    } catch (e) {
        print("Error formatting date for $locationId: $e");
        return "Error"; // Error indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for KeepAlive

    // Use Consumer to get the list and rebuild when it changes
    return Consumer<WorldClockProvider>(
      builder: (context, worldClock, child) {
        final locations = worldClock.selectedLocationIds;

        // Build the main list view
        return Scaffold( // Add Scaffold here since this is the content body
           // AppBar is handled by MainScreen, but we need a FAB or action button
           floatingActionButton: FloatingActionButton(
             onPressed: () => _navigateAddLocation(context),
             tooltip: 'Add Location',
             child: const Icon(Icons.add),
           ),
           body: locations.isEmpty
            ? const Center(child: Text('Add locations using the + button.'))
            : ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final locationId = locations[index];
                  final locationName = locationId.split('/').last.replaceAll('_', ' '); // Simple name extraction
                  final currentTime = _formatLocationTime(locationId);
                  final currentDate = _formatLocationDate(locationId);

                  return ListTile(
                    // Maybe add leading icon (e.g., based on time of day?)
                    title: Text(locationName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(locationId), // Show full ID in subtitle
                    trailing: Column( // Display time and date vertically
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                           Text(currentTime, style: Theme.of(context).textTheme.titleLarge),
                           Text(currentDate, style: Theme.of(context).textTheme.bodySmall),
                       ],
                    ),
                    // Optional: Add remove button
                    // Example using InkWell for larger tap area
                    leading: IconButton( // Simple remove button example
                       icon: Icon(Icons.remove_circle_outline, color: Colors.red.withOpacity(0.7)),
                       tooltip: 'Remove $locationName',
                       onPressed: () {
                          // Add confirmation dialog here ideally
                           context.read<WorldClockProvider>().removeLocation(locationId);
                       },
                    ),
                  );
                },
              ),
        );
      },
    );
  }
}