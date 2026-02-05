import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// System Coolant Capacity Calculator
class CoolantCapacityScreen extends ConsumerStatefulWidget {
  const CoolantCapacityScreen({super.key});
  @override
  ConsumerState<CoolantCapacityScreen> createState() => _CoolantCapacityScreenState();
}

class _CoolantCapacityScreenState extends ConsumerState<CoolantCapacityScreen> {
  final _engineBlockController = TextEditingController();
  final _radiatorController = TextEditingController();
  final _heaterCoreController = TextEditingController(text: '1.5');
  final _hosesController = TextEditingController(text: '0.5');
  final _overflowController = TextEditingController(text: '1.0');

  double? _totalCapacity;
  double? _antifreezeNeeded;
  double? _waterNeeded;

  void _calculate() {
    final engineBlock = double.tryParse(_engineBlockController.text);
    final radiator = double.tryParse(_radiatorController.text);
    final heaterCore = double.tryParse(_heaterCoreController.text) ?? 1.5;
    final hoses = double.tryParse(_hosesController.text) ?? 0.5;
    final overflow = double.tryParse(_overflowController.text) ?? 1.0;

    if (engineBlock == null || radiator == null) {
      setState(() { _totalCapacity = null; });
      return;
    }

    final total = engineBlock + radiator + heaterCore + hoses + overflow;

    // 50/50 mix calculation
    final antifreeze = total / 2;
    final water = total / 2;

    setState(() {
      _totalCapacity = total;
      _antifreezeNeeded = antifreeze;
      _waterNeeded = water;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _engineBlockController.clear();
    _radiatorController.clear();
    _heaterCoreController.text = '1.5';
    _hosesController.text = '0.5';
    _overflowController.text = '1.0';
    setState(() { _totalCapacity = null; });
  }

  @override
  void dispose() {
    _engineBlockController.dispose();
    _radiatorController.dispose();
    _heaterCoreController.dispose();
    _hosesController.dispose();
    _overflowController.dispose();
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
        title: Text('Coolant Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Block Capacity', unit: 'qts', hint: 'Block and heads', controller: _engineBlockController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Radiator Capacity', unit: 'qts', hint: 'Radiator volume', controller: _radiatorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Heater Core', unit: 'qts', hint: 'Typical: 1-2 qts', controller: _heaterCoreController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Hoses & Lines', unit: 'qts', hint: 'Upper/lower hoses', controller: _hosesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Overflow Tank', unit: 'qts', hint: 'Reservoir capacity', controller: _overflowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalCapacity != null) _buildResultsCard(colors),
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
        Text('Total = Block + Radiator + Heater + Hoses + Overflow', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Add all components for accurate coolant purchase', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total System Capacity', '${_totalCapacity!.toStringAsFixed(1)} qts', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'In Gallons', '${(_totalCapacity! / 4).toStringAsFixed(2)} gal'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('For 50/50 Mix:', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildMixItem(colors, 'Antifreeze', '${_antifreezeNeeded!.toStringAsFixed(1)} qts'),
              Container(width: 1, height: 40, color: colors.borderSubtle),
              _buildMixItem(colors, 'Water', '${_waterNeeded!.toStringAsFixed(1)} qts'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Icon(LucideIcons.alertTriangle, color: colors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Use distilled water only - tap water causes deposits', style: TextStyle(color: colors.textTertiary, fontSize: 12))),
        ]),
      ]),
    );
  }

  Widget _buildMixItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
