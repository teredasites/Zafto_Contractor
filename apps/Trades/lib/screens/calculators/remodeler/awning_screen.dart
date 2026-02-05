import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Awning Calculator - Window/door awning estimation
class AwningScreen extends ConsumerStatefulWidget {
  const AwningScreen({super.key});
  @override
  ConsumerState<AwningScreen> createState() => _AwningScreenState();
}

class _AwningScreenState extends ConsumerState<AwningScreen> {
  final _widthController = TextEditingController(text: '48');
  final _projectionController = TextEditingController(text: '36');
  final _countController = TextEditingController(text: '1');

  String _type = 'fixed';
  String _material = 'fabric';

  double? _fabricSqft;
  double? _frameLength;
  int? _brackets;
  double? _shadeSqft;

  @override
  void dispose() { _widthController.dispose(); _projectionController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 48;
    final projection = double.tryParse(_projectionController.text) ?? 36;
    final count = int.tryParse(_countController.text) ?? 1;

    final widthFt = width / 12;
    final projectionFt = projection / 12;

    // Fabric/cover area (slope adds ~15% to flat area)
    final flatArea = widthFt * projectionFt;
    final fabricSqft = flatArea * 1.15 * count;

    // Frame material: perimeter + ribs
    final perimeter = (widthFt + projectionFt) * 2;
    final ribs = (widthFt / 2).ceil(); // rib every 2 feet
    final frameLength = (perimeter + (projectionFt * ribs)) * count;

    // Brackets: 2 per awning minimum, +1 per 4' width
    final bracketsPerAwning = 2 + (widthFt / 4).floor();
    final brackets = bracketsPerAwning * count;

    // Shade coverage on ground
    final shadeSqft = flatArea * count;

    setState(() { _fabricSqft = fabricSqft; _frameLength = frameLength; _brackets = brackets; _shadeSqft = shadeSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '48'; _projectionController.text = '36'; _countController.text = '1'; setState(() { _type = 'fixed'; _material = 'fabric'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Awning', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['fixed', 'retractable', 'freestanding'], _type, {'fixed': 'Fixed', 'retractable': 'Retractable', 'freestanding': 'Freestanding'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['fabric', 'aluminum', 'polycarbonate'], _material, {'fabric': 'Fabric', 'aluminum': 'Aluminum', 'polycarbonate': 'Polycarbonate'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Awnings', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Projection', unit: 'inches', controller: _projectionController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_fabricSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COVER MATERIAL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Frame Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_frameLength!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Brackets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_brackets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shade Coverage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_shadeSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBenefitsTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_type) {
      case 'fixed':
        return 'Fixed awnings: permanent installation. Most durable. Require periodic fabric replacement.';
      case 'retractable':
        return 'Retractable: manual or motorized. Protect fabric in bad weather. Higher cost, more versatile.';
      case 'freestanding':
        return 'Freestanding: no wall attachment. Good for patios. Requires anchor posts.';
      default:
        return 'Awnings reduce solar heat gain 65-77% on windows. Significant energy savings.';
    }
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

  Widget _buildBenefitsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AWNING BENEFITS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Heat reduction', '65-77% on windows'),
        _buildTableRow(colors, 'UV protection', 'Up to 99%'),
        _buildTableRow(colors, 'AC savings', '25% or more'),
        _buildTableRow(colors, 'Fabric life', '5-15 years'),
        _buildTableRow(colors, 'Frame life', '20+ years'),
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
