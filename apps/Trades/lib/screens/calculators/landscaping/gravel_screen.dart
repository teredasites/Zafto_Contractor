import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gravel Calculator - Tons by depth
class GravelScreen extends ConsumerStatefulWidget {
  const GravelScreen({super.key});
  @override
  ConsumerState<GravelScreen> createState() => _GravelScreenState();
}

class _GravelScreenState extends ConsumerState<GravelScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '10');
  final _depthController = TextEditingController(text: '3');

  String _gravelType = 'crushed';

  double? _cubicYards;
  double? _tons;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 10;
    final depthInches = double.tryParse(_depthController.text) ?? 3;

    final sqft = length * width;
    final depthFeet = depthInches / 12;
    final cubicFeet = sqft * depthFeet;
    final cubicYards = cubicFeet / 27;

    // Weight varies by type (lbs per cubic yard)
    double lbsPerCubicYard;
    switch (_gravelType) {
      case 'crushed': lbsPerCubicYard = 2700; break;
      case 'pea': lbsPerCubicYard = 2600; break;
      case 'river': lbsPerCubicYard = 2700; break;
      case 'dg': lbsPerCubicYard = 2500; break;
      default: lbsPerCubicYard = 2700;
    }

    final tons = (cubicYards * lbsPerCubicYard) / 2000;

    setState(() {
      _cubicYards = cubicYards;
      _tons = tons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '10'; _depthController.text = '3'; setState(() { _gravelType = 'crushed'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gravel Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GRAVEL TYPE', ['crushed', 'pea', 'river', 'dg'], _gravelType, {'crushed': 'Crushed', 'pea': 'Pea Gravel', 'river': 'River Rock', 'dg': 'Decomp. Granite'}, (v) { setState(() => _gravelType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cubicYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAVEL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cubic Yards', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Order 5-10% extra to account for compaction and irregular areas.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGravelTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildGravelTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GRAVEL WEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Crushed stone', '~2,700 lbs/yd'),
        _buildTableRow(colors, 'Pea gravel', '~2,600 lbs/yd'),
        _buildTableRow(colors, 'River rock', '~2,700 lbs/yd'),
        _buildTableRow(colors, 'Decomp. granite', '~2,500 lbs/yd'),
        _buildTableRow(colors, 'Rip rap', '~2,800 lbs/yd'),
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
