// lib/screens/main_screen.dart
import 'package:flutter/material.dart';

// Import the CONTENT widgets for each page
// Adjust paths as needed
import 'home_page_content.dart';
import 'settings_screen.dart';
import 'conversion_screen.dart';
import 'world_clock_screen.dart';
import '../widgets/app_drawer.dart'; // Import the drawer

// This is the main structure holding the persistent AppBar and Drawer
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the currently displayed page content

  // --- REORDERED LISTS to match Drawer ---
  // Home (0), Converter (1), Settings (2)
  static const List<Widget> _pageContentOptions = <Widget>[
    HomePageContent(key: ValueKey('home_content')),    // Index 0
    ConversionScreen(key: ValueKey('converter_content')), // Index 1 (Was Settings)
    WorldClockScreen(key: ValueKey('world_clock_content')), //Index 2
    SettingsScreen(key: ValueKey('settings_content')),     // Index 3 (Was Converter)
  ];

  // Titles for the AppBar corresponding to each page index
  static const List<String> _pageTitles = <String>[
    'Zulu Time Clock', // Index 0
    'Time Converter',  // Index 1 (Was Settings)
    'World Clock',     //Index 2
    'Settings',        // Index 3 (Was Converter)
  ];
  // --- END REORDER ---


  // Callback function passed TO the AppDrawer
  // This is called BY the AppDrawer when an item is tapped
  void _onSelectItem(int index) {
    // Check if the index is valid
    if (index >= 0 && index < _pageContentOptions.length) {
      // --- WORKAROUND: Add slight delay before setState for ghost box issue ---
      Future.delayed(const Duration(milliseconds: 50), () { // 50ms delay
        // Check if the widget is still mounted after the delay before calling setState
        if (mounted) {
          setState(() {
            _selectedIndex = index;
            print("MainScreen: Switched to index $index"); // Debug print
          });
        }
      });
      // --- End Workaround ---
    }
    // Drawer pops itself before calling this now
  }

// In class _MainScreenState inside lib/screens/main_screen.dart

  @override
  Widget build(BuildContext context) {
    print("MainScreen build: Selected Index = $_selectedIndex");
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
      ),
      drawer: AppDrawer(onSelectItem: _onSelectItem), // Pass the callback

      // --- TEMPORARY CHANGE FOR TESTING ---
      // Comment out IndexedStack:
      // body: IndexedStack(
      //    index: _selectedIndex,
      //    children: _pageContentOptions,
      // ),

      // Use direct body switching instead:
      body: _pageContentOptions[_selectedIndex],
      // --- END TEMPORARY CHANGE ---
    );
  }
}