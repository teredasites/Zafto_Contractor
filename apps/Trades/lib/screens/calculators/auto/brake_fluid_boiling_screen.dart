import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Fluid Boiling Point Calculator - DOT specs and wet vs dry
class BrakeFluidBoilingScreen extends ConsumerStatefulWidget {
  const BrakeFluidBoilingScreen({super.key});
  @override
  ConsumerState<BrakeFluidBoilingScreen> createState() => _BrakeFluidBoilingScreenState();
}

class _BrakeFluidBoilingScreenState extends ConsumerState<BrakeFluidBoilingScreen> {
  String _fluidType = 'dot4';

  final Map<String, Map<String, int>> _fluidSpecs = {
    'dot3': {'dry': 401, 'wet': 284},
    'dot4': {'dry': 446, 'wet': 311},
    'dot4plus': {'dry': 500, 'wet': 356},
    'dot51': {'dry': 500, 'wet': 356},
    'dot5': {'dry': 500, 'wet': 356},
    'racing': {'dry': 590, 'wet': 420},
  };

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() { _fluidType = 'dot4'; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Brake Fluid Boiling', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildFluidSelector(colors),
            const SizedBox(height: 32),
            _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildComparisonCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFluidSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FLUID TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildOption(colors, 'DOT 3', 'dot3'),
        _buildOption(colors, 'DOT 4', 'dot4'),
        _buildOption(colors, 'DOT 4+', 'dot4plus'),
        _buildOption(colors, 'DOT 5.1', 'dot51'),
        _buildOption(colors, 'DOT 5', 'dot5'),
        _buildOption(colors, 'Racing', 'racing'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value) {
    final selected = _fluidType == value;
    return GestureDetector(
      onTap: () => setState(() => _fluidType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Dry = New | Wet = 3% moisture', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Fluid absorbs moisture over time, lowering boiling point', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final specs = _fluidSpecs[_fluidType]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(children: [
            Text('DRY BOILING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${specs['dry']}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('${((specs['dry']! - 32) * 5 / 9).round()}°C', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ])),
          Container(width: 1, height: 60, color: colors.borderSubtle),
          Expanded(child: Column(children: [
            Text('WET BOILING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${specs['wet']}°F', style: TextStyle(color: colors.warning, fontSize: 28, fontWeight: FontWeight.w700)),
            Text('${((specs['wet']! - 32) * 5 / 9).round()}°C', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ])),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_fluidType == 'dot5' ? 'DOT 5 is silicone-based - not compatible with other types' : 'Replace fluid every 2-3 years or when moisture content exceeds 3%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildComparisonCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._fluidSpecs.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 70, child: Text(e.key.toUpperCase(), style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            Expanded(child: Container(
              height: 8,
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: e.value['dry']! / 600,
                child: Container(decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4))),
              ),
            )),
            SizedBox(width: 50, child: Text('${e.value['dry']}°', textAlign: TextAlign.right, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          ]),
        )),
      ]),
    );
  }
}
