import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weatherstrip Calculator - Door/window seal estimation
class WeatherstripScreen extends ConsumerStatefulWidget {
  const WeatherstripScreen({super.key});
  @override
  ConsumerState<WeatherstripScreen> createState() => _WeatherstripScreenState();
}

class _WeatherstripScreenState extends ConsumerState<WeatherstripScreen> {
  final _doorsController = TextEditingController(text: '3');
  final _windowsController = TextEditingController(text: '10');

  String _type = 'vstrip';

  double? _doorFeet;
  double? _windowFeet;
  double? _totalFeet;
  int? _rolls17ft;

  @override
  void dispose() { _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;

    // Door: perimeter minus threshold = ~17 lf per door
    final doorFeet = doors * 17.0;

    // Window: depends on type, average ~14 lf per double-hung
    final windowFeet = windows * 14.0;

    final totalFeet = doorFeet + windowFeet;

    // Standard rolls are 17 ft
    final rolls17ft = (totalFeet / 17).ceil();

    setState(() { _doorFeet = doorFeet; _windowFeet = windowFeet; _totalFeet = totalFeet; _rolls17ft = rolls17ft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _doorsController.text = '3'; _windowsController.text = '10'; setState(() => _type = 'vstrip'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Weatherstripping', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Exterior Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('For Doors', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_doorFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('For Windows', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_windowFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('17\' Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rolls17ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_type) {
      case 'vstrip':
        return 'V-strip (tension seal) is most durable. Self-adhesive, lasts 3-5 years.';
      case 'foam':
        return 'Foam tape is easiest but wears fastest. Replace yearly. Good for low-use windows.';
      case 'felt':
        return 'Felt is cheapest but least durable. Staple or nail in place. Indoor use only.';
      case 'rubber':
        return 'Rubber/vinyl is good for irregular gaps. Flexible, handles compression well.';
      default:
        return 'Match weatherstrip type to gap size and surface. Clean surface before applying.';
    }
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['vstrip', 'foam', 'felt', 'rubber'];
    final labels = {'vstrip': 'V-Strip', 'foam': 'Foam Tape', 'felt': 'Felt', 'rubber': 'Rubber'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WEATHERSTRIP COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'V-strip (tension)', 'Best, 3-5 years'),
        _buildTableRow(colors, 'Foam tape', 'Easy, 1-2 years'),
        _buildTableRow(colors, 'Felt', 'Cheapest, 1 year'),
        _buildTableRow(colors, 'Rubber/vinyl', 'Good, 2-4 years'),
        _buildTableRow(colors, 'Door sweep', 'Bottom of door'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
