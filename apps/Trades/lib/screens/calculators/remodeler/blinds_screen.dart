import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Blinds Calculator - Window blind sizing estimation
class BlindsScreen extends ConsumerStatefulWidget {
  const BlindsScreen({super.key});
  @override
  ConsumerState<BlindsScreen> createState() => _BlindsScreenState();
}

class _BlindsScreenState extends ConsumerState<BlindsScreen> {
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '48');
  final _quantityController = TextEditingController(text: '6');

  String _mount = 'inside';
  String _type = 'faux';

  double? _orderWidth;
  double? _orderHeight;
  double? _totalSqft;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _quantityController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 48;
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    double orderWidth;
    double orderHeight;

    if (_mount == 'inside') {
      // Inside mount: deduct 1/4" to 1/2" for clearance
      orderWidth = width - 0.5;
      orderHeight = height;
    } else {
      // Outside mount: add 1.5-3" each side for coverage
      orderWidth = width + 3;
      orderHeight = height + 3;
    }

    final widthFt = orderWidth / 12;
    final heightFt = orderHeight / 12;
    final totalSqft = widthFt * heightFt * quantity;

    setState(() { _orderWidth = orderWidth; _orderHeight = orderHeight; _totalSqft = totalSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _heightController.text = '48'; _quantityController.text = '6'; setState(() { _mount = 'inside'; _type = 'faux'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Blinds', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MOUNT', ['inside', 'outside'], _mount, {'inside': 'Inside Mount', 'outside': 'Outside Mount'}, (v) { setState(() => _mount = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TYPE', ['faux', 'wood', 'aluminum', 'vertical'], _type, {'faux': 'Faux Wood', 'wood': 'Real Wood', 'aluminum': 'Aluminum', 'vertical': 'Vertical'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Quantity', unit: 'windows', controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_orderWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ORDER SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_orderWidth!.toStringAsFixed(1)}\" x ${_orderHeight!.toStringAsFixed(1)}\"', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Coverage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_mount == 'inside' ? 'Inside mount needs min 2.5\" depth. Measure at 3 points, use smallest width.' : 'Outside mount: extend 1.5\" past frame each side for light blockage.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMeasureTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildMeasureTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASURING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Inside mount', 'Measure opening, not trim'),
        _buildTableRow(colors, 'Width', 'Top, middle, bottom'),
        _buildTableRow(colors, 'Height', 'Left, center, right'),
        _buildTableRow(colors, 'Use smallest', 'For inside mount'),
        _buildTableRow(colors, 'Min depth', '2.5\" for inside mount'),
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
