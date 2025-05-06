// lib/widgets/flight_calcs/fuel_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ztime/providers/theme_provider.dart';

enum FuelCalcMode { endurance, required, rate }
enum FuelUnit { gal, L } // US Gallons, Liters

class FuelTab extends StatefulWidget {
  const FuelTab({super.key});

  @override
  State<FuelTab> createState() => _FuelTabState();
}

class _FuelTabState extends State<FuelTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _fuelAvailController = TextEditingController();
  final TextEditingController _burnRateController = TextEditingController();
  final TextEditingController _timeHoursController = TextEditingController();
  final TextEditingController _timeMinutesController = TextEditingController();
  final TextEditingController _fuelUsedController = TextEditingController();

  FuelCalcMode _mode = FuelCalcMode.endurance;
  FuelUnit _fuelUnit = FuelUnit.gal;
  String _resultText = '--';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fuelAvailController.addListener(_calculate);
    _burnRateController.addListener(_calculate);
    _timeHoursController.addListener(_calculate);
    _timeMinutesController.addListener(_calculate);
    _fuelUsedController.addListener(_calculate);
    _calculate();
  }

  @override
  void dispose() {
    // Dispose all controllers...
    _fuelAvailController.removeListener(_calculate);
    _burnRateController.removeListener(_calculate);
    _timeHoursController.removeListener(_calculate);
    _timeMinutesController.removeListener(_calculate);
    _fuelUsedController.removeListener(_calculate);
    _fuelAvailController.dispose();
    _burnRateController.dispose();
    _timeHoursController.dispose();
    _timeMinutesController.dispose();
    _fuelUsedController.dispose();
    super.dispose();
  }

  void _calculate() {
    // ... (Calculation logic remains the same as previous version) ...
     setState(() {
      final double? fuelAvail = double.tryParse(_fuelAvailController.text);
      final double? burnRate = double.tryParse(_burnRateController.text);
      final double? hours = double.tryParse(_timeHoursController.text);
      final double? minutes = double.tryParse(_timeMinutesController.text);
      final double? fuelUsed = double.tryParse(_fuelUsedController.text);
      double? timeTotalHours;
      if (hours != null || minutes != null) { timeTotalHours = (hours ?? 0) + ((minutes ?? 0) / 60.0); }
      String currentResult = '--'; String fuelUnitStr = _fuelUnit == FuelUnit.gal ? 'Gal' : 'L';
      String rateUnitStr = _fuelUnit == FuelUnit.gal ? 'Gal/Hr' : 'L/Hr';
      try {
        switch (_mode) {
          case FuelCalcMode.endurance:
            if (fuelAvail != null && burnRate != null && burnRate > 0) {
              double enduranceHours = fuelAvail / burnRate; int totalMinutes = (enduranceHours * 60).round();
              int ehours = totalMinutes ~/ 60; int emins = totalMinutes % 60;
              currentResult = "${ehours}h ${emins}m";
            } break;
          case FuelCalcMode.required:
            if (burnRate != null && timeTotalHours != null && timeTotalHours >= 0) {
              double fuelNeeded = burnRate * timeTotalHours;
              currentResult = "${fuelNeeded.toStringAsFixed(1)} $fuelUnitStr";
            } break;
          case FuelCalcMode.rate:
            if (fuelUsed != null && timeTotalHours != null && timeTotalHours > 0) {
              double calculatedRate = fuelUsed / timeTotalHours;
              currentResult = "${calculatedRate.toStringAsFixed(1)} $rateUnitStr";
            } break;
        }
      } catch (e) { debugPrint("Fuel Calculation Error: $e"); currentResult = 'Error'; }
      _resultText = currentResult;
    });
  }

  // Helper to build time input row
  Widget _buildTimeInputRow({required bool isEnabled}) {
    Color? fillColor = isEnabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3);
     return Row(
       children: [
        Expanded(child: TextField(controller: _timeHoursController, enabled: isEnabled, decoration: InputDecoration(labelText: "Time (H)", suffixText: "hr", border: const OutlineInputBorder(), filled: !isEnabled, fillColor: fillColor), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text(":")),
        Expanded(child: TextField(controller: _timeMinutesController, enabled: isEnabled, decoration: InputDecoration(labelText: "Time (M)", suffixText: "min", border: const OutlineInputBorder(), filled: !isEnabled, fillColor: fillColor), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
      ],
     );
  }

  // Helper to build generic input field
   Widget _buildFuelInputField({
    required TextEditingController controller,
    required String label,
    required String unitLabel,
    required bool isEnabled,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(), // <-- Ensure OutlineInputBorder
        suffixText: unitLabel,
        filled: !isEnabled,
        fillColor: isEnabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      enabled: isEnabled,
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    String fuelUnitSuffix = _fuelUnit == FuelUnit.gal ? 'Gal' : 'L';
    String rateUnitSuffix = _fuelUnit == FuelUnit.gal ? 'Gal/Hr' : 'L/Hr';
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final MaterialColor accentColor = themeProvider.primaryColor;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
       onTap: () => FocusScope.of(context).unfocus(),
       child: SingleChildScrollView(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Text("Calculate:", style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             SegmentedButton<FuelCalcMode>(
               segments: const <ButtonSegment<FuelCalcMode>>[
                 ButtonSegment<FuelCalcMode>(value: FuelCalcMode.endurance, label: Text('Max Time'), icon: Icon(Icons.timer_outlined)),
                 ButtonSegment<FuelCalcMode>(value: FuelCalcMode.required, label: Text('Fuel Req.'), icon: Icon(Icons.local_gas_station_outlined)),
                 ButtonSegment<FuelCalcMode>(value: FuelCalcMode.rate, label: Text('Burn Rate'), icon: Icon(Icons.speed_outlined)),
               ],
               selected: {_mode},
               onSelectionChanged: (Set<FuelCalcMode> newSelection) {
                 setState(() { _mode = newSelection.first; _calculate(); });
               },
                // --- Add Style for Border ---
                style: SegmentedButton.styleFrom(
                  // --- Overall border for the button group (from previous fix) ---
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.8),
                    width: 1.0,
                  ),

                  // --- Color for SELECTED segment's icon and text ---S
                  selectedForegroundColor: accentColor,

                  // --- Background color for SELECTED segment ---
                  selectedBackgroundColor: accentColor.withOpacity(0.12),

                  // --- Color for UNSELECTED segment's icon and text ---
                  foregroundColor: colorScheme.onSurface.withOpacity(0.7),

                  // --- Background color for UNSELECTED segments ---
                  backgroundColor: Colors.transparent,
                ),
               // --- End Style ---
             ),
             const SizedBox(height: 20),

             // --- Single Unit Selection Row ---
             ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.opacity), // Drop icon
                title: const Text('Fuel Units'),
                trailing: DropdownButton<FuelUnit>( // Keep this standard dropdown
                   value: _fuelUnit,
                   items: FuelUnit.values.map((u) => DropdownMenuItem( value: u, child: Text(u == FuelUnit.gal ? 'Gallons (US)' : 'Liters'))).toList(),
                   onChanged: (FuelUnit? val) { if (val != null) { setState(() { _fuelUnit = val; _calculate(); }); } },
                 ),
             ),
             const Divider(height: 20),

             // --- Input Fields ---
             _buildFuelInputField(controller: _fuelAvailController, label: "Fuel Available", unitLabel: fuelUnitSuffix, isEnabled: _mode == FuelCalcMode.endurance),
             const SizedBox(height: 16),
             _buildFuelInputField(controller: _burnRateController, label: "Fuel Burn Rate", unitLabel: rateUnitSuffix, isEnabled: _mode == FuelCalcMode.endurance || _mode == FuelCalcMode.required),
             const SizedBox(height: 16),
             _buildTimeInputRow(isEnabled: _mode == FuelCalcMode.required || _mode == FuelCalcMode.rate),
             const SizedBox(height: 16),
             _buildFuelInputField(controller: _fuelUsedController, label: "Fuel Used", unitLabel: fuelUnitSuffix, isEnabled: _mode == FuelCalcMode.rate),

             const SizedBox(height: 30),

             // --- Result Display ---
              Center(
                child: Column(
                  children: [
                     Text( 'Calculated ${ _mode == FuelCalcMode.endurance ? 'Max Time' : (_mode == FuelCalcMode.required ? 'Fuel Required' : 'Burn Rate') }', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor),),
                     const SizedBox(height: 4),
                     Text( _resultText, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
                  ],
                ),
              ),
           ],
         ),
       ),
    );
  }
}