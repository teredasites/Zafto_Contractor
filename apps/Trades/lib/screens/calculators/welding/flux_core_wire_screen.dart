import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flux Core Wire Calculator - FCAW wire consumption
class FluxCoreWireScreen extends ConsumerStatefulWidget {
  const FluxCoreWireScreen({super.key});
  @override
  ConsumerState<FluxCoreWireScreen> createState() => _FluxCoreWireScreenState();
}

class _FluxCoreWireScreenState extends ConsumerState<FluxCoreWireScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  String _wireType = 'E71T-1';
  String _wireSize = '0.045';

  double? _lbsNeeded;
  double? _spoolsNeeded;
  String? _gasRequirement;

  // Deposition efficiency for FCAW
  static const Map<String, double> _depositionEff = {
    'E71T-1': 0.85, // Gas-shielded
    'E71T-8': 0.78, // Self-shielded
    'E71T-11': 0.80, // Self-shielded
    'E81T1-Ni1': 0.83,
    'E91T1-Ni2': 0.82,
  };

  static const Map<String, String> _gasReq = {
    'E71T-1': '75/25 CO2/Ar or 100% CO2',
    'E71T-8': 'Self-shielded (no gas)',
    'E71T-11': 'Self-shielded (no gas)',
    'E81T1-Ni1': '75/25 CO2/Ar',
    'E91T1-Ni2': '75/25 CO2/Ar',
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);

    if (length == null || leg == null || leg <= 0) {
      setState(() { _lbsNeeded = null; });
      return;
    }

    final areaPerFoot = (leg * leg / 2) * 12;
    final totalVolume = areaPerFoot * length;
    final weldMetalWeight = totalVolume * 0.284;

    final efficiency = _depositionEff[_wireType] ?? 0.85;
    final lbsNeeded = weldMetalWeight / efficiency;

    // Standard 33 lb spool
    final spoolsNeeded = lbsNeeded / 33;

    setState(() {
      _lbsNeeded = lbsNeeded;
      _spoolsNeeded = spoolsNeeded;
      _gasRequirement = _gasReq[_wireType];
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    setState(() { _lbsNeeded = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
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
        title: Text('Flux Core Wire', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTypeSelector(colors),
            const SizedBox(height: 12),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Total linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fillet Leg Size', unit: 'in', hint: 'e.g. 0.25', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lbsNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _depositionEff.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 12)),
        selected: _wireType == type,
        onSelected: (_) => setState(() { _wireType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['0.035', '0.045', '0.052', '1/16', '5/64'];
    return Wrap(
      spacing: 8,
      children: sizes.map((size) => ChoiceChip(
        label: Text(size),
        selected: _wireSize == size,
        onSelected: (_) => setState(() { _wireSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('FCAW Wire Consumption', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Accounts for flux core deposition efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wire Needed', '${_lbsNeeded!.toStringAsFixed(1)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, '33 lb Spools', _spoolsNeeded!.toStringAsFixed(2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.wind, size: 16, color: colors.textTertiary),
            const SizedBox(width: 8),
            Expanded(child: Text(_gasRequirement!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
