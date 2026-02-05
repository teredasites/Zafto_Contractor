import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Towel Bar Calculator - Bathroom accessory placement
class TowelBarScreen extends ConsumerStatefulWidget {
  const TowelBarScreen({super.key});
  @override
  ConsumerState<TowelBarScreen> createState() => _TowelBarScreenState();
}

class _TowelBarScreenState extends ConsumerState<TowelBarScreen> {
  final _wallWidthController = TextEditingController(text: '36');
  final _vanityHeightController = TextEditingController(text: '36');

  int _bathTowels = 2;
  int _handTowels = 2;

  int? _towelBars;
  int? _towelRings;
  int? _hooks;
  double? _barHeight;

  @override
  void dispose() { _wallWidthController.dispose(); _vanityHeightController.dispose(); super.dispose(); }

  void _calculate() {
    final wallWidth = double.tryParse(_wallWidthController.text) ?? 36;
    final vanityHeight = double.tryParse(_vanityHeightController.text) ?? 36;

    // 24" bar holds 2 towels, 18" bar holds 1-2
    final towelBars = (_bathTowels / 2).ceil();

    // Rings or hooks for hand towels
    final towelRings = _handTowels;

    // Additional hooks
    final hooks = 2; // Robe hooks

    // Bar height: 48" from floor typical, or 8-12" above vanity
    final barHeight = vanityHeight + 10;

    setState(() { _towelBars = towelBars; _towelRings = towelRings; _hooks = hooks; _barHeight = barHeight; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _wallWidthController.text = '36'; _vanityHeightController.text = '36'; setState(() { _bathTowels = 2; _handTowels = 2; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Towel Bars', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Width', unit: 'inches', controller: _wallWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Vanity Height', unit: 'inches', controller: _vanityHeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 20),
            _buildCounter(colors, 'Bath Towels', _bathTowels, (v) { setState(() => _bathTowels = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildCounter(colors, 'Hand Towels', _handTowels, (v) { setState(() => _handTowels = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_towelBars != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('ACCESSORIES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Towel Bars (24\")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_towelBars', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Towel Rings', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_towelRings', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Robe Hooks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hooks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mount Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_barHeight!.toStringAsFixed(0)}\" from floor', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use wall anchors or hit studs. Keep TP holder 26\" from floor, 8-12\" from toilet.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlacementTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCounter(ZaftoColors colors, String label, int value, Function(int) onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
      Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); if (value > 0) onChanged(value - 1); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
            child: Icon(LucideIcons.minus, size: 18, color: colors.textPrimary)),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); if (value < 10) onChanged(value + 1); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
            child: Icon(LucideIcons.plus, size: 18, color: colors.textPrimary)),
        ),
      ]),
    ]);
  }

  Widget _buildPlacementTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLACEMENT HEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Towel bar', '48\" from floor'),
        _buildTableRow(colors, 'Towel ring', '48-52\" from floor'),
        _buildTableRow(colors, 'Robe hook', '65-70\" from floor'),
        _buildTableRow(colors, 'TP holder', '26\" from floor'),
        _buildTableRow(colors, 'ADA grab bar', '33-36\" from floor'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
