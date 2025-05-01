// lib/widgets/flight_calcs/wind_heading_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // For sin, cos, asin, sqrt, pow, pi

// Enums
enum SpeedUnit { kts, mph }
// Using boolean for ToggleButtons state
// enum VariationDirection { east, west } // Removed

class WindHeadingTab extends StatefulWidget {
  const WindHeadingTab({super.key});

  @override
  State<WindHeadingTab> createState() => _WindHeadingTabState();
}

class _WindHeadingTabState extends State<WindHeadingTab> with AutomaticKeepAliveClientMixin {
  // --- Controllers ---
  final TextEditingController _wcHdgController = TextEditingController();
  final TextEditingController _wcWindDirController = TextEditingController();
  final TextEditingController _wcWindSpdController = TextEditingController();
  final TextEditingController _navTcController = TextEditingController();
  final TextEditingController _navTasController = TextEditingController();
  final TextEditingController _navWindDirController = TextEditingController();
  final TextEditingController _navWindSpdController = TextEditingController();
  final TextEditingController _navVarController = TextEditingController();
  final TextEditingController _navDevController = TextEditingController();

  // --- State ---
  String _headwindResult = "--";
  String _crosswindResult = "--";
  SpeedUnit _speedUnit = SpeedUnit.kts;
  bool _isVariationEast = true; // Boolean state for E/W ToggleButtons
  String _wcaResult = "--";
  String _trueHeadingResult = "--";
  String _groundSpeedResult = "--";
  String _magHeadingResult = "--";
  String _compHeadingResult = "--";

  @override
  bool get wantKeepAlive => true;

   @override
  void initState() {
    super.initState();
    // Add listeners
    _wcHdgController.addListener(_calculateWindComponents);
    _wcWindDirController.addListener(_calculateWindComponents);
    _wcWindSpdController.addListener(_calculateWindComponents);
    _navTcController.addListener(_calculateAllNav);
    _navTasController.addListener(_calculateAllNav);
    _navWindDirController.addListener(_calculateAllNav);
    _navWindSpdController.addListener(_calculateAllNav);
    _navVarController.addListener(_calculateAllNav);
    _navDevController.addListener(_calculateAllNav);

    // Initial calculations
    _calculateWindComponents();
    _calculateAllNav();
  }

   @override
  void dispose() {
    // Remove listeners and dispose controllers
    _wcHdgController.removeListener(_calculateWindComponents);
    _wcWindDirController.removeListener(_calculateWindComponents);
    _wcWindSpdController.removeListener(_calculateWindComponents);
    _navTcController.removeListener(_calculateAllNav);
    _navTasController.removeListener(_calculateAllNav);
    _navWindDirController.removeListener(_calculateAllNav);
    _navWindSpdController.removeListener(_calculateAllNav);
    _navVarController.removeListener(_calculateAllNav);
    _navDevController.removeListener(_calculateAllNav);

    _wcHdgController.dispose(); _wcWindDirController.dispose(); _wcWindSpdController.dispose();
    _navTcController.dispose(); _navTasController.dispose(); _navWindDirController.dispose();
    _navWindSpdController.dispose(); _navVarController.dispose(); _navDevController.dispose();
    super.dispose();
  }

  // --- Calculations ---
  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
  double _radiansToDegrees(double radians) => (radians * (180.0 / pi));

  // --- Wind Component Calculation ---
  void _calculateWindComponents() {
     final double? heading = double.tryParse(_wcHdgController.text);
     final double? windDir = double.tryParse(_wcWindDirController.text);
     final double? windSpd = double.tryParse(_wcWindSpdController.text);

     String newHeadwindResult = "--";
     String newCrosswindResult = "--";

     if (heading != null && windDir != null && windSpd != null && windSpd >= 0) {
       double angleDiffDegrees = windDir - heading;
       while (angleDiffDegrees <= -180) angleDiffDegrees += 360;
       while (angleDiffDegrees > 180) angleDiffDegrees -= 360;
       double angleDiffRadians = _degreesToRadians(angleDiffDegrees);

       // Component along heading axis. Negative = Opposing = Headwind. Positive = Assisting = Tailwind.
       double alongAxisComponent = windSpd * cos(angleDiffRadians);
       double crossAxisComponent = windSpd * sin(angleDiffRadians);

       // --- CORRECTED Headwind/Tailwind Logic ---
       if (alongAxisComponent <= 0) { // Negative or zero component means headwind
         newHeadwindResult = "Headwind ${(-alongAxisComponent).toStringAsFixed(1)} kts";
       } else { // Positive component means tailwind
         newHeadwindResult = "Tailwind ${alongAxisComponent.toStringAsFixed(1)} kts";
       }
       // --- End Correction ---

       if (crossAxisComponent >= 0) { // Positive = From Right
          newCrosswindResult = "From Right ${crossAxisComponent.toStringAsFixed(1)} kts";
       } else { // Negative = From Left
          newCrosswindResult = "From Left ${(-crossAxisComponent).toStringAsFixed(1)} kts";
       }
     }
      if (mounted && (_headwindResult != newHeadwindResult || _crosswindResult != newCrosswindResult)) {
         setState(() {
           _headwindResult = newHeadwindResult;
           _crosswindResult = newCrosswindResult;
         });
      }
  }

