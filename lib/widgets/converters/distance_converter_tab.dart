// lib/widgets/converters/distance_converter_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Enum specific to this converter
enum DistanceUnit { nm, sm, km }

class DistanceConverterTab extends StatefulWidget {
  const DistanceConverterTab({super.key});

  @override
  State<DistanceConverterTab> createState() => _DistanceConverterTabState();
}

// Add AutomaticKeepAliveClientMixin to preserve state across tab switches
class _DistanceConverterTabState extends State<DistanceConverterTab> with AutomaticKeepAliveClientMixin {
  // State specific to Distance conversion
  final TextEditingController _inputController = TextEditingController();
  double? _inputValue;
  double? _result;
  DistanceUnit _fromUnit = DistanceUnit.nm;
  DistanceUnit _toUnit = DistanceUnit.km;

  // --- State Preservation ---
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
      _result = null;
      return;
    }
    _result = _convertDistance(_inputValue!, _fromUnit, _toUnit);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculateResult(); // Recalculate after swap
    });
  }

  // --- Conversion Logic ---
  double? _convertDistance(double value, DistanceUnit from, DistanceUnit to) {
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

  // --- Unit to String Helper ---
  String _unitToString(DistanceUnit unit) {
    switch (unit) {
      case DistanceUnit.nm: return "Nautical Miles (NM)";
      case DistanceUnit.sm: return "Statute Miles (SM)";
      case DistanceUnit.km: return "Kilometers (KM)";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for KeepAlive

    // Use GestureDetector + SingleChildScrollView for keyboard dismissal and scrolling
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Field
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Enter Value to Convert',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.straighten), // Ruler icon
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            ),
            const SizedBox(height: 20),

            // "From" Dropdown
            DropdownButtonFormField<DistanceUnit>(
              value: _fromUnit,
              decoration: const InputDecoration(labelText: 'From Unit', border: UnderlineInputBorder()),
              items: DistanceUnit.values.map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (DistanceUnit? newValue) {
                if (newValue != null) { setState(() { _fromUnit = newValue; _calculateResult(); }); }
              },
              isExpanded: true,
            ),

            // Swap Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: IconButton(
                icon: const Icon(Icons.swap_vert),
                iconSize: 28.0,
                tooltip: 'Swap Units',
                onPressed: _swapUnits,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            // "To" Dropdown
            DropdownButtonFormField<DistanceUnit>(
              value: _toUnit,
              decoration: const InputDecoration(labelText: 'To Unit', border: UnderlineInputBorder()),
              items: DistanceUnit.values.map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (DistanceUnit? newValue) {
                if (newValue != null) { setState(() { _toUnit = newValue; _calculateResult(); }); }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 30),

            // Result Display
            Column(
              children: [
                Text(
                  'Result',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  _result != null ? _result!.toStringAsFixed(3) : "--",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}