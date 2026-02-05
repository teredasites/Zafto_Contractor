import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// MIG Settings Calculator - Wire speed/voltage by thickness
class MigSettingsScreen extends ConsumerStatefulWidget {
  const MigSettingsScreen({super.key});
  @override
  ConsumerState<MigSettingsScreen> createState() => _MigSettingsScreenState();
}

class _MigSettingsScreenState extends ConsumerState<MigSettingsScreen> {
  final _thicknessController = TextEditingController();
  String _wireDiameter = '0.030';
  String _gasType = 'C25';

  double? _wireSpeed;
  double? _voltage;
  double? _amperage;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    if (thickness == null || thickness <= 0) {
      setState(() { _wireSpeed = null; });
      return;
    }

    // Base settings for 0.030" wire on mild steel
    double baseWireSpeed, baseVoltage;
    switch (_wireDiameter) {
      case '0.023':
        baseWireSpeed = 180 + (thickness * 80);
        baseVoltage = 15 + (thickness * 3);
        break;
      case '0.030':
        baseWireSpeed = 200 + (thickness * 100);
        baseVoltage = 17 + (thickness * 4);
        break;
      case '0.035':
        baseWireSpeed = 220 + (thickness * 120);
        baseVoltage = 18 + (thickness * 5);
        break;
      case '0.045':
        baseWireSpeed = 180 + (thickness * 80);
        baseVoltage = 20 + (thickness * 6);
        break;
      default:
        baseWireSpeed = 200;
        baseVoltage = 18;
    }

    // Approximate amperage (rough rule: 1 amp per 0.001" of thickness for steel)
    final amps = thickness * 1000 * 0.9;

    setState(() {
      _wireSpeed = baseWireSpeed.clamp(100, 600);
      _voltage = baseVoltage.clamp(14, 30);
      _amperage = amps.clamp(30, 300);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _wireSpeed = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('MIG Settings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('WIRE DIAMETER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildWireSelector(colors),
            const SizedBox(height: 16),
            Text('SHIELDING GAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildGasSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'e.g. 0.125 for 1/8"', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_wireSpeed != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildWireSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['0.023', '0.030', '0.035', '0.045'].map((size) => ChoiceChip(
        label: Text('$size"'),
        selected: _wireDiameter == size,
        onSelected: (_) => setState(() { _wireDiameter = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildGasSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['C25', '100% CO2', '90/10'].map((gas) => ChoiceChip(
        label: Text(gas),
        selected: _gasType == gas,
        onSelected: (_) => setState(() { _gasType = gas; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Starting Point Settings', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Fine-tune based on joint type and position', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wire Speed', '${_wireSpeed!.toStringAsFixed(0)} IPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Voltage', '${_voltage!.toStringAsFixed(1)} V'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Amperage', '${_amperage!.toStringAsFixed(0)} A'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text('These are starting points - adjust for your machine', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