  // --- Combined Nav Calculation ---
  void _calculateAllNav() {
      String wcaStr = "--"; String thStr = "--"; String gsStr = "--";
      String mhStr = "--"; String chStr = "--";
      double? calculatedThDeg;

      final double? tc = double.tryParse(_navTcController.text);
      final double? tas = double.tryParse(_navTasController.text);
      final double? windDir = double.tryParse(_navWindDirController.text);
      final double? windSpd = double.tryParse(_navWindSpdController.text);
      final String speedUnitSuffix = _speedUnit == SpeedUnit.kts ? "kts" : "mph";
      final double? variation = double.tryParse(_navVarController.text);
      final double? deviation = double.tryParse(_navDevController.text);

      // Calculate WCA, TH, GS
      if (tc != null && tas != null && tas > 0 && windDir != null && windSpd != null && windSpd >= 0) {
         try {
           double tcRad = _degreesToRadians(tc); double windDirRad = _degreesToRadians(windDir);
           double windAngleDiffRad = windDirRad - tcRad; double sinWCA = (windSpd / tas) * sin(windAngleDiffRad);
           if (sinWCA.abs() <= 1.0) {
              double wcaRad = asin(sinWCA); double wcaDeg = _radiansToDegrees(wcaRad);
              wcaStr = "${wcaDeg.abs().toStringAsFixed(0)}° ${wcaDeg >= 0 ? 'R' : 'L'}";
              double thRad = tcRad + wcaRad; calculatedThDeg = (_radiansToDegrees(thRad) + 360) % 360;
              thStr = "${calculatedThDeg.toStringAsFixed(0)}°";
              double windToRad = _degreesToRadians(windDir + 180); double windNorthComp = windSpd * cos(windToRad); double windEastComp = windSpd * sin(windToRad);
              double aircraftNorthComp = tas * cos(thRad); double aircraftEastComp = tas * sin(thRad);
              double gsNorthComp = aircraftNorthComp + windNorthComp; double gsEastComp = aircraftEastComp + windEastComp;
              double gs = sqrt(pow(gsNorthComp, 2) + pow(gsEastComp, 2)); gsStr = "${gs.toStringAsFixed(1)} $speedUnitSuffix";
           } else { wcaStr = "Error"; thStr = "Impossible"; gsStr = "(XW > TAS)"; }
         } catch (e) { print("Heading/GS Calc Error: $e"); wcaStr = "Error"; thStr = "Error"; gsStr = "Error"; } }

      // Calculate MH, CH
      if (calculatedThDeg != null && variation != null) {
          double mhDeg = (_isVariationEast) ? (calculatedThDeg - variation) : (calculatedThDeg + variation);
          mhDeg = (mhDeg + 360) % 360; mhStr = "${mhDeg.toStringAsFixed(0)}°";
          if (deviation != null) { double chDeg = mhDeg + deviation; chDeg = (chDeg + 360) % 360; chStr = "${chDeg.toStringAsFixed(0)}°"; } }

      // --- Update state unconditionally if mounted ---
      //print("[DEBUG WIDGET] Setting Nav State: WCA='$wcaStr', TH='$thStr', GS='$gsStr', MH='$mhStr', CH='$chStr'");
      if (mounted) {
        setState(() {
          _wcaResult = wcaStr; _trueHeadingResult = thStr; _groundSpeedResult = gsStr;
          _magHeadingResult = mhStr; _compHeadingResult = chStr;
        });
      }
      // --- End Update ---
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive
    String speedUnitSuffix = _speedUnit == SpeedUnit.kts ? "kts" : "mph";

     return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Wind Components Section ---
            Card(
              elevation: 2, margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                     Text("Wind Components", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(controller: _wcHdgController, decoration: const InputDecoration(labelText: 'Runway / Course Heading', suffixText: '°', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 16),
                      Row(children: [
                          Expanded(child: TextField(controller: _wcWindDirController, decoration: const InputDecoration(labelText: 'Wind Direction (FROM)', suffixText: '°', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                          const SizedBox(width: 8), const Text('@', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _wcWindSpdController, decoration: const InputDecoration(labelText: 'Wind Speed', suffixText: 'kts', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                      ]),
                       const SizedBox(height: 16),
                       _buildResultRow("Head/Tailwind:", _headwindResult),
                       _buildResultRow("Crosswind:", _crosswindResult),
                   ],),),
            ),
            const SizedBox(height: 10),

            // --- Heading / Ground Speed Section ---
             Card(
              elevation: 2,
              child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Text("Heading & Groundspeed", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Center(
                        child: SegmentedButton<SpeedUnit>(
                           // Ensure segments are defined correctly
                           segments: const <ButtonSegment<SpeedUnit>>[
                             ButtonSegment<SpeedUnit>(value: SpeedUnit.kts, label: Text('Knots')),
                             ButtonSegment<SpeedUnit>(value: SpeedUnit.mph, label: Text('MPH')),
                           ],
                           selected: {_speedUnit},
                           onSelectionChanged: (Set<SpeedUnit> newSelection) {
                             setState(() { _speedUnit = newSelection.first; _calculateAllNav(); });
                           },
                           style: SegmentedButton.styleFrom( side: BorderSide( color: Theme.of(context).colorScheme.outline.withOpacity(0.8), width: 1.0), minimumSize: const Size(100, 36)),
                         ),
                      ),
                      const SizedBox(height: 20),
                      TextField(controller: _navTcController, decoration: const InputDecoration(labelText: 'True Course (TC)', suffixText: '°', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 16),
                      TextField(controller: _navTasController, decoration: InputDecoration(labelText: 'True Airspeed (TAS)', suffixText: speedUnitSuffix, border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                      const SizedBox(height: 16),
                      Row(children: [
                          Expanded(child: TextField(controller: _navWindDirController, decoration: const InputDecoration(labelText: 'Wind Direction (FROM)', suffixText: '°', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                          const SizedBox(width: 8), const Text('@', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _navWindSpdController, decoration: InputDecoration(labelText: 'Wind Speed', suffixText: speedUnitSuffix, border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                      ]),
                       const SizedBox(height: 16),
                       // Variation Row with ToggleButtons
                       Row(
                         children: [
                           Expanded(child: TextField(controller: _navVarController, decoration: const InputDecoration(labelText: 'Variation (VAR)', hintText: 'e.g., 10', suffixText: '°', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])),
                           const SizedBox(width: 8),
                            ToggleButtons(
                               isSelected: [_isVariationEast, !_isVariationEast],
                               onPressed: (index) { setState(() { _isVariationEast = (index == 0); _calculateAllNav(); }); },
                               children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('E')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('W'))],
                               constraints: const BoxConstraints(minHeight: 40.0),
                               borderRadius: BorderRadius.circular(8),
                               borderWidth: 1.0, borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8), selectedBorderColor: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                            )
                         ]
                      ),
                       const SizedBox(height: 16),
                       TextField(controller: _navDevController, decoration: const InputDecoration(labelText: 'Deviation (DEV)', hintText: 'e.g., -2', suffixText: '° (+/-)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))]),
                        const SizedBox(height: 20),
                        // Results
                        Text("Calculated:", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _buildResultRow("Wind Corr Angle (WCA):", _wcaResult),
                        _buildResultRow("True Heading (TH):", _trueHeadingResult),
                        _buildResultRow("Ground Speed (GS):", _groundSpeedResult),
                        _buildResultRow("Magnetic Hdg (MH):", _magHeadingResult),
                        _buildResultRow("Compass Hdg (CH):", _compHeadingResult),
                   ],
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for displaying results
  Widget _buildResultRow(String label, String value) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 4.0),
       child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
           Text(label, style: Theme.of(context).textTheme.bodyLarge),
           Text( value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
         ],),);
  }
}