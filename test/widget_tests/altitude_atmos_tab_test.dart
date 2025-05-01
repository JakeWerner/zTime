// test/widget_tests/altitude_atmos_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the widget to test and its enums
// Adjust the import path based on your project structure
import 'package:zulutime/widgets/flight_calcs/altitude_atmos_tab.dart';

// Helper to build the widget in a testable environment (MaterialApp)
Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(), // Or dark
    home: Scaffold(body: child),
  );
}

void main() {
  // --- Finders ---
  final elevFinder = find.widgetWithText(TextField, 'Field Elevation / Altitude');
  final altimeterFinder = find.widgetWithText(TextField, 'Altimeter Setting');
  final tempFinder = find.widgetWithText(TextField, 'Temperature (OAT)');
  final dewFinder = find.widgetWithText(TextField, 'Dew Point');

  // Find toggle button texts - using ancestor helps ensure we tap the button area
  Finder findToggleButton(String text) =>
      find.ancestor(of: find.text(text), matching: find.byType(InkWell)).first;
  //final inHgToggleFinder = findToggleButton('inHg');
  final hPaToggleFinder = findToggleButton('hPa');
  //final celsiusToggleFinder = findToggleButton('°C');
  final fahrenheitToggleFinder = findToggleButton('°F');

  // Helper to find the specific result value Text widget within its Row
  Finder findResultValue(String label, String expectedValue) {
    final rowFinder = find.ancestor(
      of: find.text(label, findRichText: true),
      matching: find.byType(Row),
    );
    // Ensure the row itself is found before searching within it
    expect(rowFinder, findsOneWidget, reason: 'Could not find Row for label "$label"');
    return find.descendant(
      of: rowFinder,
      matching: find.text(expectedValue, findRichText: true),
    );
  }
  // --- End Finders ---


  group('AltitudeAtmosTab Widget Tests -', () {
    testWidgets('Initial state displays placeholders and default units', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      expect(elevFinder, findsOneWidget);
      expect(altimeterFinder, findsOneWidget);
      expect(tempFinder, findsOneWidget);
      expect(dewFinder, findsOneWidget);

      // Check initial results are placeholders within their rows
      expect(findResultValue('Pressure Altitude:', '--'), findsOneWidget);
      expect(findResultValue('Density Altitude:', '--'), findsOneWidget);
      expect(findResultValue('Cloud Base (AGL approx):', '--'), findsOneWidget);
      expect(findResultValue('Freezing Level (MSL approx):', '--'), findsOneWidget);

      // Check default units are selected visually via suffixes/toggle state
      expect(find.widgetWithText(TextField, 'inHg'), findsOneWidget); // Altimeter suffix
      expect(find.widgetWithText(TextField, '°C'), findsNWidgets(2)); // Temp and Dew Point suffixes
    });

    testWidgets('Calculates Pressure Altitude correctly (inHg)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.enterText(elevFinder, '5000');
      await tester.enterText(altimeterFinder, '29.42');
      await tester.pump();

      // PA = 5000 + (29.92 - 29.42) * 1000 = 5500
      expect(findResultValue('Pressure Altitude:', '5500 ft'), findsOneWidget);
      // Other results still placeholder as temp/dew not entered
      expect(findResultValue('Density Altitude:', '--'), findsOneWidget);
      expect(findResultValue('Cloud Base (AGL approx):', '--'), findsOneWidget);
      expect(findResultValue('Freezing Level (MSL approx):', '--'), findsOneWidget);
    });

     testWidgets('Calculates Pressure Altitude correctly (hPa)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.tap(hPaToggleFinder); // Tap hPa button
      await tester.pump();

      await tester.enterText(elevFinder, '1524'); // ~5000 ft
      await tester.enterText(altimeterFinder, '1000');
      await tester.pump();

      // PA = 1524 + (1013.25 - 1000) * 27 = ~1882m -> ~6174 ft
      expect(findResultValue('Pressure Altitude:', '1882 ft'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'hPa'), findsOneWidget); // Verify unit suffix changed
    });

     testWidgets('Calculates Density Altitude correctly (Celsius)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.enterText(elevFinder, '5000');
      await tester.enterText(altimeterFinder, '29.42'); // PA = 5500 ft
      await tester.enterText(tempFinder, '25'); // 25°C
      await tester.pump();

      // ISA Temp @ 5500ft = 4°C. DA = 5500 + 120 * (25 - 4) = 8020 ft
      expect(findResultValue('Pressure Altitude:', '5500 ft'), findsOneWidget); // Verify PA first
      expect(findResultValue('Density Altitude:', '8020 ft'), findsOneWidget);
    });

    testWidgets('Calculates Density Altitude correctly (Fahrenheit)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.enterText(elevFinder, '5000');
      await tester.enterText(altimeterFinder, '29.42'); // PA = 5500 ft
      await tester.tap(fahrenheitToggleFinder); // Switch Temp to Fahrenheit
      await tester.pump();
      await tester.enterText(tempFinder, '77'); // 77°F = 25°C
      await tester.pump();

      // DA should be the same (~8020 ft)
      expect(findResultValue('Density Altitude:', '8020 ft'), findsOneWidget);
      expect(find.widgetWithText(TextField, '°F'), findsNWidgets(2)); // Verify unit suffixes changed
    });

    testWidgets('Calculates Cloud Base AGL correctly (Celsius)', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.enterText(tempFinder, '20');
      await tester.enterText(dewFinder, '10');
      await tester.pump();

      // Base = ((20 - 10) / 2.5) * 1000 = 4000 ft AGL
      expect(findResultValue('Cloud Base (AGL approx):', '4000 ft'), findsOneWidget);
    });

     testWidgets('Calculates Cloud Base AGL correctly (Fahrenheit)', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

       await tester.tap(fahrenheitToggleFinder); // Switch to Fahrenheit
       await tester.pump();

      await tester.enterText(tempFinder, '77');
      await tester.enterText(dewFinder, '59');
      await tester.pump();

      // Base = ((77 - 59) / 4.4) * 1000 = 4090.9... -> 4091 ft AGL
      expect(findResultValue('Cloud Base (AGL approx):', '4091 ft'), findsOneWidget);
    });

     testWidgets('Cloud Base shows -- if Temp <= Dew Point', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

      await tester.enterText(tempFinder, '10');
      await tester.enterText(dewFinder, '12'); // Dew point higher than temp
      await tester.pump();

      expect(findResultValue('Cloud Base (AGL approx):', '--'), findsOneWidget);
    });

    testWidgets('Calculates Freezing Level correctly (Celsius)', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

       await tester.enterText(elevFinder, '6000');
       await tester.enterText(tempFinder, '10'); // 10°C
       await tester.pump();

       // FZ LVL MSL = 6000 + (10 / 2) * 1000 = 11000 ft
       expect(findResultValue('Freezing Level (MSL approx):', '11000 ft'), findsOneWidget);
    });

    testWidgets('Freezing Level shows Field Elevation if Temp <= 0C', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

       await tester.enterText(elevFinder, '8500');
       await tester.enterText(tempFinder, '-5'); // -5°C
       await tester.pump();

       // Should show elevation as freezing level is at or below surface
       expect(findResultValue('Freezing Level (MSL approx):', '8500 ft'), findsOneWidget);
    });

     testWidgets('Handles empty inputs gracefully', (tester) async {
        await tester.pumpWidget(buildTestableWidget(const AltitudeAtmosTab()));

        await tester.enterText(elevFinder, '5000');
        // Leave other fields empty
        await tester.pump();

        expect(findResultValue('Pressure Altitude:', '--'), findsOneWidget);
        expect(findResultValue('Density Altitude:', '--'), findsOneWidget);
        expect(findResultValue('Cloud Base (AGL approx):', '--'), findsOneWidget);
        expect(findResultValue('Freezing Level (MSL approx):', '--'), findsOneWidget);
     });

  }); // End Group
}