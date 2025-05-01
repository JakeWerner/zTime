// lib/screens/world_clock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // For Timer
import 'package:intl/intl.dart'; // For formatting
import 'package:timezone/timezone.dart' as tz; // For time zones

// Import other necessary files
import '../providers/world_clock_provider.dart';
import './timezone_selection_screen.dart'; // For adding new locations

// This widget displays the list of world clocks and handles editing
class WorldClockScreen extends StatefulWidget {
  // Add key for state preservation with AutomaticKeepAliveClientMixin
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  bool _isEditMode = false; // State variable to track edit mode

  // Formatters (can be moved to a central location if used elsewhere)
  // Current Context: Thursday, May 1, 2025 09:17 AM MDT (UTC-6)
  final DateFormat _timeFormatter = DateFormat('HH:mm'); // e.g., 09:17
  final DateFormat _dateFormatter = DateFormat('MMM d, EEE'); // e.g., May 1, Thu

  // --- State Preservation ---
  @override
  bool get wantKeepAlive => true; // Keep state when switching pages

  @override
  void initState() {
    super.initState();
    print("WorldClockScreen: initState");
    // Start timer to update displayed times periodically (e.g., every minute)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        // Trigger rebuild to update times - simple way, redraws all visible items
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    print("WorldClockScreen: dispose - Cancelling timer");
    _timer?.cancel();
    super.dispose();
  }

  // --- Actions ---
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
     print("WorldClockScreen: Toggled Edit Mode to $_isEditMode");
  }

  Future<void> _navigateAddLocation(BuildContext context) async {
      // Use read here as it's a one-off action triggered by user
      final worldClockProvider = context.read<WorldClockProvider>();
      print("WorldClockScreen: Navigating to add location.");
      final selectedZone = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const TimeZoneSelectionScreen()), // Use your full list picker
      );
      if (selectedZone != null && context.mounted) {
         print("WorldClockScreen: Adding location: $selectedZone");
        worldClockProvider.addLocation(selectedZone);
      } else {
         print("WorldClockScreen: No location selected or widget unmounted.");
      }
  }

  // --- Time Formatting Helpers ---
  String _formatLocationTime(String locationId) {
    try {
       final location = tz.getLocation(locationId);
       // Use tz.TZDateTime.now() to get current time in that location
       final nowInLocation = tz.TZDateTime.now(location);
       return _timeFormatter.format(nowInLocation);
    } catch (e) {
        // Handle cases where location ID might be invalid (shouldn't happen if added via picker)
        print("Error formatting time for $locationId: $e");
        return "--:--";
    }
  }

  String _formatLocationDate(String locationId) {
    try {
       final location = tz.getLocation(locationId);
       final nowInLocation = tz.TZDateTime.now(location);
       return _dateFormatter.format(nowInLocation);
    } catch (e) {
        print("Error formatting date for $locationId: $e");
        return "Error";
    }
  }

  // --- List Item Builder Helper ---
  Widget _buildWorldClockTile(BuildContext context, String locationId, int index, {required bool isEditMode, Key? key}) {
    // Extract a more readable name (e.g., "Denver" from "America/Denver")
    final locationName = locationId.split('/').last.replaceAll('_', ' ');
    final currentTime = _formatLocationTime(locationId);
    final currentDate = _formatLocationDate(locationId);
    // Access provider without listening for remove action
    final worldClockProvider = context.read<WorldClockProvider>();

    return ListTile(
      key: key, // Key is required by ReorderableListView.builder
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // Show remove button only in edit mode
      leading: isEditMode
          ? IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red.withOpacity(0.9)),
              tooltip: 'Remove $locationName',
              onPressed: () {
                // Optional: Add a confirmation dialog before removing
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('Remove Location'),
                          content: Text('Are you sure you want to remove $locationName ($locationId)?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Close dialog
                                  worldClockProvider.removeLocation(locationId); // Perform remove
                                },
                                child: const Text('Remove', style: TextStyle(color: Colors.red))),
                          ],
                        ));
              },
            )
          : null, // No leading icon in normal mode, or maybe Icon(Icons.public)
      title: Text(locationName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
      subtitle: Text(locationId, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
      trailing: Row( // Keep time and potential drag handle together
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currentTime, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500)), // Make time prominent
              Text(currentDate, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          // Show drag handle only in edit mode - wrap with Listener to enable drag
           if (isEditMode)
             ReorderableDragStartListener(
               index: index, // The index of the item in the list
               child: const Padding(
                 padding: EdgeInsets.only(left: 16.0), // Space it out from time
                 child: Icon(Icons.drag_handle),
               ),
             ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Necessary call for AutomaticKeepAliveClientMixin
    super.build(context);
    print("WorldClockScreen: build method running (Edit Mode: $_isEditMode)");

    // Use Consumer to get the latest list of locations and rebuild when it changes
    return Scaffold( // This screen content needs its own Scaffold for the FAB
       body: Column(
        children: [
          // --- Edit Button Toggle Area ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(_isEditMode ? Icons.check_circle_outline : Icons.edit_outlined, size: 20),
                  label: Text(_isEditMode ? 'Done' : 'Edit List'),
                  onPressed: _toggleEditMode,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1), // Separator
          // --- End Edit Button ---

          // --- List Area ---
          Expanded( // Make the list take remaining space
            child: Consumer<WorldClockProvider>(
              builder: (context, worldClock, child) {
                final locations = worldClock.selectedLocationIds;

                if (locations.isEmpty) {
                  return const Center(child: Text('Add locations using the + button below.'));
                }

                // --- Conditional List View ---
                if (_isEditMode) {
                  // --- EDIT MODE: Reorderable List ---
                  print("WorldClockScreen: Building ReorderableListView");
                  return ReorderableListView.builder(
                    padding: EdgeInsets.zero, // Remove default padding if needed
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final locationId = locations[index];
                      // Key is crucial for ReorderableListView
                      return _buildWorldClockTile(context, locationId, index, isEditMode: true, key: ValueKey(locationId));
                    },
                    // Callback when item is dragged and dropped
                    onReorder: (int oldIndex, int newIndex) {
                       print("WorldClockScreen: Reordering item from $oldIndex to $newIndex");
                       // Use read as this is a one-off action
                       context.read<WorldClockProvider>().reorderLocations(oldIndex, newIndex);
                    },
                  );
                } else {
                  // --- NORMAL MODE: Standard List ---
                   print("WorldClockScreen: Building ListView");
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final locationId = locations[index];
                       // Use the same helper, indicate not in edit mode
                      return _buildWorldClockTile(context, locationId, index, isEditMode: false);
                    },
                  );
                }
                // --- End Conditional List View ---
              },
            ),
          ),
        ],
      ),
       // FAB for adding new locations - part of this screen's Scaffold
       floatingActionButton: FloatingActionButton(
         onPressed: () => _navigateAddLocation(context),
         tooltip: 'Add Location',
         child: const Icon(Icons.add),
       ),
    ); // End Scaffold
  }
} // End of _WorldClockScreenState