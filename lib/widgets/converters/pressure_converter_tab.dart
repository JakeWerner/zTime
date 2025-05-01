// lib/widgets/converters/pressure_converter_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PressureUnit { inHg, hPa } // Inches of Mercury, Hectopascals (Millibars)

class PressureConverterTab extends StatefulWidget {
  const PressureConverterTab({super.key});

  @override
  State<PressureConverterTab> createState() => _PressureConverterTabState();
}

class _PressureConverterTabState extends State<PressureConverterTab> with AutomaticKeepAliveClientMixin {
 final TextEditingController _inputController = TextEditingController();
  double? _inputValue;
  double? _result;
  PressureUnit _fromUnit = PressureUnit.inHg; // Default From: inHg
  PressureUnit _toUnit = PressureUnit.hPa;   // Default To: hPa

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
    _result = _convertPressure(_inputValue!, _fromUnit, _toUnit);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculateResult();
    });
  }

   double? _convertPressure(double value, PressureUnit from, PressureUnit to) {
      if (from == to) return value;
       double valueInHpa; // Base unit: Hectopascals (hPa / mb)
       switch (from) {
         case PressureUnit.hPa: valueInHpa = value; break;
         case PressureUnit.inHg: valueInHpa = value * 33.86389; break;
       }
       switch (to) {
         case PressureUnit.hPa: return valueInHpa;
         case PressureUnit.inHg: return valueInHpa / 33.86389;
       }
   }

  String _unitToString(PressureUnit unit) {
    switch (unit) {
      case PressureUnit.inHg: return "Inches Hg (inHg)";
      case PressureUnit.hPa: return "Hectopascals (hPa/mb)";
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
               decoration: const InputDecoration(labelText: 'Enter Pressure', hintText: 'e.g., 29.92', border: OutlineInputBorder(), suffixIcon: Icon(Icons.compress)),
               keyboardType: const TextInputType.numberWithOptions(decimal: true),
               inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
             ),
             const SizedBox(height: 20),
             DropdownButtonFormField<PressureUnit>(
               value: _fromUnit,
               decoration: const InputDecoration(labelText: 'From Unit', border: UnderlineInputBorder()),
               items: PressureUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
               onChanged: (PressureUnit? newValue) { if (newValue != null) { setState(() { _fromUnit = newValue; _calculateResult(); }); } },
               isExpanded: true,
             ),
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 4.0),
               child: IconButton(icon: const Icon(Icons.swap_vert), iconSize: 28.0, tooltip: 'Swap Units', onPressed: _swapUnits, color: Theme.of(context).colorScheme.primary),
             ),
             DropdownButtonFormField<PressureUnit>(
               value: _toUnit,
               decoration: const InputDecoration(labelText: 'To Unit', border: UnderlineInputBorder()),
               items: PressureUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_unitToString(unit), overflow: TextOverflow.ellipsis))).toList(),
               onChanged: (PressureUnit? newValue) { if (newValue != null) { setState(() { _toUnit = newValue; _calculateResult(); }); } },
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