import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Unit Converter - Design System v2.6
class UnitConverterScreen extends ConsumerStatefulWidget {
  const UnitConverterScreen({super.key});
  @override
  ConsumerState<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

enum ConversionType { length, area, power, temperature, wireGauge }

class _UnitConverterScreenState extends ConsumerState<UnitConverterScreen> {
  ConversionType _type = ConversionType.length;
  final _inputController = TextEditingController();
  String _fromUnit = '';
  String _toUnit = '';
  double? _result;

  @override
  void initState() { super.initState(); _setDefaultUnits(); }

  void _setDefaultUnits() { final units = _getUnits(); if (units.isNotEmpty) { _fromUnit = units[0]; _toUnit = units.length > 1 ? units[1] : units[0]; } }

  List<String> _getUnits() {
    switch (_type) {
      case ConversionType.length: return ['Feet', 'Inches', 'Meters', 'Centimeters', 'Millimeters'];
      case ConversionType.area: return ['Sq Feet', 'Sq Inches', 'Sq Meters', 'Circular Mils', 'Sq mm'];
      case ConversionType.power: return ['Watts', 'Kilowatts', 'Horsepower', 'BTU/hr', 'VA'];
      case ConversionType.temperature: return ['Celsius', 'Fahrenheit', 'Kelvin'];
      case ConversionType.wireGauge: return ['AWG', 'Circular Mils', 'Sq mm'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Unit Converter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildTypeSelector(colors),
            const SizedBox(height: 32),
            _buildInputField(colors),
            const SizedBox(height: 24),
            _buildUnitSelector(colors, label: 'FROM', value: _fromUnit, onChanged: (u) { setState(() => _fromUnit = u); _convert(); }),
            const SizedBox(height: 16),
            Center(child: IconButton(onPressed: _swap, icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(LucideIcons.arrowUpDown, color: colors.accentPrimary)))),
            const SizedBox(height: 16),
            _buildUnitSelector(colors, label: 'TO', value: _toUnit, onChanged: (u) { setState(() => _toUnit = u); _convert(); }),
            const SizedBox(height: 32),
            if (_result != null) _buildResult(colors),
            const SizedBox(height: 24),
            _buildQuickRef(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final labels = {ConversionType.length: 'Length', ConversionType.area: 'Area', ConversionType.power: 'Power', ConversionType.temperature: 'Temp', ConversionType.wireGauge: 'Wire'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: ConversionType.values.map((t) {
        final sel = t == _type;
        return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _type = t; _result = null; _setDefaultUnits(); }); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? colors.accentPrimary : colors.borderSubtle)), child: Text(labels[t]!, style: TextStyle(color: sel ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
        ));
      }).toList()),
    );
  }

  Widget _buildInputField(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: TextField(controller: _inputController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]'))], textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700), decoration: InputDecoration(hintText: '0', hintStyle: TextStyle(color: colors.textTertiary), border: InputBorder.none), onChanged: (_) => _convert()),
    );
  }

  Widget _buildUnitSelector(ZaftoColors colors, {required String label, required String value, required ValueChanged<String> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Expanded(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: _getUnits().map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => onChanged(v!))),
      ]),
    );
  }

  Widget _buildResult(ZaftoColors colors) {
    String formatted;
    if (_result!.abs() >= 1000000) { formatted = _result!.toStringAsExponential(4); }
    else if (_result!.abs() < 0.001 && _result != 0) { formatted = _result!.toStringAsExponential(4); }
    else { formatted = _result!.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''); }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(formatted, style: TextStyle(color: colors.accentSuccess, fontSize: 36, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(_toUnit, style: TextStyle(color: colors.textTertiary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildQuickRef(ZaftoColors colors) {
    List<String> refs;
    switch (_type) {
      case ConversionType.length: refs = ['1 ft = 12 in', '1 m = 3.281 ft', '1 in = 25.4 mm']; break;
      case ConversionType.area: refs = ['1 sq ft = 144 sq in', '1 kcmil = 1000 cmil', '1 sq mm = 1973 cmil']; break;
      case ConversionType.power: refs = ['1 HP = 746 W', '1 kW = 1000 W', '1 BTU/hr = 0.293 W']; break;
      case ConversionType.temperature: refs = ['0°C = 32°F', '100°C = 212°F', '0 K = -273.15°C']; break;
      case ConversionType.wireGauge: refs = ['10 AWG = 10,380 cmil', '4/0 AWG = 211,600 cmil', '500 kcmil = 253 mm²']; break;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('QUICK REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...refs.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(r, style: TextStyle(color: colors.textSecondary, fontSize: 13)))),
      ]),
    );
  }

  void _convert() {
    final input = double.tryParse(_inputController.text);
    if (input == null) { setState(() => _result = null); return; }
    double result;
    switch (_type) {
      case ConversionType.length: result = _convertLength(input, _fromUnit, _toUnit); break;
      case ConversionType.area: result = _convertArea(input, _fromUnit, _toUnit); break;
      case ConversionType.power: result = _convertPower(input, _fromUnit, _toUnit); break;
      case ConversionType.temperature: result = _convertTemperature(input, _fromUnit, _toUnit); break;
      case ConversionType.wireGauge: result = _convertWireGauge(input, _fromUnit, _toUnit); break;
    }
    setState(() => _result = result);
  }

  double _convertLength(double val, String from, String to) {
    double meters;
    switch (from) { case 'Feet': meters = val * 0.3048; break; case 'Inches': meters = val * 0.0254; break; case 'Meters': meters = val; break; case 'Centimeters': meters = val / 100; break; case 'Millimeters': meters = val / 1000; break; default: meters = val; }
    switch (to) { case 'Feet': return meters / 0.3048; case 'Inches': return meters / 0.0254; case 'Meters': return meters; case 'Centimeters': return meters * 100; case 'Millimeters': return meters * 1000; default: return meters; }
  }

  double _convertArea(double val, String from, String to) {
    double sqm;
    switch (from) { case 'Sq Feet': sqm = val * 0.0929; break; case 'Sq Inches': sqm = val * 0.00064516; break; case 'Sq Meters': sqm = val; break; case 'Circular Mils': sqm = val * 5.067e-10; break; case 'Sq mm': sqm = val * 1e-6; break; default: sqm = val; }
    switch (to) { case 'Sq Feet': return sqm / 0.0929; case 'Sq Inches': return sqm / 0.00064516; case 'Sq Meters': return sqm; case 'Circular Mils': return sqm / 5.067e-10; case 'Sq mm': return sqm / 1e-6; default: return sqm; }
  }

  double _convertPower(double val, String from, String to) {
    double watts;
    switch (from) { case 'Watts': watts = val; break; case 'Kilowatts': watts = val * 1000; break; case 'Horsepower': watts = val * 746; break; case 'BTU/hr': watts = val * 0.293; break; case 'VA': watts = val; break; default: watts = val; }
    switch (to) { case 'Watts': return watts; case 'Kilowatts': return watts / 1000; case 'Horsepower': return watts / 746; case 'BTU/hr': return watts / 0.293; case 'VA': return watts; default: return watts; }
  }

  double _convertTemperature(double val, String from, String to) {
    double celsius;
    switch (from) { case 'Celsius': celsius = val; break; case 'Fahrenheit': celsius = (val - 32) * 5 / 9; break; case 'Kelvin': celsius = val - 273.15; break; default: celsius = val; }
    switch (to) { case 'Celsius': return celsius; case 'Fahrenheit': return celsius * 9 / 5 + 32; case 'Kelvin': return celsius + 273.15; default: return celsius; }
  }

  double _convertWireGauge(double val, String from, String to) {
    double cmils;
    switch (from) { case 'AWG': final d = 0.005 * 1000 * _pow92((36 - val) / 39); cmils = d * d; break; case 'Circular Mils': cmils = val; break; case 'Sq mm': cmils = val * 1973.525; break; default: cmils = val; }
    switch (to) { case 'AWG': final d = _sqrt(cmils); return 36 - 39 * _log(d / 5) / _log(92); case 'Circular Mils': return cmils; case 'Sq mm': return cmils / 1973.525; default: return cmils; }
  }

  double _pow92(double x) => _pow(92, x);
  double _pow(double base, double exp) => _exp(exp * _ln(base));
  double _exp(double x) { double sum = 1, term = 1; for (int i = 1; i < 100; i++) { term *= x / i; sum += term; if (term.abs() < 1e-15) break; } return sum; }
  double _ln(double x) { if (x <= 0) return double.nan; double sum = 0, term = (x - 1) / (x + 1), t2 = term * term; for (int i = 1; i < 200; i += 2) { sum += term / i; term *= t2; } return 2 * sum; }
  double _log(double x) => _ln(x) / _ln(10);
  double _sqrt(double x) { if (x < 0) return double.nan; double g = x / 2; for (int i = 0; i < 50; i++) g = (g + x / g) / 2; return g; }

  void _swap() { final temp = _fromUnit; setState(() { _fromUnit = _toUnit; _toUnit = temp; }); _convert(); }
  void _reset() { _inputController.clear(); setState(() { _result = null; _setDefaultUnits(); }); }
}
