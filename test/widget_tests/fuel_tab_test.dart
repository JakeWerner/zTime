// test/widget_tests/fuel_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the widget to test and its enums
// Adjust the import path based on your project structure
import 'package:ztime/widgets/flight_calcs/fuel_tab.dart';

// Helper to build the widget in a testable environment (MaterialApp)
Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(), // Use a specific theme for consistency
    home: Scaffold(body: child),
  );
}

void main() {
  // --- Finders ---
  // Input Fields (using labels)
  final fuelAvailFinder = find.widgetWithText(TextField, 'Fuel Available');
  final burnRateFinder = find.widgetWithText(TextField, 'Fuel Burn Rate');
  final timeHoursFinder = find.widgetWithText(TextField, 'Time (H)');
  final timeMinutesFinder = find.widgetWithText(TextField, 'Time (M)');
  final fuelUsedFinder = find.widgetWithText(TextField, 'Fuel Used');

  // Unit Selection
  final fuelUnitDropdownFinder = find.byType(DropdownButton<FuelUnit>);
  // Use .last because the text appears both on the button and in the dropdown item
  //final gallonsOptionFinder = find.text('Gallons (US)').last;
  final litersOptionFinder = find.text('Liters').last;

  // Mode Selection Segments
  final modeSelectorFinder = find.byType(SegmentedButton<FuelCalcMode>);
  //final enduranceModeFinder = find.descendant(of: modeSelectorFinder, matching: find.text('Endurance'));
  final fuelReqModeFinder = find.descendant(of: modeSelectorFinder, matching: find.text('Fuel Req.'));
  final burnRateModeFinder = find.descendant(of: modeSelectorFinder, matching: find.text('Burn Rate'));

  // Result Text (find by the value displayed)
  Finder findResultValue(String value) => find.text(value);


  group('FuelTab Widget Tests -', () {
    testWidgets('Initial state is correct (Endurance mode, Gallons)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

      // Check default mode selected
      expect(find.textContaining('Calculated Endurance'), findsOneWidget);

      // Check default units selected and displayed
      expect(find.text('Gallons (US)'), findsOneWidget); // <-- Change findsNWidgets(2) to findsOneWidget // Dropdown value + Dropdown item (need .last for tapping)
      expect(find.widgetWithText(TextField, 'Gal'), findsNWidgets(2)); // Fuel Avail, Fuel Used suffixes
      expect(find.widgetWithText(TextField, 'Gal/Hr'), findsOneWidget); // Burn Rate suffix

      // Check field enabled states for Endurance mode
      expect(tester.widget<TextField>(fuelAvailFinder).enabled, isTrue);
      expect(tester.widget<TextField>(burnRateFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isFalse);
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isFalse);
      expect(tester.widget<TextField>(fuelUsedFinder).enabled, isFalse);

      // Check initial result
      expect(findResultValue('--'), findsOneWidget);
    });

    testWidgets('Calculates Endurance correctly (Gallons)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

      await tester.enterText(fuelAvailFinder, '50'); // 50 Gal
      await tester.enterText(burnRateFinder, '8'); // 8 Gal/Hr
      await tester.pump();

      // Endurance = 50 / 8 = 6.25 hours = 6 hours 15 minutes
      expect(findResultValue('6h 15m'), findsOneWidget);
    });

     testWidgets('Calculates Endurance correctly (Liters)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

      // Switch to Liters
      await tester.tap(fuelUnitDropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(litersOptionFinder);
      await tester.pumpAndSettle();

      // Verify suffixes updated
      expect(find.widgetWithText(TextField, 'L'), findsNWidgets(2));
      expect(find.widgetWithText(TextField, 'L/Hr'), findsOneWidget);

      // Enter values
      await tester.enterText(fuelAvailFinder, '120'); // 120 L
      await tester.enterText(burnRateFinder, '30'); // 30 L/Hr
      await tester.pump();

      // Endurance = 120 / 30 = 4.0 hours = 4 hours 0 minutes
      expect(findResultValue('4h 0m'), findsOneWidget);
    });

     testWidgets('Endurance handles zero/invalid burn rate', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

      await tester.enterText(fuelAvailFinder, '50');
      await tester.enterText(burnRateFinder, '0'); // Invalid burn rate
      await tester.pump();
      // Depending on implementation, might show --, Error, or Infinity. Test for '--'.
      expect(findResultValue('--'), findsOneWidget);

      await tester.enterText(burnRateFinder, ''); // Clear burn rate
      await tester.pump();
       expect(findResultValue('--'), findsOneWidget);
     });


    testWidgets('Switches to Fuel Required mode and calculates correctly (Gallons)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

      // Switch mode
      await tester.tap(fuelReqModeFinder);
      await tester.pump();

      // Check state
      expect(find.textContaining('Calculated Fuel Required'), findsOneWidget);
      expect(tester.widget<TextField>(fuelAvailFinder).enabled, isFalse);
      expect(tester.widget<TextField>(burnRateFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isTrue);
      expect(tester.widget<TextField>(fuelUsedFinder).enabled, isFalse);

      // Enter values
      await tester.enterText(burnRateFinder, '10.5'); // 10.5 Gal/Hr
      await tester.enterText(timeHoursFinder, '2'); // 2 hours
      await tester.enterText(timeMinutesFinder, '30'); // 30 minutes = 2.5 hours total
      await tester.pump();

      // Fuel Req = 10.5 * 2.5 = 26.25 Gal
      expect(findResultValue('26.3 Gal'), findsOneWidget); // Check formatted/rounded result
    });

     testWidgets('Switches to Burn Rate mode and calculates correctly (Liters)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FuelTab()));

       // Switch unit
      await tester.tap(fuelUnitDropdownFinder); await tester.pumpAndSettle();
      await tester.tap(litersOptionFinder); await tester.pumpAndSettle();
      // Switch mode
      await tester.tap(burnRateModeFinder); await tester.pump();

       // Check state
      expect(find.textContaining('Calculated Burn Rate'), findsOneWidget);
      expect(tester.widget<TextField>(fuelAvailFinder).enabled, isFalse);
      expect(tester.widget<TextField>(burnRateFinder).enabled, isFalse);
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isTrue);
      expect(tester.widget<TextField>(fuelUsedFinder).enabled, isTrue);

      // Enter values
      await tester.enterText(fuelUsedFinder, '75'); // 75 L
      await tester.enterText(timeHoursFinder, '1'); // 1 hour
      await tester.enterText(timeMinutesFinder, '45'); // 45 minutes = 1.75 hours total
      await tester.pump();

      // Rate = 75 / 1.75 = 42.857... L/Hr
      expect(findResultValue('42.9 L/Hr'), findsOneWidget); // Check formatted/rounded result
    });

     testWidgets('Clearing input clears result', (tester) async {
        await tester.pumpWidget(buildTestableWidget(const FuelTab()));

        // Calculate Endurance initially
        await tester.enterText(fuelAvailFinder, '50');
        await tester.enterText(burnRateFinder, '10');
        await tester.pump();
        expect(findResultValue('5h 0m'), findsOneWidget);

        // Clear an input
        await tester.enterText(burnRateFinder, '');
        await tester.pump();
        expect(findResultValue('--'), findsOneWidget); // Result should clear
     });

  });
}