import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stair Tread Calculator - Stair tread and riser estimation
class StairTreadScreen extends ConsumerStatefulWidget {
  const StairTreadScreen({super.key});
  @override
  ConsumerState<StairTreadScreen> createState() => _StairTreadScreenState();
}

class _StairTreadScreenState extends ConsumerState<StairTreadScreen> {
  final _stepsController = TextEditingController(text: '13');
  final _widthController = TextEditingController(text: '36');

  String _material = 'oak';
  bool _hasRisers = true;
  bool _hasNosing = true;

  int? _treads;
  int? _risers;
  double? _nosingLF;
  double? _stringerLF;

  @override
  void dispose() { _stepsController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final steps = int.tryParse(_stepsController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 36;

    final widthFt = width / 12;

    // Treads equal number of steps
    final treads = steps;

    // Risers: 1 more than treads (includes bottom)
    final risers = _hasRisers ? steps + 1 : 0;

    // Return nosing at landing
    final nosingLF = _hasNosing ? widthFt * 1.1 : 0.0; // With waste

    // Stringers: 2 minimum, add 1 for wide stairs
    final stringerCount = width > 42 ? 3 : 2;
    // Each stringer ~1.5x the run length
    final stringerLF = (steps * 1.2) * stringerCount.toDouble();

    setState(() { _treads = treads; _risers = risers; _nosingLF = nosingLF; _stringerLF = stringerLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _stepsController.text = '13'; _widthController.text = '36'; setState(() { _material = 'oak'; _hasRisers = true; _hasNosing = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stair Treads', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Number of Steps', unit: 'qty', controller: _stepsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stair Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Risers', _hasRisers, (v) { setState(() => _hasRisers = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Landing Nosing', _hasNosing, (v) { setState(() => _hasNosing = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_treads != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TREADS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_treads', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_hasRisers) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Risers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_risers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                if (_hasNosing) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landing Nosing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_nosingLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stringer Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stringerLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard tread: 1\" thick, 10.5-11.5\" deep. Nosing overhang 3/4-1.25\".', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['oak', 'maple', 'pine', 'lvl'];
    final labels = {'oak': 'Red Oak', 'maple': 'Maple', 'pine': 'Pine', 'lvl': 'LVL/Retro'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _material == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Center(child: Text(label, style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD TREAD SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Width', '36\", 42\", 48\"'),
        _buildTableRow(colors, 'Depth', '10.5\", 11.25\", 11.5\"'),
        _buildTableRow(colors, 'Thickness', '1\" (25mm)'),
        _buildTableRow(colors, 'Nosing', '3/4\" - 1.25\"'),
        _buildTableRow(colors, 'Riser', '7\" - 8\" height'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
