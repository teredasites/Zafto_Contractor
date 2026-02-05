import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ohm's Law Calculator - 12V automotive electrical calculations
class OhmsLaw12vScreen extends ConsumerStatefulWidget {
  const OhmsLaw12vScreen({super.key});
  @override
  ConsumerState<OhmsLaw12vScreen> createState() => _OhmsLaw12vScreenState();
}

class _OhmsLaw12vScreenState extends ConsumerState<OhmsLaw12vScreen> {
  final _voltageController = TextEditingController(text: '12');
  final _currentController = TextEditingController();
  final _resistanceController = TextEditingController();
  final _powerController = TextEditingController();

  int _lastEditedField = 0; // 1=V, 2=I, 3=R, 4=P
  List<int> _editOrder = [];

  void _calculate(int fieldEdited) {
    // Track edit order
    _editOrder.remove(fieldEdited);
    _editOrder.add(fieldEdited);
    if (_editOrder.length > 2) _editOrder.removeAt(0);

    final v = double.tryParse(_voltageController.text);
    final i = double.tryParse(_currentController.text);
    final r = double.tryParse(_resistanceController.text);
    final p = double.tryParse(_powerController.text);

    // Calculate based on what we have
    if (_editOrder.length >= 2) {
      final f1 = _editOrder[0];
      final f2 = _editOrder[1];

      // V and I known
      if ((f1 == 1 || f1 == 2) && (f2 == 1 || f2 == 2) && v != null && i != null && i > 0) {
        _resistanceController.text = (v / i).toStringAsFixed(2);
        _powerController.text = (v * i).toStringAsFixed(1);
      }
      // V and R known
      else if ((f1 == 1 || f1 == 3) && (f2 == 1 || f2 == 3) && v != null && r != null && r > 0) {
        _currentController.text = (v / r).toStringAsFixed(2);
        _powerController.text = (v * v / r).toStringAsFixed(1);
      }
      // V and P known
      else if ((f1 == 1 || f1 == 4) && (f2 == 1 || f2 == 4) && v != null && p != null && v > 0) {
        _currentController.text = (p / v).toStringAsFixed(2);
        _resistanceController.text = (v * v / p).toStringAsFixed(2);
      }
      // I and R known
      else if ((f1 == 2 || f1 == 3) && (f2 == 2 || f2 == 3) && i != null && r != null) {
        _voltageController.text = (i * r).toStringAsFixed(2);
        _powerController.text = (i * i * r).toStringAsFixed(1);
      }
      // I and P known
      else if ((f1 == 2 || f1 == 4) && (f2 == 2 || f2 == 4) && i != null && p != null && i > 0) {
        _voltageController.text = (p / i).toStringAsFixed(2);
        _resistanceController.text = (p / (i * i)).toStringAsFixed(2);
      }
      // R and P known
      else if ((f1 == 3 || f1 == 4) && (f2 == 3 || f2 == 4) && r != null && p != null && r > 0) {
        _voltageController.text = (p * r).toStringAsFixed(2);
        _currentController.text = (p / r).toStringAsFixed(2);
      }
    }

    setState(() {});
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _voltageController.text = '12';
    _currentController.clear();
    _resistanceController.clear();
    _powerController.clear();
    _editOrder.clear();
    setState(() {});
  }

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
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text("Ohm's Law (12V)", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Voltage (V)', unit: 'volts', hint: '12V typical', controller: _voltageController, onChanged: (_) => _calculate(1)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current (I)', unit: 'amps', hint: 'Amperage', controller: _currentController, onChanged: (_) => _calculate(2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Resistance (R)', unit: 'ohms', hint: 'Resistance', controller: _resistanceController, onChanged: (_) => _calculate(3)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Power (P)', unit: 'watts', hint: 'Wattage', controller: _powerController, onChanged: (_) => _calculate(4)),
            const SizedBox(height: 32),
            _buildFormulasCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('V = I × R  |  P = V × I', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Enter any two values to calculate the others', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildFormulasCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("OHM'S LAW FORMULAS", style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildFormulaRow(colors, 'V = I × R', 'V = P / I', 'V = √(P × R)'),
        _buildFormulaRow(colors, 'I = V / R', 'I = P / V', 'I = √(P / R)'),
        _buildFormulaRow(colors, 'R = V / I', 'R = V² / P', 'R = P / I²'),
        _buildFormulaRow(colors, 'P = V × I', 'P = V² / R', 'P = I² × R'),
      ]),
    );
  }

  Widget _buildFormulaRow(ZaftoColors colors, String f1, String f2, String f3) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(f1, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace'))),
        Expanded(child: Text(f2, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace'))),
        Expanded(child: Text(f3, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace'))),
      ]),
    );
  }
}
