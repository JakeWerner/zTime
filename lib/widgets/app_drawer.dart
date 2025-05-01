// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onSelectItem;
  const AppDrawer({required this.onSelectItem, super.key});

    void _showSupportDialog(BuildContext context) {
    // Replace with your actual donation links
    //const String buyMeACoffeeUrl = 'https://www.buymeacoffee.com/YOUR_USERNAME'; // Replace!
    const String payPalMeUrl = 'https://paypal.me/jacobwerner1?country.x=US&locale.x=en_US';
    // Add other links if needed

    // Helper function to launch URL
    Future<void> launchURL(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // Handle error - e.g., show a Snackbar
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Could not launch $urlString')),
           );
        }
        print('Could not launch $urlString');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Support the Developer'),
          content: SingleChildScrollView( // In case text/buttons overflow
            child: ListBody(
              children: <Widget>[
                const Text('Thank you for using zTime!'),
                const SizedBox(height: 10),
                const Text('If you find this app helpful, please consider supporting its development. Donations are voluntary and greatly appreciated!'),
                const SizedBox(height: 20),
                // Add buttons for your chosen platforms
                /*ElevatedButton.icon(
                   icon: const Icon(Icons.coffee_outlined), // Example icon
                   label: const Text('Buy Me a Coffee'),
                   onPressed: () {
                      Navigator.of(ctx).pop(); // Close dialog before launching
                      launchURL(buyMeACoffeeUrl);
                   },
                   style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)), // Make button wider
                ), */
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.paypal), // Example icon
                  label: const Text('PayPal'),
                  onPressed: () {
                     Navigator.of(ctx).pop();
                     launchURL(payPalMeUrl);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                ),
                // Add more buttons for Ko-fi, Patreon etc. if desired
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
            child: Column( // Use a Column to stack logo and text
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Align text left
              children: [
                Image.asset( // Display the logo
                  'lib/assets/zTimeLogo.png',
                  height: 100, // Adjust size as needed
                  
                  // Optional: Add error handling for image loading
                  errorBuilder: (crontext, error, stackTrace) {
                     return const Icon(Icons.error_outline, color: Colors.red, size: 40); // Show error icon
                  },
                ),
                Text(
                  'Menu', // Keep or adjust text
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20, // Adjust size
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
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
          const Divider(),
           ListTile(
             leading: const Icon(Icons.favorite_border), // Heart icon
             title: const Text('Support the Dev'),
             onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Show the support dialog
                _showSupportDialog(context);
             },
           ),
        ],
      ),
    );
  }
}