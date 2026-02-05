import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Border Stone Calculator - Decorative edging stones
class BorderStoneScreen extends ConsumerStatefulWidget {
  const BorderStoneScreen({super.key});
  @override
  ConsumerState<BorderStoneScreen> createState() => _BorderStoneScreenState();
}

class _BorderStoneScreenState extends ConsumerState<BorderStoneScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _stoneType = 'scallop';
  double _wasteFactor = 10;

  int? _stonesNeeded;
  double? _adhesiveTubes;
  double? _sandBags;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;

    // Stone width varies by type (inches)
    double stoneWidthIn;
    switch (_stoneType) {
      case 'scallop': stoneWidthIn = 12; break;
      case 'belgian': stoneWidthIn = 7; break;
      case 'cobble': stoneWidthIn = 4; break;
      case 'rope': stoneWidthIn = 12; break;
      default: stoneWidthIn = 12;
    }

    final lengthInches = length * 12;
    final baseStones = (lengthInches / stoneWidthIn).ceil();
    final stonesWithWaste = (baseStones * (1 + _wasteFactor / 100)).ceil();

    // Adhesive: 1 tube per ~30 lin ft (optional for some applications)
    final adhesiveTubes = length / 30;

    // Sand: leveling bed, 50 lb bag per 10 lin ft
    final sandBags = length / 10;

    setState(() {
      _stonesNeeded = stonesWithWaste;
      _adhesiveTubes = adhesiveTubes;
      _sandBags = sandBags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _stoneType = 'scallop'; _wasteFactor = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Border Stones', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STONE TYPE', ['scallop', 'belgian', 'cobble', 'rope'], _stoneType, {'scallop': 'Scallop', 'belgian': 'Belgian', 'cobble': 'Cobble', 'rope': 'Rope'}, (v) { setState(() => _stoneType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Border Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 15, divisions: 2, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_stonesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STONES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stonesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Leveling sand (50 lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandBags!.ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Adhesive tubes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_adhesiveTubes!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStoneGuide(colors),
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

  Widget _buildStoneGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BORDER STYLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Scallop', '12" wide, curved top'),
        _buildTableRow(colors, 'Belgian block', '7" wide, tumbled'),
        _buildTableRow(colors, 'Cobblestone', '4" wide, round'),
        _buildTableRow(colors, 'Rope edge', '12" wide, decorative'),
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
