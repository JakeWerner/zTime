// test/utils/conversion_logic_test.dart
import 'package:flutter_test/flutter_test.dart';

// --- Enums (Defined here for test standalone execution) ---
// In real app, import these from where they are defined
enum DistanceUnit { nm, sm, km }
enum SpeedUnit { kts, mph, kph }
enum AltitudeUnit { ft, m }
enum TemperatureUnit { C, F }
enum PressureUnit { inHg, hPa }
// --- End Enums ---


// --- Conversion Logic (Defined here for test standalone execution) ---
// IMPORTANT: Ideally, these functions would be in your main code (e.g., lib/utils/)
// and imported here. Ensure the logic here matches your app's State classes.

// Distance
double? convertDistance(double value, DistanceUnit from, DistanceUnit to) {
  if (from == to) return value;
  double valueInNm; // Base unit: Nautical Miles
  switch (from) {
    case DistanceUnit.nm: valueInNm = value; break;
    case DistanceUnit.sm: valueInNm = value / 1.15078; break;
    case DistanceUnit.km: valueInNm = value / 1.852; break;
  }
  switch (to) {
    case DistanceUnit.nm: return valueInNm;
    case DistanceUnit.sm: return valueInNm * 1.15078;
    case DistanceUnit.km: return valueInNm * 1.852;
  }
}

// Speed
double? convertSpeed(double value, SpeedUnit from, SpeedUnit to) {
   if (from == to) return value;
   double valueInKts; // Base unit: Knots
   switch (from) {
      case SpeedUnit.kts: valueInKts = value; break;
      case SpeedUnit.mph: valueInKts = value / 1.15078; break;
      case SpeedUnit.kph: valueInKts = value / 1.852; break;
   }
   switch (to) {
     case SpeedUnit.kts: return valueInKts;
     case SpeedUnit.mph: return valueInKts * 1.15078;
     case SpeedUnit.kph: return valueInKts * 1.852;
   }
}

// Altitude
double? convertAltitude(double value, AltitudeUnit from, AltitudeUnit to) {
   if (from == to) return value;
    double valueInFt; // Base unit: Feet
    switch (from) {
      case AltitudeUnit.ft: valueInFt = value; break;
      case AltitudeUnit.m: valueInFt = value * 3.28084; break; // 1 Meter = 3.28084 Feet
   }
   switch (to) {
     case AltitudeUnit.ft: return valueInFt;
     case AltitudeUnit.m: return valueInFt / 3.28084;
   }
 }

// Temperature
double? convertTemperature(double value, TemperatureUnit from, TemperatureUnit to) {
    if (from == to) return value;
    switch (from) {
       case TemperatureUnit.C:
         return (to == TemperatureUnit.F) ? (value * 9 / 5) + 32 : value; // Should never be C->C here
       case TemperatureUnit.F:
         return (to == TemperatureUnit.C) ? (value - 32) * 5 / 9 : value; // Should never be F->F here
    }
 }

// Pressure
 double? convertPressure(double value, PressureUnit from, PressureUnit to) {
    if (from == to) return value;
     double valueInHpa; // Base unit: Hectopascals
     switch (from) {
       case PressureUnit.hPa: valueInHpa = value; break;
       case PressureUnit.inHg: valueInHpa = value * 33.86389; break; // 1 inHg approx 33.86389 hPa
     }
     switch (to) {
       case PressureUnit.hPa: return valueInHpa;
       case PressureUnit.inHg: return valueInHpa / 33.86389;
     }
 }
// --- End Conversion Logic ---


