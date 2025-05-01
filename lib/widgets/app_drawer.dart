// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  // Callback function to notify MainScreen which item was selected
  final Function(int) onSelectItem;

  // Require the callback in the constructor
  const AppDrawer({required this.onSelectItem, super.key});

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to access theme data for header color etc.
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              // Use theme color for header background
              color: theme.colorScheme.primary,
            ),
            // Display title within the header
            child: Text(
              'Menu',
              style: TextStyle(
                // Use theme color for text that contrasts with header background
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
              ),
            ),
          ),
          // --- ListTile Order Changed ---
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Pop drawer first
              onSelectItem(0);        // Home is Index 0
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Time Converter'),
            onTap: () {
               Navigator.pop(context); // Pop drawer first
               onSelectItem(1);        // Converter is Index 1
            },
          ),
          // Settings is now last
          const Divider(), // Optional divider before settings
           ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Pop drawer first
              onSelectItem(2);        // Settings is Index 2
            },
          ),
          // --- End Order Change ---
        ],
      ),
    );
  }
}