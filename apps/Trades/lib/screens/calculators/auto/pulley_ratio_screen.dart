import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pulley Ratio Calculator - Accessory drive calculations
class PulleyRatioScreen extends ConsumerStatefulWidget {
  const PulleyRatioScreen({super.key});
  @override
  ConsumerState<PulleyRatioScreen> createState() => _PulleyRatioScreenState();
}

class _PulleyRatioScreenState extends ConsumerState<PulleyRatioScreen> {
  final _crankPulleyController = TextEditingController();
  final _accessoryPulleyController = TextEditingController();
  final _engineRpmController = TextEditingController(text: '3000');

  double? _ratio;
  double? _accessoryRpm;

  void _calculate() {
    final crankPulley = double.tryParse(_crankPulleyController.text);
    final accessoryPulley = double.tryParse(_accessoryPulleyController.text);
    final engineRpm = double.tryParse(_engineRpmController.text);

    if (crankPulley == null || accessoryPulley == null || accessoryPulley <= 0) {
      setState(() { _ratio = null; });
      return;
    }

    final ratio = crankPulley / accessoryPulley;
    double? accRpm;
    if (engineRpm != null) {
      accRpm = engineRpm * ratio;
    }

    setState(() {
      _ratio = ratio;
      _accessoryRpm = accRpm;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _crankPulleyController.clear();
    _accessoryPulleyController.clear();
    _engineRpmController.text = '3000';
    setState(() { _ratio = null; });
  }

  @override
  void dispose() {
    _crankPulleyController.dispose();
    _accessoryPulleyController.dispose();
    _engineRpmController.dispose();
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
        title: Text('Pulley Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Crank Pulley Diameter', unit: 'in', hint: 'Drive pulley', controller: _crankPulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Accessory Pulley Diameter', unit: 'in', hint: 'Driven pulley', controller: _accessoryPulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine RPM', unit: 'rpm', hint: 'For speed calculation', controller: _engineRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_ratio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildApplicationCard(colors),
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
        Text('Ratio = Crank Pulley / Accessory Pulley', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Larger crank = faster accessory, Smaller = slower', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isOverdriven = _ratio! > 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pulley Ratio', '${_ratio!.toStringAsFixed(2)}:1', isPrimary: true),
        if (_accessoryRpm != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Accessory Speed', '${_accessoryRpm!.toStringAsFixed(0)} rpm'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            isOverdriven ? 'Overdriven - accessory spins faster than crank' : 'Underdriven - accessory spins slower than crank',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildAppRow(colors, 'Alternator', 'Usually overdriven 2-3:1'),
        _buildAppRow(colors, 'A/C Compressor', 'Usually 1:1 to 1.5:1'),
        _buildAppRow(colors, 'Water Pump', 'Usually 1:1'),
        _buildAppRow(colors, 'Supercharger', '1.5:1 to 3.5:1 for boost'),
        const SizedBox(height: 8),
        Text('Underdrive pulleys reduce parasitic loss but may affect charging and cooling at idle.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildAppRow(ZaftoColors colors, String component, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(component, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(child: Text(info, textAlign: TextAlign.right, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
