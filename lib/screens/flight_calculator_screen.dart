// lib/screens/flight_calculator_screen.dart
import 'package:flutter/material.dart';

// Import the individual tab content widgets
import '../widgets/flight_calcs/tsd_tab.dart';
import '../widgets/flight_calcs/fuel_tab.dart';
import '../widgets/flight_calcs/altitude_atmos_tab.dart';
import '../widgets/flight_calcs/wind_heading_tab.dart';

class FlightCalculatorScreen extends StatefulWidget {
  const FlightCalculatorScreen({super.key});
  @override
  State<FlightCalculatorScreen> createState() => _FlightCalculatorScreenState();
}

class _FlightCalculatorScreenState extends State<FlightCalculatorScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const <Tab>[ /* ... Your Tabs ... */
    Tab(text: 'Time/Spd/Dist'), Tab(text: 'Fuel'), Tab(text: 'Altitude/Atmos'), Tab(text: 'Wind/Heading'),
  ];
  final List<Widget> _tabViews = <Widget>[ /* ... Your Tab Views ... */
    TsdTab(), FuelTab(), AltitudeAtmosTab(), WindHeadingTab(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for KeepAlive
    // This widget provides the content body for the flight calculators page
    // within the MainScreen shell.
    return Scaffold(
      body: Column(
        // Column takes children vertically
        children: <Widget>[
          // 1. Place the TabBar directly here
          Container( // Optional: Add background color matching AppBar if needed
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).unselectedWidgetColor, // Use theme color
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3.0,
              tabAlignment: TabAlignment.start,
            ),
          ),
          // Add a divider below the tab bar for visual separation if desired
          // const Divider(height: 1, thickness: 1),
          // 2. Use Expanded for the TabBarView to fill remaining space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabViews,
            ),
          ),
        ],
      ),
      // Remove FAB if it was here - FAB should belong to MainScreen or be omitted
      // floatingActionButton: FloatingActionButton(...)
    );
  }
}