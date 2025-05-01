// lib/widgets/flight_calcs/altitude_atmos_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  double? _calculateDensityAltitude() {
    if (_pressureAltitudeFt == null || _oat == null) return null;
    try {
      double oatC = (_tempUnit == TempUnit.F) ? ((_oat! - 32) * 5 / 9) : _oat!;
      double isaTempC = 15.0 - (2 * (_pressureAltitudeFt! / 1000.0));
      return _pressureAltitudeFt! + (120 * (oatC - isaTempC)); // Approx 120 ft per degree C deviation
    } catch (e) { return null; }
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