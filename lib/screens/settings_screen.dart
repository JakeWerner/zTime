// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:timezone/timezone.dart' as tz; // Needed for TimeSettingsProvider fallback

// Import your other project files (adjust paths if needed)
import '../providers/theme_provider.dart';
import '../providers/time_settings_provider.dart';
import './timezone_selection_screen.dart'; // For navigating to manual time zone selection

// --- Top-Level Helper function to Launch URL ---
Future<void> _launchUrl(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  // Use context.mounted check before launching if context might become invalid
  // This check is good practice when using context after an await
  if (!context.mounted) return;

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    // Handle error - show Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch $urlString')),
    );
    print('Could not launch $urlString');
  }
}
// --- End Top-Level Function ---


// SettingsScreen remains a StatelessWidget as its UI depends on providers
class SettingsScreen extends StatelessWidget {
  // Add key for state preservation if needed by MainScreen's list
  const SettingsScreen({super.key});

  // Helper function to get display name for ThemeMode
  // Okay inside StatelessWidget as it's a pure function based on input
  String _themeModeToString(ThemeMode themeMode) {
     switch (themeMode) {
       case ThemeMode.light: return 'Light';
       case ThemeMode.dark: return 'Dark';
       case ThemeMode.system: return 'System Default';
     }
     // The switch covers all cases, but Dart analysis might want an explicit return.
     // return 'System Default';
  }

  // Helper to get the name of a MaterialColor
  // Okay inside StatelessWidget
  String _colorToString(MaterialColor color) {
     // Find the name associated with the color value in our map
     return AppColors.primaryColorOptions.entries
          .firstWhere((entry) => entry.value.value == color.value, // Compare primary value
             orElse: () => MapEntry('Blue', Colors.blue) // Default if not found
          )
          .key; // Return the key (name)
  }


  @override
  Widget build(BuildContext context) {
    // This screen is now just the content for the MainScreen body
    // No Scaffold or AppBar needed here
    return Padding(
      // Use ListView padding instead of body padding if preferred
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: ListView(
        // Consider adding padding to the ListView instead of the outer Padding
        // padding: const EdgeInsets.all(16.0),
        children: <Widget>[

          // --- Appearance Section Header ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
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
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme Mode'),
            trailing: Consumer<ThemeProvider>(
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
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Accent Color'),
            trailing: Consumer<ThemeProvider>(
               builder: (context, themeProvider, child) {
                  return DropdownButton<MaterialColor>(
                    value: themeProvider.primaryColor,
                    items: AppColors.primaryColorOptions.entries.map((entry) {
                        final String colorName = entry.key;
                        final MaterialColor colorValue = entry.value;
                        return DropdownMenuItem<MaterialColor>(
                           value: colorValue,
                           child: Row( // Show color swatch and name
                              children: [
                                 Container(width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      color: colorValue,
                                      border: Border.all(color: Theme.of(context).dividerColor, width: 0.5)
                                    ),
                                 ),
                                 const SizedBox(width: 10),
                                 Text(colorName),
                              ],
                           ),
                        );
                    }).toList(),
                    onChanged: (MaterialColor? newColor) {
                       if (newColor != null) {
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
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0), // Added more top padding
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding( // Sub-header for clarity
                     padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0),
                     child: Text('Home Screen Local Time Source', style: Theme.of(context).textTheme.titleMedium),
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
                    controlAffinity: ListTileControlAffinity.trailing, // Standard placement
                  ),
                  RadioListTile<bool>(
                    title: const Text('Manual'),
                    value: false, // Represents the 'isAutomatic' state
                    groupValue: timeSettingsProvider.isLocalTimeAutomatic,
                    onChanged: (bool? value) {
                      if (value == false) {
                         String currentManualOrDefault = timeSettingsProvider.manualTimeZoneId ?? tz.local.name;
                         context.read<TimeSettingsProvider>().setManualLocalTime(currentManualOrDefault);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),

                  // Show manual selection only if Manual mode is selected
                  AnimatedOpacity(
                    opacity: !timeSettingsProvider.isLocalTimeAutomatic ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    // Use Visibility to prevent interaction when hidden
                    child: Visibility(
                      visible: !timeSettingsProvider.isLocalTimeAutomatic,
                      child: ListTile(
                          leading: const Icon(Icons.language_outlined),
                          title: const Text('Selected Manual Zone'),
                          subtitle: Text(timeSettingsProvider.manualTimeZoneId ?? 'Please select'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                             final selectedZone = await Navigator.push<String>(
                               context,
                               MaterialPageRoute(builder: (context) => const TimeZoneSelectionScreen()), // Navigate to picker
                             );
                             if (selectedZone != null && context.mounted) {
                               context.read<TimeSettingsProvider>().setManualLocalTime(selectedZone);
                             }
                          },
                        ),
                    )
                  ),
                ],
              );
            }
          ),
          const Divider(),

          // --- Legal Section Header ---
           Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              'Legal',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          // --- Privacy Policy Link ---
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_outlined, size: 18), // External link icon
            onTap: () {
              // --- Replace with your actual hosted URL ---
              const String privacyPolicyUrl = 'https://github.com/JakeWerner/zTime/blob/master/PrivacyPolicy1MAY2025.md';
              // --- ------------------------------------ ---
              if (privacyPolicyUrl != 'https://github.com/JakeWerner/zTime/blob/master/PrivacyPolicy1MAY2025.md') {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Privacy Policy URL not set yet!')),
                 );
                 return;
              }
              // Call the top-level function
              _launchUrl(context, privacyPolicyUrl);
            },
          ),
          const Divider(), // Optional final divider
        ],
      ),
    );
  }
}