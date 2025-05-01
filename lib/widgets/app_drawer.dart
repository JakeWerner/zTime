// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onSelectItem;
  const AppDrawer({required this.onSelectItem, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader( // Use DrawerHeader, not const if using theme data below
            decoration: BoxDecoration(
              // Use theme color for header background
              color: theme.colorScheme.primary, // Use theme color
            ),
            // --- Ensure this 'child:' line exists ---
            child: Text(
              'Menu',
              style: TextStyle(
                // Use theme color for text that contrasts
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
              ),
            ),
            // --- End Replace Here ---
          ),
          ListTile( // Index 0
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () { Navigator.pop(context); onSelectItem(0); },
          ),
          ListTile( // Index 1
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Time Converter'),
            onTap: () { Navigator.pop(context); onSelectItem(1); },
          ),
          ListTile( // Index 2 - NEW
            leading: const Icon(Icons.language), // World icon
            title: const Text('World Clock'),
            onTap: () { Navigator.pop(context); onSelectItem(2); },
          ),
          const Divider(),
           ListTile( // Index 3 - Was 2
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () { Navigator.pop(context); onSelectItem(3); },
          ),
        ],
      ),
    );
  }
}