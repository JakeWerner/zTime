// test/widget_tests/wind_heading_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztime/widgets/flight_calcs/wind_heading_tab.dart'; // Adjust import

// Helper to build the widget in a testable environment
Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  // --- Finders ---
  final windComponentsCardFinder = find.byType(Card).at(0);
  final headingGsCardFinder = find.byType(Card).at(1);
  // Inputs
  Finder wcHdgFinder() => find.descendant(of: windComponentsCardFinder, matching: find.widgetWithText(TextField, 'Runway / Course Heading'));
  Finder wcWindDirFinder() => find.descendant(of: windComponentsCardFinder, matching: find.widgetWithText(TextField, 'Wind Direction (FROM)'));
  Finder wcWindSpdFinder() => find.descendant(of: windComponentsCardFinder, matching: find.widgetWithText(TextField, 'Wind Speed'));
  final navSpeedUnitSelectorFinder = find.descendant(of: headingGsCardFinder, matching: find.byType(SegmentedButton<SpeedUnit>));
  //final navKtsFinder = find.descendant(of: navSpeedUnitSelectorFinder, matching: find.text('Knots'));
  final navMphFinder = find.descendant(of: navSpeedUnitSelectorFinder, matching: find.text('MPH'));
  Finder navTcFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'True Course (TC)'));
  Finder navTasFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'True Airspeed (TAS)'));
  Finder navWindDirFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'Wind Direction (FROM)'));
  Finder navWindSpdFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'Wind Speed'));
  Finder navVarFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'Variation (VAR)'));
  Finder navDevFinder() => find.descendant(of: headingGsCardFinder, matching: find.widgetWithText(TextField, 'Deviation (DEV)'));
  Finder findVarToggleButton(String text) => find.descendant(of: find.ancestor(of: find.text(text), matching: find.byType(ToggleButtons)), matching: find.text(text));
  final varWestFinder = findVarToggleButton('W');

  // --- RE-ADD Helper to find the specific result value Text widget ---
  Finder findResultValue(Finder cardFinder, String label, String expectedValue) {
    final rowFinder = find.ancestor(
      of: find.descendant(of: cardFinder, matching: find.text(label, findRichText: true)),
      matching: find.byType(Row),
    );
    // Don't expect in helper, expect where helper is used
    // expect(rowFinder, findsOneWidget, reason: 'Could not find Row for label "$label" in specified card');
    return find.descendant(
      of: rowFinder,
      matching: find.text(expectedValue, findRichText: true),
    );
  }
  // --- End Finders ---


  group('WindHeadingTab Widget Tests -', () {
    testWidgets('Initial state is correct', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       // Check inputs exist
       expect(wcHdgFinder(), findsOneWidget); expect(navTcFinder(), findsOneWidget); /* etc */

       // Check results are placeholders using the helper
       expect(findResultValue(windComponentsCardFinder, 'Head/Tailwind:', '--'), findsOneWidget);
       expect(findResultValue(windComponentsCardFinder, 'Crosswind:', '--'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Wind Corr Angle (WCA):', '--'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', '--'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '--'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Magnetic Hdg (MH):', '--'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Compass Hdg (CH):', '--'), findsOneWidget);
    });

    testWidgets('Calculates Wind Components - Direct Headwind', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       await tester.enterText(wcHdgFinder(), '360');
       await tester.enterText(wcWindDirFinder(), '180');
       await tester.enterText(wcWindSpdFinder(), '10');
       await tester.pump();

       // --- FIX: Use helper, Check correct value, Check Crosswind correctly ---
       expect(findResultValue(windComponentsCardFinder, 'Head/Tailwind:', 'Headwind 10.0 kts'), findsOneWidget);
       // Check crosswind is zero (allow L or R) - Find the row, then check text within it
       final xwRowFinder = find.ancestor(of: find.text('Crosswind:', findRichText: true), matching: find.byType(Row));
       expect(find.descendant(of: xwRowFinder, matching: find.textContaining('0.0 kts')), findsOneWidget);
       // --- End Fix ---
    });

     testWidgets('Calculates Wind Components - Quartering Tailwind Left', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       await tester.enterText(wcHdgFinder(), '270');
       await tester.enterText(wcWindDirFinder(), '225');
       await tester.enterText(wcWindSpdFinder(), '14');
       await tester.pump();

       // --- FIX: Use helper + Correct expectation ---
       expect(findResultValue(windComponentsCardFinder, 'Head/Tailwind:', 'Tailwind 9.9 kts'), findsOneWidget);
       expect(findResultValue(windComponentsCardFinder, 'Crosswind:', 'From Left 9.9 kts'), findsOneWidget);
       // --- End Fix ---
    });

    testWidgets('Calculates Heading/GS - No Wind', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       await tester.enterText(navTcFinder(), '120');
       await tester.enterText(navTasFinder(), '100');
       await tester.enterText(navWindDirFinder(), '0');
       await tester.enterText(navWindSpdFinder(), '0');
       await tester.pump();

       expect(findResultValue(headingGsCardFinder, 'Wind Corr Angle (WCA):', '0° R'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', '120°'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '100.0 kts'), findsOneWidget);
       // --- FIX: Correct MH expectation ---
       expect(findResultValue(headingGsCardFinder, 'Magnetic Hdg (MH):', '--'), findsOneWidget); // Expect '--' as VAR is empty
       // --- End Fix ---
       expect(findResultValue(headingGsCardFinder, 'Compass Hdg (CH):', '--'), findsOneWidget);
     });

    testWidgets('Calculates Heading/GS - Direct Crosswind (kts)', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       await tester.enterText(navTcFinder(), '000');
       await tester.enterText(navTasFinder(), '100');
       await tester.enterText(navWindDirFinder(), '090');
       await tester.enterText(navWindSpdFinder(), '15');
       await tester.pump();

       // --- FIX: Use helper ---
       expect(findResultValue(headingGsCardFinder, 'Wind Corr Angle (WCA):', '9° R'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', '9°'), findsOneWidget);
       expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '98.9 kts'), findsOneWidget);
       // --- End Fix ---
     });

    testWidgets('Calculates Heading/GS - Updates with MPH selection', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
       await tester.enterText(navTcFinder(), '000');
       await tester.enterText(navTasFinder(), '100');
       await tester.enterText(navWindDirFinder(), '090');
       await tester.enterText(navWindSpdFinder(), '15');
       await tester.pump();
       expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '98.9 kts'), findsOneWidget);

       // Switch to MPH
       await tester.ensureVisible(navMphFinder);
       await tester.tap(navMphFinder);
       await tester.pumpAndSettle();

       // Check suffixes and GS result using helper
       final tasField = tester.widget<TextField>(navTasFinder());
       expect(tasField.decoration?.suffixText, equals('mph'));
       final windSpdField = tester.widget<TextField>(navWindSpdFinder());
       expect(windSpdField.decoration?.suffixText, equals('mph'));
       expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '98.9 mph'), findsOneWidget); // GS now in MPH
       // --- FIX: Use helper for WCA/TH checks ---
       expect(findResultValue(headingGsCardFinder, 'Wind Corr Angle (WCA):', '9° R'), findsOneWidget); // WCA unchanged
       expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', '9°'), findsOneWidget); // TH unchanged
       // --- End Fix ---
     });

    testWidgets('Calculates MH/CH correctly with E/W Variation and Deviation', (tester) async {
         await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
         // Set up for TH = 100 deg
         await tester.enterText(navTcFinder(), '100');
         await tester.enterText(navTasFinder(), '100');
         // --- FIX: Enter Wind Direction (even if speed is 0) ---
         await tester.enterText(navWindDirFinder(), '0'); // Needs a direction
         // --- End Fix ---
         await tester.enterText(navWindSpdFinder(), '0'); // No wind speed
         await tester.pumpAndSettle(); // Allow calculations

         // Verify TH using helper
         expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', '100°'), findsOneWidget, reason: "Should find TH result '100°'");

         // Test East Variation (default)
         await tester.enterText(navVarFinder(), '12');
         await tester.pump();
         expect(findResultValue(headingGsCardFinder, 'Magnetic Hdg (MH):', '88°'), findsOneWidget);

         // Test West Variation
         await tester.ensureVisible(varWestFinder);
         await tester.tap(varWestFinder);
         await tester.pump();
         expect(findResultValue(headingGsCardFinder, 'Magnetic Hdg (MH):', '112°'), findsOneWidget);

         // Test Deviation
         await tester.enterText(navDevFinder(), '-3');
         await tester.pump();
         expect(findResultValue(headingGsCardFinder, 'Compass Hdg (CH):', '109°'), findsOneWidget);

         // Test clear deviation
         await tester.enterText(navDevFinder(), '');
         await tester.pump();
         expect(findResultValue(headingGsCardFinder, 'Compass Hdg (CH):', '--'), findsOneWidget);
      });

      testWidgets('"Impossible" wind scenario', (tester) async {
         await tester.pumpWidget(buildTestableWidget(const WindHeadingTab()));
         await tester.enterText(navTcFinder(), '000');
         await tester.enterText(navTasFinder(), '10');
         await tester.enterText(navWindDirFinder(), '090');
         await tester.enterText(navWindSpdFinder(), '15');
         await tester.pump();

         // --- FIX: Use helper ---
         expect(findResultValue(headingGsCardFinder, 'Wind Corr Angle (WCA):', 'Error'), findsOneWidget);
         expect(findResultValue(headingGsCardFinder, 'True Heading (TH):', 'Impossible'), findsOneWidget);
         expect(findResultValue(headingGsCardFinder, 'Ground Speed (GS):', '(XW > TAS)'), findsOneWidget);
         // --- End Fix ---
      });

  }); // End Group
}