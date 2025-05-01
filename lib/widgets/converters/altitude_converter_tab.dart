// lib/widgets/converters/altitude_converter_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AltitudeUnit { ft, m } // Feet, Meters

class AltitudeConverterTab extends StatefulWidget {
  const AltitudeConverterTab({super.key});

  @override
  State<AltitudeConverterTab> createState() => _AltitudeConverterTabState();
}

class _AltitudeConverterTabState extends State<AltitudeConverterTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _inputController = TextEditingController();
  double? _inputValue;
  double? _result;
  AltitudeUnit _fromUnit = AltitudeUnit.ft; // Default From: Feet
  AltitudeUnit _toUnit = AltitudeUnit.m;   // Default To: Meters

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
    _result = _convertAltitude(_inputValue!, _fromUnit, _toUnit);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculateResult();
    });
  }

   double? _convertAltitude(double value, AltitudeUnit from, AltitudeUnit to) {
     if (from == to) return value;
     double valueInFt; // Base unit: Feet
      switch (from) {
        case AltitudeUnit.ft: valueInFt = value; break;
        case AltitudeUnit.m: valueInFt = value * 3.28084; break;
     }
     switch (to) {
       case AltitudeUnit.ft: return valueInFt;
       case AltitudeUnit.m: return valueInFt / 3.28084;
     }
   }

  String _unitToString(AltitudeUnit unit) {
    switch (unit) {
      case AltitudeUnit.ft: return "Feet (FT)";
      case AltitudeUnit.m: return "Meters (M)";
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
              decoration: const InputDecoration(labelText: 'Enter Altitude / Elevation', hintText: 'e.g., 10000', border: OutlineInputBorder(), suffixIcon: Icon(Icons.filter_hdr)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<AltitudeUnit>(
              value: _fromUnit,
              decoration: const InputDecoration(labelText: 'From Unit', border: UnderlineInputBorder()),
              items: AltitudeUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (AltitudeUnit? newValue) { if (newValue != null) { setState(() { _fromUnit = newValue; _calculateResult(); }); } },
              isExpanded: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: IconButton(icon: const Icon(Icons.swap_vert), iconSize: 28.0, tooltip: 'Swap Units', onPressed: _swapUnits, color: Theme.of(context).colorScheme.primary),
            ),
            DropdownButtonFormField<AltitudeUnit>(
              value: _toUnit,
              decoration: const InputDecoration(labelText: 'To Unit', border: UnderlineInputBorder()),
              items: AltitudeUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (AltitudeUnit? newValue) { if (newValue != null) { setState(() { _toUnit = newValue; _calculateResult(); }); } },
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