import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Differential Fluid Calculator
class DiffFluidScreen extends ConsumerStatefulWidget {
  const DiffFluidScreen({super.key});
  @override
  ConsumerState<DiffFluidScreen> createState() => _DiffFluidScreenState();
}

class _DiffFluidScreenState extends ConsumerState<DiffFluidScreen> {
  String _diffType = 'Open';
  String _axleSize = 'Light Duty';
  bool _hasPosi = false;

  double? _fluidCapacity;
  String? _fluidType;
  String? _recommendation;

  // Typical capacities by axle size (pints)
  static const Map<String, double> _capacities = {
    'Light Duty': 2.5,
    'Medium Duty': 3.5,
    'Heavy Duty': 5.0,
    '3/4 Ton+': 6.5,
  };

  void _calculate() {
    final baseCapacity = _capacities[_axleSize]!;

    String fluidType;
    String recommendation;

    if (_diffType == 'Limited Slip' || _hasPosi) {
      fluidType = 'GL-5 with LS additive';
      recommendation = 'Add friction modifier for limited slip. Check for chatter.';
    } else if (_diffType == 'Locking') {
      fluidType = 'Synthetic GL-5';
      recommendation = 'Locking diffs may require specific manufacturer fluid';
    } else {
      fluidType = 'GL-5 75W-90';
      recommendation = 'Open diff: Standard gear oil. Check for leaks at seals.';
    }

    setState(() {
      _fluidCapacity = baseCapacity;
      _fluidType = fluidType;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _diffType = 'Open';
    _axleSize = 'Light Duty';
    _hasPosi = false;
    setState(() { _fluidCapacity = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Diff Fluid', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('DIFFERENTIAL TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildDiffSelector(colors),
            const SizedBox(height: 16),
            Text('AXLE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildAxleSelector(colors),
            const SizedBox(height: 16),
            _buildPosiToggle(colors),
            const SizedBox(height: 32),
            if (_fluidCapacity != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildDiffSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Open', 'Limited Slip', 'Locking'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _diffType == type,
        onSelected: (_) => setState(() { _diffType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildAxleSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _capacities.keys.map((size) => ChoiceChip(
        label: Text(size, style: const TextStyle(fontSize: 10)),
        selected: _axleSize == size,
        onSelected: (_) => setState(() { _axleSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPosiToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Has Posi/LSD'), selected: _hasPosi, onSelected: (_) => setState(() { _hasPosi = !_hasPosi; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Capacity varies by axle size', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('LS/Posi requires friction modifier additive', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Capacity', '${_fluidCapacity!.toStringAsFixed(1)} pt', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Quarts', '${(_fluidCapacity! / 2).toStringAsFixed(2)} qt'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Fluid Type', _fluidType!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
