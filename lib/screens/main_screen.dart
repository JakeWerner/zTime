// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

// Import page content widgets and drawer
// Adjust paths as needed
import 'home_page_content.dart';
import 'world_clock_screen.dart';
import 'conversion_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_drawer.dart';

// This is the main structure holding the persistent AppBar and Drawer,
// and now also handles the initial legal notice check.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the currently displayed page content

  // SharedPreferences key for tracking terms acceptance
  static const String _acceptedTermsKey = 'hasAcceptedLegalTerms_v1'; // Added v1 suffix

  // --- Page Content Widgets and Titles (Ordered to match Drawer) ---
  // Home (0), World Clock (2), Converter (1), Settings (3)
  static const List<Widget> _pageContentOptions = <Widget>[
    HomePageContent(key: ValueKey('home_content')),      // Index 0
    ConversionScreen(key: ValueKey('converter_content')), // Index 1
    WorldClockScreen(key: ValueKey('world_clock_content')),// Index 2
    SettingsScreen(key: ValueKey('settings_content')),     // Index 3
  ];

  static const List<String> _pageTitles = <String>[
    'zTime Clock', // Index 0     
    'Time Converter',  // Index 1
    'World Clock',     // Index 2
    'Settings',        // Index 3
  ];
  // --- End Page Content ---


  @override
  void initState() {
    super.initState();
    print("MainScreen initState: Initializing...");
    // Check if terms have been accepted right after the first frame builds
    // This ensures context is available for showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure widget is still in the tree
         _checkAndShowLegalNotice();
      }
    });
  }

  // --- Legal Notice Logic ---

  Future<void> _checkAndShowLegalNotice() async {
    print("MainScreen: Checking legal notice acceptance (Key: $_acceptedTermsKey)...");
    bool accepted = false; // Default to not accepted
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if the key exists and is true, default to false otherwise
      accepted = prefs.getBool(_acceptedTermsKey) ?? false;
      print("MainScreen: Found acceptance flag = $accepted");
    } catch (e) {
       print("MainScreen: Error reading SharedPreferences: $e. Assuming terms not accepted.");
       accepted = false; // Assume not accepted if error reading prefs
    }

    // If not accepted AND the widget is still mounted, show the dialog
    if (!accepted && mounted) {
      print("MainScreen: Terms not accepted. Showing legal notice dialog.");
      // Use the current context to show the dialog
      _showLegalNoticeDialog(context);
    } else if (accepted) {
       print("MainScreen: Legal notice already accepted.");
    } else {
       print("MainScreen: Widget unmounted before showing dialog check result.");
    }
  }

  Future<void> _acceptTerms() async {
     print("MainScreen: User agreed to terms. Saving flag (Key: $_acceptedTermsKey)...");
    try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_acceptedTermsKey, true); // Save acceptance
         print("MainScreen: Terms acceptance flag saved successfully.");
    } catch (e) {
        print("MainScreen: Error saving acceptance flag to SharedPreferences: $e");
        // Optionally show an error message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save acceptance. Please try again.')),
          );
        }
    }
  }

  // Method to display the modal dialog
  void _showLegalNoticeDialog(BuildContext context) {
    // --- IMPORTANT: Replace this placeholder with your actual legal text ---
    // Consider loading this from a separate file or constant for maintainability
    const String legalNoticeText = """
LEGAL NOTICE & DISCLAIMER

Please read these terms carefully before using the zTime application.

1.  **Accuracy:** This application provides time zone information, conversions, and related data based on publicly available sources (such as the IANA Time Zone Database) and standard calculations. While reasonable efforts are made to ensure accuracy, time zone rules, Daylight Saving Time (DST) transitions, and other data can change or contain complexities. Information provided, especially for future dates or critical functions like flight planning, should always be verified with official sources.

2.  **No Warranty:** This application is provided "as is" without any warranties, express or implied. The developer disclaims all warranties, including but not limited to, implied warranties of merchantability and fitness for a particular purpose. The developer does not warrant that the application will be error-free or uninterrupted.

3.  **Limitation of Liability:** In no event shall the developer be liable for any direct, indirect, incidental, special, consequential, or exemplary damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this application, even if advised of the possibility of such damage. You use this application at your own risk.

4.  **Data & Preferences:** The application stores your preferences (such as theme, accent color, selected time zones for world clock, and manual local time settings) locally on your device using the SharedPreferences feature. No personal data is collected or transmitted from your device by the core application unless required for specific, explicitly stated features (like potential future analytics or crash reporting, which would require separate consent if implemented).

5.  **Voluntary Support:** The "Support the Dev" feature utilizes links to external third-party payment platforms (e.g., Buy Me a Coffee, PayPal). Any transactions made are solely between you and the respective platform according to their terms and privacy policies. Donations are entirely voluntary, non-refundable, and do not grant any additional features, services, or guarantees within this application.

**Agreement:**
By clicking "Agree", you acknowledge that you have read, understood, and agree to be bound by the terms of this Legal Notice & Disclaimer. If you do not agree, please exit and uninstall the application.
""";
    // --- End Legal Text Placeholder ---

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext ctx) {
        // Use PopScope to prevent closing with the back button on Android
        return PopScope(
          canPop: false, // Prevent back button dismissal
          child: AlertDialog(
            title: const Text('Legal Notice & Disclaimer'),
            content: const SingleChildScrollView( // Ensure text is scrollable
              child: Text(legalNoticeText),
            ),
            actionsAlignment: MainAxisAlignment.center, // Center the button
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                   backgroundColor: Theme.of(context).colorScheme.primary,
                   foregroundColor: Theme.of(context).colorScheme.onPrimary,
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                ),
                onPressed: () {
                  // Save the acceptance flag first
                  _acceptTerms();
                  // Then close the dialog
                  Navigator.of(ctx).pop();
                   print("MainScreen: Legal notice dialog closed after agreement.");
                },
                child: const Text('Agree and Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Navigation Logic ---
  // Callback function passed TO the AppDrawer
  void _onSelectItem(int index) {
    // Check if the index is valid
    if (index >= 0 && index < _pageContentOptions.length) {
      // WORKAROUND: Add slight delay before setState for potential ghost box issue
      Future.delayed(const Duration(milliseconds: 50), () {
        // Check if the widget is still mounted after the delay
        if (mounted) {
          setState(() {
            _selectedIndex = index;
            print("MainScreen: Switched to page index $index");
          });
        }
      });
      // End Workaround
    }
    // Drawer pops itself before calling this callback
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
     print("MainScreen build: Displaying page index = $_selectedIndex");
    return Scaffold(
      // AppBar remains constant, title updates based on selected index
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        elevation: 1, // Add subtle shadow to AppBar
      ),
      // Drawer remains constant, pass the callback function to it
      drawer: AppDrawer(onSelectItem: _onSelectItem),
      // Body displays the widget corresponding to the selected index
      // Keep using direct switching + AutomaticKeepAliveClientMixin in children
      body: _pageContentOptions[_selectedIndex],
      // If keep alive doesn't work well enough, IndexedStack is the alternative
      // body: IndexedStack(
      //    index: _selectedIndex,
      //    children: _pageContentOptions,
      // ),
    );
  }
}