// --- TESTS ---
void main() {
  // Tolerance for floating point comparisons
  const double tolerance = 0.001;
  const double pressureTolerance = 0.1; // hPa values can be large

  group('Unit Conversion Logic Unit Tests -', () {

    group('Distance Conversions -', () {
      test('NM to KM', () => expect(convertDistance(100, DistanceUnit.nm, DistanceUnit.km), closeTo(185.2, tolerance)));
      test('NM to SM', () => expect(convertDistance(100, DistanceUnit.nm, DistanceUnit.sm), closeTo(115.078, tolerance)));
      test('KM to NM', () => expect(convertDistance(185.2, DistanceUnit.km, DistanceUnit.nm), closeTo(100.0, tolerance)));
      test('KM to SM', () => expect(convertDistance(100, DistanceUnit.km, DistanceUnit.sm), closeTo(62.137, tolerance)));
      test('SM to NM', () => expect(convertDistance(115.078, DistanceUnit.sm, DistanceUnit.nm), closeTo(100.0, tolerance)));
      test('SM to KM', () => expect(convertDistance(100, DistanceUnit.sm, DistanceUnit.km), closeTo(160.934, tolerance)));
      test('Same Unit (NM)', () => expect(convertDistance(50, DistanceUnit.nm, DistanceUnit.nm), equals(50)));
      test('Same Unit (KM)', () => expect(convertDistance(100, DistanceUnit.km, DistanceUnit.km), equals(100)));
      test('Same Unit (SM)', () => expect(convertDistance(200, DistanceUnit.sm, DistanceUnit.sm), equals(200)));
    });

    group('Speed Conversions -', () {
       test('KTS to KPH', () => expect(convertSpeed(100, SpeedUnit.kts, SpeedUnit.kph), closeTo(185.2, tolerance)));
       test('KTS to MPH', () => expect(convertSpeed(100, SpeedUnit.kts, SpeedUnit.mph), closeTo(115.078, tolerance)));
       test('KPH to KTS', () => expect(convertSpeed(185.2, SpeedUnit.kph, SpeedUnit.kts), closeTo(100.0, tolerance)));
       test('KPH to MPH', () => expect(convertSpeed(100, SpeedUnit.kph, SpeedUnit.mph), closeTo(62.137, tolerance)));
       test('MPH to KTS', () => expect(convertSpeed(115.078, SpeedUnit.mph, SpeedUnit.kts), closeTo(100.0, tolerance)));
       test('MPH to KPH', () => expect(convertSpeed(100, SpeedUnit.mph, SpeedUnit.kph), closeTo(160.934, tolerance)));
       test('Same Unit (KTS)', () => expect(convertSpeed(120, SpeedUnit.kts, SpeedUnit.kts), equals(120)));
       test('Same Unit (MPH)', () => expect(convertSpeed(80, SpeedUnit.mph, SpeedUnit.mph), equals(80)));
       test('Same Unit (KPH)', () => expect(convertSpeed(150, SpeedUnit.kph, SpeedUnit.kph), equals(150)));
    });

    group('Altitude Conversions -', () {
       test('Feet to Meters', () => expect(convertAltitude(10000, AltitudeUnit.ft, AltitudeUnit.m), closeTo(3048.0, tolerance)));
       test('Meters to Feet', () => expect(convertAltitude(1000, AltitudeUnit.m, AltitudeUnit.ft), closeTo(3280.84, tolerance)));
       test('Same Unit (FT)', () => expect(convertAltitude(35000, AltitudeUnit.ft, AltitudeUnit.ft), equals(35000)));
       test('Same Unit (M)', () => expect(convertAltitude(10000, AltitudeUnit.m, AltitudeUnit.m), equals(10000)));
    });

    group('Temperature Conversions -', () {
      test('Celsius to Fahrenheit', () {
        expect(convertTemperature(0, TemperatureUnit.C, TemperatureUnit.F), closeTo(32.0, tolerance));
        expect(convertTemperature(100, TemperatureUnit.C, TemperatureUnit.F), closeTo(212.0, tolerance));
        expect(convertTemperature(-18, TemperatureUnit.C, TemperatureUnit.F), closeTo(-0.4, tolerance));
        expect(convertTemperature(37, TemperatureUnit.C, TemperatureUnit.F), closeTo(98.6, tolerance));
      });
      test('Fahrenheit to Celsius', () {
        expect(convertTemperature(32, TemperatureUnit.F, TemperatureUnit.C), closeTo(0.0, tolerance));
        expect(convertTemperature(212, TemperatureUnit.F, TemperatureUnit.C), closeTo(100.0, tolerance));
        expect(convertTemperature(-4, TemperatureUnit.F, TemperatureUnit.C), closeTo(-20.0, tolerance));
         expect(convertTemperature(98.6, TemperatureUnit.F, TemperatureUnit.C), closeTo(37.0, tolerance));
      });
      test('Same Unit (C)', () => expect(convertTemperature(20, TemperatureUnit.C, TemperatureUnit.C), equals(20)));
      test('Same Unit (F)', () => expect(convertTemperature(68, TemperatureUnit.F, TemperatureUnit.F), equals(68)));
    });

     group('Pressure Conversions -', () {
       test('inHg to hPa (Standard Atmosphere)', () => expect(convertPressure(29.92126, PressureUnit.inHg, PressureUnit.hPa), closeTo(1013.25, tolerance))); // Use more precise 29.921...
       test('hPa to inHg (Standard Atmosphere)', () => expect(convertPressure(1013.25, PressureUnit.hPa, PressureUnit.inHg), closeTo(29.92126, tolerance)));
       test('Low Pressure hPa to inHg', () => expect(convertPressure(980, PressureUnit.hPa, PressureUnit.inHg), closeTo(28.939, tolerance)));
       test('High Pressure inHg to hPa', () => expect(convertPressure(30.50, PressureUnit.inHg, PressureUnit.hPa), closeTo(1032.85, pressureTolerance)));
       test('Same Unit (hPa)', () => expect(convertPressure(1000, PressureUnit.hPa, PressureUnit.hPa), equals(1000)));
       test('Same Unit (inHg)', () => expect(convertPressure(30.00, PressureUnit.inHg, PressureUnit.inHg), equals(30.00)));
    });

    // TODO: Add Unit Tests for Pressure Altitude, Density Altitude, Cloud Base, Freezing Level,
    // Wind Components, Heading/GS/WCA, and Fuel calculations if/when extracted to testable functions.

  }); // End top-level group
} // End main