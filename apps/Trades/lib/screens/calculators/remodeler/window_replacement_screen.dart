import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Window Replacement Calculator - Replacement window sizing
class WindowReplacementScreen extends ConsumerStatefulWidget {
  const WindowReplacementScreen({super.key});
  @override
  ConsumerState<WindowReplacementScreen> createState() => _WindowReplacementScreenState();
}

class _WindowReplacementScreenState extends ConsumerState<WindowReplacementScreen> {
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '48');

  String _type = 'doublehung';
  String _glass = 'double';

  String? _orderSize;
  double? _sqft;
  String? _uiSize;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 48;

    // Order size: deduct 1/8" to 1/4" for pocket replacement
    final orderWidth = width - 0.25;
    final orderHeight = height - 0.25;

    final sqft = (width * height) / 144;

    // UI size format (feet-inches notation)
    final widthFt = (width / 12).floor();
    final widthIn = (width % 12).round();
    final heightFt = (height / 12).floor();
    final heightIn = (height % 12).round();

    final uiSize = '${widthFt}\'${widthIn}" x ${heightFt}\'${heightIn}"';

    setState(() {
      _orderSize = '${orderWidth.toStringAsFixed(2)}" x ${orderHeight.toStringAsFixed(2)}"';
      _sqft = sqft;
      _uiSize = uiSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _heightController.text = '48'; setState(() { _type = 'doublehung'; _glass = 'double'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Window Replacement', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['doublehung', 'casement', 'slider', 'picture'], _type, {'doublehung': 'Double Hung', 'casement': 'Casement', 'slider': 'Slider', 'picture': 'Picture'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'GLASS', ['double', 'triple', 'lowE'], _glass, {'double': 'Double Pane', 'triple': 'Triple Pane', 'lowE': 'Low-E'}, (v) { setState(() => _glass = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Opening Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Opening Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_orderSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ORDER SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_orderSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('UI Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_uiSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Glass Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Measure inside frame at 3 points (top/mid/bottom). Use smallest measurement. Check for square.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WINDOW TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Double hung', 'Both sashes slide'),
        _buildTableRow(colors, 'Casement', 'Crank out, best seal'),
        _buildTableRow(colors, 'Slider', 'Horizontal slide'),
        _buildTableRow(colors, 'Picture', 'Fixed, no open'),
        _buildTableRow(colors, 'Awning', 'Hinged at top'),
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
