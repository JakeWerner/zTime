// lib/widgets/flight_calcs/tsd_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ztime/providers/theme_provider.dart';

enum TsdMode { calculateTime, calculateSpeed, calculateDistance }

class TsdTab extends StatefulWidget {
  const TsdTab({super.key});

  @override
  State<TsdTab> createState() => _TsdTabState();
}

class _TsdTabState extends State<TsdTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _speedController = TextEditingController();
  final TextEditingController _timeHoursController = TextEditingController();
  final TextEditingController _timeMinutesController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  TsdMode _mode = TsdMode.calculateTime;

  double? _speedValue; // Knots
  double? _timeValue; // Total Minutes
  double? _distanceValue; // Nautical Miles

  String _resultText = '--';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _speedController.addListener(_calculate);
    _timeHoursController.addListener(_calculate);
    _timeMinutesController.addListener(_calculate);
    _distanceController.addListener(_calculate);
  }

  @override
  void dispose() {
    _speedController.removeListener(_calculate);
    _timeHoursController.removeListener(_calculate);
    _timeMinutesController.removeListener(_calculate);
    _distanceController.removeListener(_calculate);
    _speedController.dispose();
    _timeHoursController.dispose();
    _timeMinutesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _parseInputs() {
    _speedValue = double.tryParse(_speedController.text);
    final double? hours = double.tryParse(_timeHoursController.text);
    final double? minutes = double.tryParse(_timeMinutesController.text);
    if (hours != null || minutes != null) {
      _timeValue = (hours ?? 0) * 60 + (minutes ?? 0);
    } else {
      _timeValue = null;
    }
    _distanceValue = double.tryParse(_distanceController.text);
  }

  void _calculate() {
    setState(() {
      _parseInputs();
      double? calculatedValue;
      String resultUnit = "";

      try {
        if (_mode == TsdMode.calculateTime) {
          if (_speedValue != null && _speedValue! > 0 && _distanceValue != null) {
            calculatedValue = (_distanceValue! / _speedValue!) * 60; // Result in minutes
            int totalMinutes = calculatedValue.round();
            int hours = totalMinutes ~/ 60;
            int mins = totalMinutes % 60;
            _resultText = "${hours}h ${mins}m";
          } else { _resultText = '--'; }
        } else if (_mode == TsdMode.calculateSpeed) {
          if (_timeValue != null && _timeValue! > 0 && _distanceValue != null) {
            calculatedValue = (_distanceValue! / _timeValue!) * 60; // Result in knots
            resultUnit = " kts";
             _resultText = "${calculatedValue.toStringAsFixed(1)}$resultUnit";
          } else { _resultText = '--'; }
        } else { // Calculate Distance
          if (_speedValue != null && _timeValue != null && _timeValue! > 0) {
            calculatedValue = _speedValue! * (_timeValue! / 60); // Result in NM
            resultUnit = " NM";
             _resultText = "${calculatedValue.toStringAsFixed(1)}$resultUnit";
          } else { _resultText = '--'; }
        }
      } catch (e) {
        debugPrint("TSD Calculation Error: $e");
        _resultText = 'Error';
      }
    });
  }

  // Helper to build input fields consistently
  Widget _buildInputField({
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

  // Helper for H:M input
  Widget _buildTimeInputField({required bool isEnabled}) {
    Color? fillColor = isEnabled ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3);
    return Row(
      children: [
        Expanded(child: TextField(controller: _timeHoursController, enabled: isEnabled, decoration: InputDecoration(labelText: "Time (H)", suffixText: "hr", border: const OutlineInputBorder(), filled: !isEnabled, fillColor: fillColor), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text(":")),
        Expanded(child: TextField(controller: _timeMinutesController, enabled: isEnabled, decoration: InputDecoration(labelText: "Time (M)", suffixText: "min", border: const OutlineInputBorder(), filled: !isEnabled, fillColor: fillColor), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
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
               SegmentedButton<TsdMode>(
                 segments: const <ButtonSegment<TsdMode>>[
                   ButtonSegment<TsdMode>(value: TsdMode.calculateTime, label: Text('Time'), icon: Icon(Icons.timer_outlined)),
                   ButtonSegment<TsdMode>(value: TsdMode.calculateSpeed, label: Text('Speed'), icon: Icon(Icons.speed_outlined)),
                   ButtonSegment<TsdMode>(value: TsdMode.calculateDistance, label: Text('Distance'), icon: Icon(Icons.straighten_outlined)),
                 ],
                 selected: {_mode},
                 onSelectionChanged: (Set<TsdMode> newSelection) {
                   setState(() { _mode = newSelection.first; _calculate(); });
                 },
                 // --- Add Style for Border ---
                style: SegmentedButton.styleFrom(
                  // --- Overall border for the button group (from previous fix) ---
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.8), // Or Theme.of(context).dividerColor
                    width: 1.0,
                  ),

                  // --- Color for SELECTED segment's icon and text ---S
                  selectedForegroundColor: accentColor,

                  // --- Background color for SELECTED segment ---
                  selectedBackgroundColor: accentColor.withOpacity(0.12), // A light, translucent shade of the accent color

                  // --- Color for UNSELECTED segment's icon and text ---
                  foregroundColor: colorScheme.onSurface.withOpacity(0.7),

                  // --- Background color for UNSELECTED segments ---
                  backgroundColor: Colors.transparent,
                ),
                 // --- End Style ---
               ),
               const SizedBox(height: 24), // Increased spacing

               _buildInputField(
                  controller: _speedController,
                  label: "Speed (Ground Speed)",
                  unitLabel: "kts", // Assuming knots for now
                  isEnabled: _mode != TsdMode.calculateSpeed,
               ),
               const SizedBox(height: 16),

               _buildTimeInputField(isEnabled: _mode != TsdMode.calculateTime),
               const SizedBox(height: 16),

               _buildInputField(
                  controller: _distanceController,
                  label: "Distance",
                  unitLabel: "NM", // Assuming Nautical Miles for now
                  isEnabled: _mode != TsdMode.calculateDistance,
                ),
                const SizedBox(height: 30),

                // Result Display
                Center(
                  child: Column(
                    children: [
                       Text( 'Calculated ${ _mode.name.replaceFirst('calculate', '') }', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor)),
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