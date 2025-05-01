// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onSelectItem;

  const AppDrawer({required this.onSelectItem, super.key});

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to access theme data for header color etc.
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader( // Use DrawerHeader, not const if using theme data
            decoration: BoxDecoration(
              // Use theme color for header background
              color: theme.colorScheme.primary, // A good themed color
            ),
            // --- FIX: Add the required 'child' property ---
            child: Text(
              'Menu',
              style: TextStyle(
                // Use theme color for text that contrasts with header background
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
              ),
            ),
            // --- End Fix ---
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              onSelectItem(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Time Converter'),
            onTap: () {
              onSelectItem(2);
            },
          ),
           ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              onSelectItem(1);
            },
          ),

          // ... other ListTiles
        ],
      ),
    );
  }
}