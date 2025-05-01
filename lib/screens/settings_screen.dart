// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz; // Needed for TimeSettingsProvider interaction fallback

import '../providers/theme_provider.dart'; // Import ThemeProvider and AppColors
import '../providers/time_settings_provider.dart';
import './timezone_selection_screen.dart'; // Import the real screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to get display name for ThemeMode
  String _themeModeToString(ThemeMode themeMode) {
     switch (themeMode) {
       case ThemeMode.light: return 'Light';
       case ThemeMode.dark: return 'Dark';
       case ThemeMode.system: return 'System Default';
     }
  }

  // Helper to get the name of a MaterialColor
  String _colorToString(MaterialColor color) {
     return AppColors.primaryColorOptions.entries
          .firstWhere((entry) => entry.value == color, orElse: () => MapEntry('Blue', Colors.blue))
          .key;
  }


  @override
  Widget build(BuildContext context) {
    // This screen is now just the content, no Scaffold/AppBar needed here
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), // Less horizontal padding for ListTiles
      child: ListView(
        children: <Widget>[
          // --- Appearance Section Header ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),

          // --- Theme Mode Setting ---
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            trailing: Consumer<ThemeProvider>( // Consumer only around the dropdown
              builder: (context, themeProvider, child) {
                return DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  items: ThemeMode.values.map((ThemeMode value) {
                    return DropdownMenuItem<ThemeMode>(
                      value: value,
                      child: Text(_themeModeToString(value)),
                    );
                  }).toList(),
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      // Use context.read in callbacks
                      final provider = context.read<ThemeProvider>();
                      switch (newValue) {
                        case ThemeMode.light: provider.setLightMode(); break;
                        case ThemeMode.dark: provider.setDarkMode(); break;
                        case ThemeMode.system: default: provider.setSystemMode(); break;
                      }
                    }
                  },
                );
              },
            ),
          ),

          // --- Accent Color Setting ---
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Accent Color'),
            trailing: Consumer<ThemeProvider>( // Consumer only around the dropdown
               builder: (context, themeProvider, child) {
                  return DropdownButton<MaterialColor>(
                    value: themeProvider.primaryColor, // Current color from provider
                    // Generate dropdown items from AppColors map
                    items: AppColors.primaryColorOptions.entries.map((entry) {
                        final String colorName = entry.key;
                        final MaterialColor colorValue = entry.value;
                        return DropdownMenuItem<MaterialColor>(
                           value: colorValue,
                           child: Row( // Show color swatch and name
                              children: [
                                 Container( // This is the color swatch container
                                  width: 16,
                                  height: 16,
                                  // --- Ensure you are using 'decoration:' like this ---
                                  decoration: BoxDecoration(
                                    // The color goes INSIDE BoxDecoration
                                    color: colorValue,
                                    // The border goes INSIDE BoxDecoration
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor, // Example border color
                                      width: 0.5,
                                    ),
                                    // Optional: You could add rounded corners here too
                                    // borderRadius: BorderRadius.circular(2),
                                  ),
                                  // --- There should be NO 'border:' parameter directly under Container ---
                                ),
                                 const SizedBox(width: 10),
                                 Text(colorName),
                              ],
                           ),
                        );
                    }).toList(),
                    onChanged: (MaterialColor? newColor) {
                       if (newColor != null) {
                          // Use context.read in callbacks
                          context.read<ThemeProvider>().setPrimaryColor(newColor);
                       }
                    },
                  );
               }
            ),
          ),
          const Divider(),

          // --- Time Settings Section Header ---
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Time Settings',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),

          // --- Local Time Zone Section ---
          // Use Consumer here as multiple widgets depend on TimeSettingsProvider
          Consumer<TimeSettingsProvider>(
            builder: (context, timeSettingsProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align sub-header
                children: [
                   Padding( // Add padding for sub-header
                     padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0),
                     child: Text('Local Time Display Source', style: Theme.of(context).textTheme.bodyLarge),
                   ),
                   RadioListTile<bool>(
                    title: const Text('Automatic (Use Device Setting)'),
                    value: true, // Represents the 'isAutomatic' state
                    groupValue: timeSettingsProvider.isLocalTimeAutomatic,
                    onChanged: (bool? value) {
                      if (value == true) {
                        context.read<TimeSettingsProvider>().setAutomaticLocalTime();
                      }
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Manual'),
                    value: false, // Represents the 'isAutomatic' state
                    groupValue: timeSettingsProvider.isLocalTimeAutomatic,
                    onChanged: (bool? value) {
                      if (value == false) {
                        // When switching to manual, ensure a valid zone is set
                        // If no manual zone exists, keep current auto zone or default
                         String currentManualOrDefault = timeSettingsProvider.manualTimeZoneId ?? tz.local.name;
                         context.read<TimeSettingsProvider>().setManualLocalTime(currentManualOrDefault);
                      }
                    },
                  ),

                  // Show manual selection only if Manual mode is selected
                  // Use AnimatedOpacity for smoother transition
                  AnimatedOpacity(
                    opacity: !timeSettingsProvider.isLocalTimeAutomatic ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: !timeSettingsProvider.isLocalTimeAutomatic
                      ? ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Selected Manual Zone'),
                          subtitle: Text(timeSettingsProvider.manualTimeZoneId ?? 'Please select'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                             // Navigate to Time Zone Selection Screen
                             final selectedZone = await Navigator.push<String>(
                               context,
                               MaterialPageRoute(builder: (context) => const TimeZoneSelectionScreen()), // Use the real screen
                             );
                             if (selectedZone != null && context.mounted) {
                               context.read<TimeSettingsProvider>().setManualLocalTime(selectedZone);
                             }
                          },
                        )
                      : const SizedBox.shrink(), // Don't show if Automatic
                    )
                ],
              );
            }
          ),
          const Divider(),
          // Add more settings ListTiles here...
        ],
      ),
    );
  }
}