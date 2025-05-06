// lib/widgets/flight_calcs/altitude_atmos_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// Enums
enum TempUnit { C, F }
enum PressUnit { inHg, hPa }

class AltitudeAtmosTab extends StatefulWidget {
  const AltitudeAtmosTab({super.key});

  @override
  State<AltitudeAtmosTab> createState() => _AltitudeAtmosTabState();
}

class _AltitudeAtmosTabState extends State<AltitudeAtmosTab> with AutomaticKeepAliveClientMixin {
  // Input Controllers
  final TextEditingController _elevationController = TextEditingController();
  final TextEditingController _altimeterController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _dewPointController = TextEditingController();

  // Selected Units
  PressUnit _altimeterUnit = PressUnit.inHg;
  TempUnit _tempUnit = TempUnit.C; // Match Dew Point unit to this

  // Input Values
  double? _elevationFt;
  double? _altimeterSetting;
  double? _oat; // Outside Air Temp
  double? _dewPoint;

  // Calculated Results
  double? _pressureAltitudeFt;
  double? _densityAltitudeFt;
  double? _cloudBaseAglFt;
  double? _freezingLevelFt; // Approx MSL

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _elevationController.addListener(_calculateAll);
    _altimeterController.addListener(_calculateAll);
    _tempController.addListener(_calculateAll);
    _dewPointController.addListener(_calculateAll);
     _calculateAll();
  }

  @override
  void dispose() {
    _elevationController.removeListener(_calculateAll);
    _altimeterController.removeListener(_calculateAll);
    _tempController.removeListener(_calculateAll);
    _dewPointController.removeListener(_calculateAll);
    _elevationController.dispose();
    _altimeterController.dispose();
    _tempController.dispose();
    _dewPointController.dispose();
    super.dispose();
  }

  void _parseInputs() {
    _elevationFt = double.tryParse(_elevationController.text);
    _altimeterSetting = double.tryParse(_altimeterController.text);
    _oat = double.tryParse(_tempController.text.replaceAll(',', '.')); // Allow comma decimal
    _dewPoint = double.tryParse(_dewPointController.text.replaceAll(',', '.')); // Allow comma decimal
  }

  void _calculateAll() {
    setState(() {
      _parseInputs();
      _pressureAltitudeFt = _calculatePressureAltitude();
      _densityAltitudeFt = _calculateDensityAltitude();
      _cloudBaseAglFt = _calculateCloudBase();
      _freezingLevelFt = _calculateFreezingLevel();
    });
  }

  // --- Calculation Functions ---
  double? _calculatePressureAltitude() {
    if (_elevationFt == null || _altimeterSetting == null) return null;
    try {
      if (_altimeterUnit == PressUnit.inHg) {
        // Standard formula approximation for inHg
        return _elevationFt! + (29.92 - _altimeterSetting!) * 1000;
      } else {
        // Standard formula approximation for hPa/mb
        return _elevationFt! + (1013.25 - _altimeterSetting!) * 27; // Approx 27 feet per hPa/mb
      }
    } catch (e) { return null; }
  }

