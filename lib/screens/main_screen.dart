// lib/screens/main_screen.dart (Rename/move home_screen.dart content here)
import 'package:flutter/material.dart';

// Import the CONTENT widgets for each page (we'll create/refactor these)
import 'home_page_content.dart';
import 'settings_screen.dart'; // Keep existing screen names for now is okay
import 'conversion_screen.dart';
import '../widgets/app_drawer.dart'; // Keep using your drawer

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 0: Home, 1: Settings, 2: Converter

  // List of the main content widgets for each "page"
  // IMPORTANT: These should be the body content, NOT full Scaffolds
  static const List<Widget> _pageContentOptions = <Widget>[
    HomePageContent(), // Extracted content from old HomeScreen
    SettingsScreen(),    // Refactored SettingsScreen (no Scaffold/AppBar)
    ConversionScreen(),  // Refactored ConversionScreen (no Scaffold/AppBar)
  ];

  // Titles for the AppBar corresponding to each page
  static const List<String> _pageTitles = <String>[
    'zTime Home',
    'Settings',
    'Time Converter',
  ];


  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]), // Title changes based on selection
      ),
      // Pass the callback function TO the drawer
      drawer: AppDrawer(onSelectItem: _onSelectItem),
      body: IndexedStack( // Use IndexedStack to keep state of pages
         index: _selectedIndex,
         children: _pageContentOptions,
      ),
      // Or simply:
      // body: _pageContentOptions[_selectedIndex], // Simpler, but pages might lose state when switched
    );
  }
}