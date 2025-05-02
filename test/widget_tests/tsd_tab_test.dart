// test/widget_tests/tsd_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the widget to test
// Adjust the import path based on your project structure
import 'package:ztime/widgets/flight_calcs/tsd_tab.dart';

// Helper to build the widget in a testable environment (MaterialApp)
Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    // Need Theme for context based styling like Theme.of(context)...
    theme: ThemeData.light(), // Or dark
    home: Scaffold(body: child),
  );
}

void main() {
  // Define finders for input fields (reused across tests)
  // Note: Using labelText assumes you have unique labels set in your TextField decorations
  final speedFinder = find.widgetWithText(TextField, 'Speed (Ground Speed)');
  final timeHoursFinder = find.widgetWithText(TextField, 'Time (H)');
  final timeMinutesFinder = find.widgetWithText(TextField, 'Time (M)');
  final distanceFinder = find.widgetWithText(TextField, 'Distance');

  // Finders for SegmentedButton segments
  //final calcTimeButtonFinder = find.descendant(of: find.byType(SegmentedButton<TsdMode>), matching: find.text('Time'));
  final calcSpeedButtonFinder = find.descendant(of: find.byType(SegmentedButton<TsdMode>), matching: find.text('Speed'));
  final calcDistanceButtonFinder = find.descendant(of: find.byType(SegmentedButton<TsdMode>), matching: find.text('Distance'));

  // Helper to find the specific result text (assuming format "X.Y unit" or "Xh Ym")
  // This looks for any Text widget containing the expected value string.
  // It's slightly less precise than finding the specific result widget, but easier.
  Finder findResultValue(String value) => find.text(value);
  // Helper to find the result label
  Finder findResultLabel(String label) => find.textContaining(label);


  group('TsdTab Widget Tests -', () {
    testWidgets('Initial state is correct (Calculate Time mode)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      // Check inputs are present and enabled/disabled correctly for default Time mode
      expect(speedFinder, findsOneWidget);
      expect(tester.widget<TextField>(speedFinder).enabled, isTrue);

      expect(timeHoursFinder, findsOneWidget);
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isFalse); // Time is calculated initially
      expect(timeMinutesFinder, findsOneWidget);
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isFalse);

      expect(distanceFinder, findsOneWidget);
      expect(tester.widget<TextField>(distanceFinder).enabled, isTrue);

      // Check initial result shows placeholder
      expect(findResultLabel('Calculated Time'), findsOneWidget);
      expect(findResultValue('--'), findsOneWidget);

      // Check correct segment is selected (visual check is harder, test functionality)
    });

    testWidgets('Calculates Time correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      // Ensure Calculate Time mode is selected (default)
      expect(findResultLabel('Calculated Time'), findsOneWidget);

      // Enter speed and distance
      await tester.enterText(speedFinder, '120'); // 120 kts
      await tester.enterText(distanceFinder, '180'); // 180 NM
      await tester.pump(); // Trigger calculation

      // Assert: Check result (Time = Dist / Speed = 180 / 120 = 1.5 hours = 1h 30m)
      expect(findResultValue('1h 30m'), findsOneWidget);

       // Test another value
      await tester.enterText(speedFinder, '90');
      await tester.enterText(distanceFinder, '60');
      await tester.pump();
      // Time = 60 / 90 = 0.666... hours = 40 minutes
      expect(findResultValue('0h 40m'), findsOneWidget);
    });

     testWidgets('Calculate Time handles zero/invalid speed', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      await tester.enterText(speedFinder, '0');
      await tester.enterText(distanceFinder, '100');
      await tester.pump();
      expect(findResultValue('--'), findsOneWidget); // Or specific error text if implemented

      await tester.enterText(speedFinder, ''); // Clear speed
      await tester.pump();
       expect(findResultValue('--'), findsOneWidget);
     });

    testWidgets('Switches to Calculate Speed mode and calculates correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      // Act: Tap the 'Speed' segment
      await tester.tap(calcSpeedButtonFinder);
      await tester.pump();

      // Assert: Mode changed
      expect(findResultLabel('Calculated Speed'), findsOneWidget);
      expect(tester.widget<TextField>(speedFinder).enabled, isFalse); // Speed is now calculated
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isTrue); // Time is now input
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isTrue);
      expect(tester.widget<TextField>(distanceFinder).enabled, isTrue); // Distance is input

      // Act: Enter time and distance
      await tester.enterText(timeHoursFinder, '1'); // 1 hour
      await tester.enterText(timeMinutesFinder, '30'); // 30 minutes = 1.5 hours total
      await tester.enterText(distanceFinder, '150'); // 150 NM
      await tester.pump();

      // Assert: Check result (Speed = Dist / Time = 150 / 1.5 = 100 kts)
      expect(findResultValue('100.0 kts'), findsOneWidget); // Check formatted result
    });

    testWidgets('Calculate Speed handles zero/invalid time', (tester) async {
       await tester.pumpWidget(buildTestableWidget(const TsdTab()));
       await tester.tap(calcSpeedButtonFinder);
       await tester.pump();

      await tester.enterText(timeHoursFinder, '0');
      await tester.enterText(timeMinutesFinder, '0');
      await tester.enterText(distanceFinder, '100');
      await tester.pump();
      expect(findResultValue('--'), findsOneWidget);

      await tester.enterText(timeHoursFinder, ''); // Clear time
      await tester.enterText(timeMinutesFinder, '');
      await tester.pump();
      expect(findResultValue('--'), findsOneWidget);
     });

     testWidgets('Switches to Calculate Distance mode and calculates correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      // Act: Tap the 'Distance' segment
      await tester.tap(calcDistanceButtonFinder);
      await tester.pump();

      // Assert: Mode changed
      expect(findResultLabel('Calculated Distance'), findsOneWidget);
      expect(tester.widget<TextField>(speedFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeHoursFinder).enabled, isTrue);
      expect(tester.widget<TextField>(timeMinutesFinder).enabled, isTrue);
      expect(tester.widget<TextField>(distanceFinder).enabled, isFalse); // Distance is calculated

      // Act: Enter speed and time
      await tester.enterText(speedFinder, '110'); // 110 kts
      await tester.enterText(timeHoursFinder, '2'); // 2 hours
      await tester.enterText(timeMinutesFinder, '15'); // 15 minutes = 2.25 hours total
      await tester.pump();

      // Assert: Check result (Distance = Speed * Time = 110 * 2.25 = 247.5 NM)
      expect(findResultValue('247.5 NM'), findsOneWidget); // Check formatted result
    });

    testWidgets('Clearing an input field resets result', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));

      // Calculate Time initially
      await tester.enterText(speedFinder, '100');
      await tester.enterText(distanceFinder, '100');
      await tester.pump();
      expect(findResultValue('1h 0m'), findsOneWidget);

      // Clear speed
      await tester.enterText(speedFinder, '');
      await tester.pump();
      expect(findResultValue('--'), findsOneWidget); // Result should clear
    });

    testWidgets('Handles partial time input', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TsdTab()));
      await tester.tap(calcDistanceButtonFinder); // Switch to calc distance
      await tester.pump();

      await tester.enterText(speedFinder, '100');
      await tester.enterText(timeMinutesFinder, '30'); // Enter only minutes (0.5 hours)
      await tester.pump();
      // Dist = 100 * 0.5 = 50 NM
      expect(findResultValue('50.0 NM'), findsOneWidget);

      await tester.enterText(timeMinutesFinder, ''); // Clear minutes
      await tester.enterText(timeHoursFinder, '2'); // Enter only hours (2.0 hours)
      await tester.pump();
      // Dist = 100 * 2.0 = 200 NM
      expect(findResultValue('200.0 NM'), findsOneWidget);

    });
  });
}