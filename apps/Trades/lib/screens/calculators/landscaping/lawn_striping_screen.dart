import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lawn Striping Calculator - Pattern planning
class LawnStripingScreen extends ConsumerStatefulWidget {
  const LawnStripingScreen({super.key});
  @override
  ConsumerState<LawnStripingScreen> createState() => _LawnStripingScreenState();
}

class _LawnStripingScreenState extends ConsumerState<LawnStripingScreen> {
  final _lengthController = TextEditingController(text: '100');
  final _widthController = TextEditingController(text: '50');
  final _deckWidthController = TextEditingController(text: '48');

  String _pattern = 'straight';

  int? _passes;
  double? _totalDistance;
  int? _turnarounds;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _deckWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;
    final width = double.tryParse(_widthController.text) ?? 50;
    final deckWidthIn = double.tryParse(_deckWidthController.text) ?? 48;

    final deckWidthFt = deckWidthIn / 12;

    // Calculate passes needed
    int passes;
    double totalDistance;
    int turnarounds;

    switch (_pattern) {
      case 'straight':
        passes = (width / deckWidthFt).ceil();
        totalDistance = passes * length;
        turnarounds = passes - 1;
        break;
      case 'diagonal':
        // Diagonal is ~41% longer
        final diagonalLength = (length * length + width * width).toDouble();
        final diagonalDist = diagonalLength > 0 ? (diagonalLength * 0.5).clamp(0, 10000) : length;
        passes = (width * 1.41 / deckWidthFt).ceil();
        totalDistance = passes * diagonalDist * 0.015; // Approximation
        turnarounds = passes - 1;
        break;
      case 'checkerboard':
        // Two passes perpendicular
        final pass1 = (width / deckWidthFt).ceil();
        final pass2 = (length / deckWidthFt).ceil();
        passes = pass1 + pass2;
        totalDistance = (pass1 * length) + (pass2 * width);
        turnarounds = passes - 2;
        break;
      default:
        passes = (width / deckWidthFt).ceil();
        totalDistance = passes * length;
        turnarounds = passes - 1;
    }

    setState(() {
      _passes = passes;
      _totalDistance = totalDistance;
      _turnarounds = turnarounds;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; _widthController.text = '50'; _deckWidthController.text = '48'; setState(() { _pattern = 'straight'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lawn Striping', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PATTERN', ['straight', 'diagonal', 'checkerboard'], _pattern, {'straight': 'Straight', 'diagonal': 'Diagonal', 'checkerboard': 'Checker'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Lawn Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Lawn Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Mower Deck Width', unit: 'in', controller: _deckWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_passes != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MOWING PASSES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_passes', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total distance', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalDistance!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Turnarounds', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_turnarounds', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStripingGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStripingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STRIPING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best grass', 'Cool season (fescue, rye)'),
        _buildTableRow(colors, 'Mow height', '3-4\" for best effect'),
        _buildTableRow(colors, 'Roller weight', 'Light touch preferred'),
        _buildTableRow(colors, 'Alternate', 'Change direction weekly'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
