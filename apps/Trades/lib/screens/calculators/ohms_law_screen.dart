import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../utils/calculations.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Ohm's Law Calculator - Design System v2.6
class OhmsLawScreen extends ConsumerStatefulWidget {
  const OhmsLawScreen({super.key});
  @override
  ConsumerState<OhmsLawScreen> createState() => _OhmsLawScreenState();
}

class _OhmsLawScreenState extends ConsumerState<OhmsLawScreen> {
  final _voltageController = TextEditingController();
  final _currentController = TextEditingController();
  final _resistanceController = TextEditingController();
  final _powerController = TextEditingController();
  final Set<_OhmsField> _userEnteredFields = {};

  @override
  void dispose() {
    _voltageController.dispose();
    _currentController.dispose();
    _resistanceController.dispose();
    _powerController.dispose();
    super.dispose();
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
        title: Text("Ohm's Law", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll, tooltip: 'Clear all')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildInputField(colors, 'Voltage', 'V', 'Volts', _voltageController, colors.accentWarning, _OhmsField.voltage),
              const SizedBox(height: 16),
              _buildInputField(colors, 'Current', 'A', 'Amps', _currentController, colors.accentSuccess, _OhmsField.current),
              const SizedBox(height: 16),
              _buildInputField(colors, 'Resistance', 'Ω', 'Ohms', _resistanceController, colors.accentPrimary, _OhmsField.resistance),
              const SizedBox(height: 16),
              _buildInputField(colors, 'Power', 'W', 'Watts', _powerController, colors.accentError, _OhmsField.power),
              const SizedBox(height: 32),
              Text('Enter any 2 values to calculate the rest', style: TextStyle(color: colors.textTertiary, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text('V = I × R', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w500, fontSize: 14)),
        Container(width: 1, height: 20, color: colors.borderSubtle),
        Text('P = V × I', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w500, fontSize: 14)),
        Container(width: 1, height: 20, color: colors.borderSubtle),
        Text('P = I²R', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w500, fontSize: 14)),
      ]),
    );
  }

  Widget _buildInputField(ZaftoColors colors, String label, String unit, String hint, TextEditingController controller, Color color, _OhmsField field) {
    final isCalculated = !_userEnteredFields.contains(field) && controller.text.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: isCalculated ? color : colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
        if (isCalculated) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text('CALC', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: isCalculated ? color.withValues(alpha: 0.05) : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCalculated ? color.withValues(alpha: 0.3) : colors.borderSubtle, width: isCalculated ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            style: TextStyle(color: isCalculated ? color : colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 28),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: colors.textQuaternary, fontWeight: FontWeight.w400, fontSize: 28), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
            onChanged: (value) => _onFieldChanged(field, value),
            readOnly: isCalculated,
          )),
          Padding(padding: const EdgeInsets.only(right: 16), child: Text(unit, style: TextStyle(color: colors.textTertiary, fontSize: 20))),
        ]),
      ),
    ]);
  }

  void _onFieldChanged(_OhmsField field, String value) {
    if (value.isEmpty) { _userEnteredFields.remove(field); } else { _userEnteredFields.add(field); }
    _calculate();
  }

  void _calculate() {
    if (_userEnteredFields.length < 2) {
      for (final field in _OhmsField.values) { if (!_userEnteredFields.contains(field)) _getController(field).text = ''; }
      setState(() {});
      return;
    }
    final v = _userEnteredFields.contains(_OhmsField.voltage) ? double.tryParse(_voltageController.text) : null;
    final i = _userEnteredFields.contains(_OhmsField.current) ? double.tryParse(_currentController.text) : null;
    final r = _userEnteredFields.contains(_OhmsField.resistance) ? double.tryParse(_resistanceController.text) : null;
    final p = _userEnteredFields.contains(_OhmsField.power) ? double.tryParse(_powerController.text) : null;
    double? calcV = v, calcI = i, calcR = r, calcP = p;
    if (v != null && i != null) { calcR = i != 0 ? OhmsLaw.resistanceFromVI(v, i) : null; calcP = OhmsLaw.powerFromVI(v, i); }
    else if (v != null && r != null) { calcI = OhmsLaw.currentFromVR(v, r); calcP = OhmsLaw.powerFromVR(v, r); }
    else if (v != null && p != null) { calcI = v != 0 ? OhmsLaw.currentFromPV(p, v) : null; calcR = calcI != null && calcI != 0 ? OhmsLaw.resistanceFromVI(v, calcI) : null; }
    else if (i != null && r != null) { calcV = OhmsLaw.voltageFromIR(i, r); calcP = OhmsLaw.powerFromIR(i, r); }
    else if (i != null && p != null) { calcV = i != 0 ? OhmsLaw.voltageFromPI(p, i) : null; calcR = i != 0 ? OhmsLaw.resistanceFromPI(p, i) : null; }
    else if (r != null && p != null && r > 0) { calcV = _sqrt(p * r); calcI = _sqrt(p / r); }
    if (!_userEnteredFields.contains(_OhmsField.voltage)) _voltageController.text = _formatResult(calcV);
    if (!_userEnteredFields.contains(_OhmsField.current)) _currentController.text = _formatResult(calcI);
    if (!_userEnteredFields.contains(_OhmsField.resistance)) _resistanceController.text = _formatResult(calcR);
    if (!_userEnteredFields.contains(_OhmsField.power)) _powerController.text = _formatResult(calcP);
    setState(() {});
  }

  double _sqrt(double x) => x > 0 ? x.toDouble() * 0.5 + x / (x.toDouble() * 0.5 + 1) : 0;
  String _formatResult(double? value) {
    if (value == null || value.isInfinite || value.isNaN) return '';
    if (value >= 1000) return value.toStringAsFixed(1);
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(3);
    return value.toStringAsFixed(4);
  }
  TextEditingController _getController(_OhmsField field) => switch (field) { _OhmsField.voltage => _voltageController, _OhmsField.current => _currentController, _OhmsField.resistance => _resistanceController, _OhmsField.power => _powerController };
  void _clearAll() { _voltageController.clear(); _currentController.clear(); _resistanceController.clear(); _powerController.clear(); _userEnteredFields.clear(); setState(() {}); }
}

enum _OhmsField { voltage, current, resistance, power }
