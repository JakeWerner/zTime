// lib/widgets/converters/temperature_converter_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TemperatureUnit { C, F } // Celsius, Fahrenheit

class TemperatureConverterTab extends StatefulWidget {
  const TemperatureConverterTab({super.key});

  @override
  State<TemperatureConverterTab> createState() => _TemperatureConverterTabState();
}

class _TemperatureConverterTabState extends State<TemperatureConverterTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _inputController = TextEditingController();
  double? _inputValue;
  double? _result;
  TemperatureUnit _fromUnit = TemperatureUnit.C; // Default From: Celsius
  TemperatureUnit _toUnit = TemperatureUnit.F;   // Default To: Fahrenheit

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    super.dispose();
  }

   void _onInputChanged() {
    setState(() {
      // Allow negative input for temperature
      _inputValue = double.tryParse(_inputController.text.replaceAll(',', '.')); // Handle comma input
      _calculateResult();
    });
  }

  void _calculateResult() {
    if (_inputValue == null) {
      _result = null; return;
    }
    _result = _convertTemperature(_inputValue!, _fromUnit, _toUnit);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculateResult();
    });
  }

  double? _convertTemperature(double value, TemperatureUnit from, TemperatureUnit to) {
     if (from == to) return value;
     switch (from) {
        case TemperatureUnit.C:
          return (to == TemperatureUnit.F) ? (value * 9 / 5) + 32 : value;
        case TemperatureUnit.F:
          return (to == TemperatureUnit.C) ? (value - 32) * 5 / 9 : value;
     }
  }

  String _unitToString(TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.C: return "Celsius (°C)";
      case TemperatureUnit.F: return "Fahrenheit (°F)";
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             TextField(
               controller: _inputController,
               decoration: const InputDecoration(labelText: 'Enter Temperature', hintText: 'e.g., 25', border: OutlineInputBorder(), suffixIcon: Icon(Icons.thermostat)),
               // Allow negative numbers and decimal point
               keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
               inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
             ),
             const SizedBox(height: 20),
             DropdownButtonFormField<TemperatureUnit>(
               value: _fromUnit,
               decoration: const InputDecoration(labelText: 'From Unit', border: UnderlineInputBorder()),
               items: TemperatureUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
               onChanged: (TemperatureUnit? newValue) { if (newValue != null) { setState(() { _fromUnit = newValue; _calculateResult(); }); } },
               isExpanded: true,
             ),
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 4.0),
               child: IconButton(icon: const Icon(Icons.swap_vert), iconSize: 28.0, tooltip: 'Swap Units', onPressed: _swapUnits, color: Theme.of(context).colorScheme.primary),
             ),
             DropdownButtonFormField<TemperatureUnit>(
               value: _toUnit,
               decoration: const InputDecoration(labelText: 'To Unit', border: UnderlineInputBorder()),
               items: TemperatureUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
               onChanged: (TemperatureUnit? newValue) { if (newValue != null) { setState(() { _toUnit = newValue; _calculateResult(); }); } },
               isExpanded: true,
             ),
             const SizedBox(height: 30),
             Column(
              children: [
                 Text('Result', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor)),
                 const SizedBox(height: 4),
                 Text(_result != null ? _result!.toStringAsFixed(1) : "--", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ),
    );
  }
}