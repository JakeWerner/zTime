// lib/widgets/converters/speed_converter_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SpeedUnit { kts, mph, kph } // Knots, Miles per Hour, Kilometers per Hour

class SpeedConverterTab extends StatefulWidget {
  const SpeedConverterTab({super.key});

  @override
  State<SpeedConverterTab> createState() => _SpeedConverterTabState();
}

class _SpeedConverterTabState extends State<SpeedConverterTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _inputController = TextEditingController();
  double? _inputValue;
  double? _result;
  SpeedUnit _fromUnit = SpeedUnit.kts; // Default From: Knots
  SpeedUnit _toUnit = SpeedUnit.kph;   // Default To: Kilometers per Hour

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
      _inputValue = double.tryParse(_inputController.text);
      _calculateResult();
    });
  }

  void _calculateResult() {
    if (_inputValue == null) {
      _result = null; return;
    }
    _result = _convertSpeed(_inputValue!, _fromUnit, _toUnit);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculateResult();
    });
  }

  double? _convertSpeed(double value, SpeedUnit from, SpeedUnit to) {
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

  String _unitToString(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.kts: return "Knots (KTS)";
      case SpeedUnit.mph: return "Miles/Hour (MPH)";
      case SpeedUnit.kph: return "Kilometers/Hour (KPH)";
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
              decoration: const InputDecoration(labelText: 'Enter Speed', hintText: 'e.g., 120', border: OutlineInputBorder(), suffixIcon: Icon(Icons.speed)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<SpeedUnit>(
              value: _fromUnit,
              decoration: const InputDecoration(labelText: 'From Unit', border: UnderlineInputBorder()),
              items: SpeedUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (SpeedUnit? newValue) { if (newValue != null) { setState(() { _fromUnit = newValue; _calculateResult(); }); } },
              isExpanded: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: IconButton(icon: const Icon(Icons.swap_vert), iconSize: 28.0, tooltip: 'Swap Units', onPressed: _swapUnits, color: Theme.of(context).colorScheme.primary),
            ),
            DropdownButtonFormField<SpeedUnit>(
              value: _toUnit,
              decoration: const InputDecoration(labelText: 'To Unit', border: UnderlineInputBorder()),
              items: SpeedUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (SpeedUnit? newValue) { if (newValue != null) { setState(() { _toUnit = newValue; _calculateResult(); }); } },
              isExpanded: true,
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                 Text('Result', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor)),
                 const SizedBox(height: 4),
                 Text(_result != null ? _result!.toStringAsFixed(2) : "--", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ),
    );
  }
}