// lib/screens/unit_converter_screen.dart
import 'package:flutter/material.dart';

// Import the individual tab content widgets (we'll create these next)
import '../widgets/converters/distance_converter_tab.dart';
import '../widgets/converters/speed_converter_tab.dart';
import '../widgets/converters/temperature_converter_tab.dart';
import '../widgets/converters/altitude_converter_tab.dart';
import '../widgets/converters/pressure_converter_tab.dart';
// Add imports for other converter tabs as you create them

class UnitConverterScreen extends StatefulWidget {
  // Add key for state preservation if needed by parent (MainScreen's list)
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

// Need TickerProviderStateMixin for the TabController animation
class _UnitConverterScreenState extends State<UnitConverterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Define the tabs
  final List<Tab> _tabs = const <Tab>[
    Tab(text: 'Distance'),
    Tab(text: 'Speed'),
    Tab(text: 'Temperature'),
    Tab(text: 'Altitude'),
    Tab(text: 'Pressure'),
    // Add more Tab() widgets here for other categories
  ];

  // Define the corresponding content widgets for the TabBarView
  final List<Widget> _tabViews = const <Widget>[
    DistanceConverterTab(), // Content for Distance tab
    SpeedConverterTab(),    // Content for Speed tab
    TemperatureConverterTab(), // Content for Temperature tab
    AltitudeConverterTab(), // Content for Altitude tab
    PressureConverterTab(), // Content for Pressure tab
    // Add instances of other converter widgets here
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the TabController
    _tabController = TabController(length: _tabs.length, vsync: this);
    print("UnitConverterScreen: initState - TabController initialized");
  }

  @override
  void dispose() {
    // Dispose the TabController when the state is disposed
    _tabController.dispose();
    print("UnitConverterScreen: dispose - TabController disposed");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This screen content needs its own Scaffold to host the TabBar below the main AppBar
    return Scaffold(
      // The AppBar is provided by MainScreen. We add the TabBar below it.
      appBar: TabBar(
        controller: _tabController,
        tabs: _tabs,
        isScrollable: true, // Allow tabs to scroll horizontally if many
        labelColor: Theme.of(context).colorScheme.primary, // Color for selected tab
        unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color, // Color for unselected tabs
        indicatorColor: Theme.of(context).colorScheme.primary, // Color of the underline indicator
        tabAlignment: TabAlignment.start,
      ),
      // The body is the TabBarView, which displays the content of the selected tab
      body: TabBarView(
        controller: _tabController,
        children: _tabViews, // The list of content widgets
      ),
    );
  }
}