// In _AltitudeAtmosTabState class within lib/widgets/flight_calcs/altitude_atmos_tab.dart

  double? _calculateDensityAltitude() {
    if (_pressureAltitudeFt == null || _oat == null || _dewPoint == null) return null;

    try {
      // --- Ensure inputs are in Celsius for internal calculation ---
      double oatC = (_tempUnit == TempUnit.F) ? ((_oat! - 32) * 5 / 9) : _oat!;
      double dewPointC = (_tempUnit == TempUnit.F) ? ((_dewPoint! - 32) * 5 / 9) : _dewPoint!;

      // Ensure dew point is not greater than OAT (physical impossibility for this formula)
      if (dewPointC > oatC) {
        // Or handle as an error, for now, treat as dry air or return null
        print("Warning: Dew point ($dewPointC C) > OAT ($oatC C). Calculating DA as dry or returning null.");
        // Calculate dry air DA as a fallback if this condition is met.
        double isaTempC_dry = 15.0 - (1.98 * (_pressureAltitudeFt! / 1000.0));
        return _pressureAltitudeFt! + (118.8 * (oatC - isaTempC_dry));
      }


      // --- Constants ---
      const double P0_hPa = 1013.25; // Standard sea level pressure in hPa
      const double T0_K = 288.15;   // Standard sea level temperature in Kelvin
      const double L_std_K_per_m = 0.0065;  // Standard temperature lapse rate in K/m
      const double epsilon = 0.62198; // Ratio of molar masses (water vapor / dry air)

      // --- 1. Convert PA to meters ---
      double paM = _pressureAltitudeFt! * 0.3048;

      // --- 2. Actual Vapor Pressure (e) from Dew Point (Magnus formula, hPa) ---
      // Using exp from dart:math
      double e_hPa = 6.112 * exp((17.67 * dewPointC) / (dewPointC + 243.5));

      // --- 3. Approximate Air Pressure at PA (pressureAtPa_hPa) ---
      // This is the ISA pressure at the given pressure altitude level
      double pressureAtPa_hPa = P0_hPa * pow((1 - (L_std_K_per_m * paM) / T0_K), 5.25588);
      if (pressureAtPa_hPa <= 0) { // Avoid division by zero or invalid pressure
          print("Warning: Calculated pressureAtPa_hPa is non-positive ($pressureAtPa_hPa). Using dry DA.");
          double isaTempC_dry = 15.0 - (2.0 * (_pressureAltitudeFt! / 1000.0));
          return _pressureAltitudeFt! + (120 * (oatC - isaTempC_dry));
      }


      // --- 4. Virtual Temperature (TvK) in Kelvin ---
      double oatK = oatC + 273.15;
      double virtualTempK = oatK / (1 - (e_hPa / pressureAtPa_hPa) * (1 - epsilon));
      double virtualTempC = virtualTempK - 273.15;

      // --- 5. ISA Temperature at PA (isaTempC_at_PA) ---
      // Using 2.0°C/1000ft lapse rate for consistency with simple E6B rules
      double isaTempC_at_PA = 15.0 - (2.0 * (_pressureAltitudeFt! / 1000.0));

      // --- 6. Final Density Altitude (DA) using Virtual Temperature ---
      // This formula structure DA = PA + Factor * (EffectiveTemp - ISA_Temp) is a common way.
      double densityAltitudeFt = _pressureAltitudeFt! + (120 * (virtualTempC - isaTempC_at_PA));

      // print("DEBUG DA: PA_ft=${_pressureAltitudeFt}, OAT_C=$oatC, DP_C=$dewPointC");
      // print("DEBUG DA: e_hPa=$e_hPa, pressureAtPa_hPa=$pressureAtPa_hPa");
      // print("DEBUG DA: virtualTempC=$virtualTempC, isaTempC_at_PA=$isaTempC_at_PA");
      // print("DEBUG DA: Calculated DA=$densityAltitudeFt");

      return densityAltitudeFt;

    } catch (e, s) {
      print("Error in _calculateDensityAltitude: $e\n$s");
      return null; // Return null or handle error appropriately
    }
  }

  double? _calculateCloudBase() {
     if (_oat == null || _dewPoint == null) return null;
     try {
        double tempForCalc = _oat!;
        double dewPointForCalc = _dewPoint!;
        double spreadRate = 2.5; // Celsius spread rate per 1000ft

        if (_tempUnit == TempUnit.F) {
           spreadRate = 4.4; // Fahrenheit spread rate per 1000ft
        } else {
           // Ensure temps are Celsius if unit is C (no conversion needed)
        }
        // Calculate spread in the selected unit
        double spread = tempForCalc - dewPointForCalc;
        if (spread < 0) return null; // Invalid input

        return (spread / spreadRate) * 1000; // Result in Feet AGL
     } catch (e) { return null; }
  }

   double? _calculateFreezingLevel() {
      if (_oat == null || _elevationFt == null) return null;
      try {
        double oatC = (_tempUnit == TempUnit.F) ? ((_oat! - 32) * 5 / 9) : _oat!;
        if (oatC <= 0) return _elevationFt; // Already freezing or below at surface
        // Estimate using standard lapse rate 2°C per 1000 ft
        double heightAboveStationFt = (oatC / 2.0) * 1000.0;
        return _elevationFt! + heightAboveStationFt; // Approx Freezing Level MSL
      } catch (e) { return null; }
   }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String tempUnitSuffix = _tempUnit == TempUnit.C ? '°C' : '°F';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // --- Inputs Card ---
             Card(
               elevation: 2, margin: const EdgeInsets.only(bottom: 16),
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Text("Inputs", style: Theme.of(context).textTheme.titleLarge),
                     const SizedBox(height: 16),
                     TextField(controller: _elevationController, decoration: const InputDecoration(labelText: 'Field Elevation / Altitude', suffixText: 'ft', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                     const SizedBox(height: 16),
                     Row(children: [
                         Expanded(child: TextField(controller: _altimeterController, decoration: InputDecoration(labelText: 'Altimeter Setting', border: const OutlineInputBorder(), suffixText: _altimeterUnit == PressUnit.inHg ? 'inHg' : 'hPa'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                         const SizedBox(width: 8),
                         ToggleButtons( // Keep ToggleButtons for simple two-way switch
                           isSelected: [_altimeterUnit == PressUnit.inHg, _altimeterUnit == PressUnit.hPa],
                           onPressed: (index) { setState(() { _altimeterUnit = (index == 0) ? PressUnit.inHg : PressUnit.hPa; _calculateAll(); }); },
                           children: const [Text('inHg'), Text('hPa')],
                           constraints: const BoxConstraints(minHeight: 40.0, minWidth: 50.0), borderRadius: BorderRadius.circular(8),
                           // Add style for border consistency
                            borderWidth: 1.0,
                            borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                            selectedBorderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                         )
                       ],),
                      const SizedBox(height: 16),
                      Row(children: [
                         Expanded(child: TextField(controller: _tempController, decoration: InputDecoration(labelText: 'Temperature (OAT)', border: const OutlineInputBorder(), suffixText: tempUnitSuffix), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))])),
                         const SizedBox(width: 8),
                         ToggleButtons(
                           isSelected: [_tempUnit == TempUnit.C, _tempUnit == TempUnit.F],
                           onPressed: (index) { setState(() { _tempUnit = (index == 0) ? TempUnit.C : TempUnit.F; _calculateAll(); }); },
                           children: const [Text('°C'), Text('°F')],
                            constraints: const BoxConstraints(minHeight: 40.0, minWidth: 50.0), borderRadius: BorderRadius.circular(8),
                             borderWidth: 1.0,
                             borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                             selectedBorderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                         )
                       ],),
                     const SizedBox(height: 16),
                     TextField(controller: _dewPointController, decoration: InputDecoration(labelText: 'Dew Point', border: const OutlineInputBorder(), suffixText: tempUnitSuffix), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))]),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 10), // Reduced space before results

             // --- Results Card ---
              Card(
               elevation: 2,
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text("Calculated Values", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildResultRow("Pressure Altitude:", _pressureAltitudeFt, "ft"),
                      _buildResultRow("Density Altitude:", _densityAltitudeFt, "ft"),
                      _buildResultRow("Cloud Base (AGL approx):", _cloudBaseAglFt, "ft"),
                      _buildResultRow("Freezing Level (MSL approx):", _freezingLevelFt, "ft"),
                   ],),),),
          ],
        ),
      ),
    );
  }

  // Helper for displaying results
  Widget _buildResultRow(String label, double? value, String unit) {
     // ... (Keep existing helper widget) ...
      return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0),
       child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
           Text(label, style: Theme.of(context).textTheme.titleMedium),
           Text( value != null ? "${value.round()} $unit" : "--", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
         ],),);
  }
}