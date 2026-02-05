import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Door Sizing Calculator - Replacement door sizing
class DoorSizingScreen extends ConsumerStatefulWidget {
  const DoorSizingScreen({super.key});
  @override
  ConsumerState<DoorSizingScreen> createState() => _DoorSizingScreenState();
}

class _DoorSizingScreenState extends ConsumerState<DoorSizingScreen> {
  final _widthController = TextEditingController(text: '32');
  final _heightController = TextEditingController(text: '80');
  final _thicknessController = TextEditingController(text: '1.375');

  String _type = 'interior';
  String _style = 'panel';

  String? _standardSize;
  String? _hingeSide;
  String? _swingDirection;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 32;
    final height = double.tryParse(_heightController.text) ?? 80;
    final thickness = double.tryParse(_thicknessController.text) ?? 1.375;

    // Determine standard size
    String standardSize;
    if (width == 24) {
      standardSize = '2-0 (24\")';
    } else if (width == 28) {
      standardSize = '2-4 (28\")';
    } else if (width == 30) {
      standardSize = '2-6 (30\")';
    } else if (width == 32) {
      standardSize = '2-8 (32\")';
    } else if (width == 34) {
      standardSize = '2-10 (34\")';
    } else if (width == 36) {
      standardSize = '3-0 (36\")';
    } else {
      standardSize = 'Custom (${width.toStringAsFixed(0)}\")';
    }

    // Standard heights
    if (height != 80 && height != 84 && height != 96) {
      standardSize += ' x Custom height';
    }

    // Thickness info
    String thicknessInfo;
    if (thickness == 1.375) {
      thicknessInfo = 'Standard interior (1-3/8\")';
    } else if (thickness == 1.75) {
      thicknessInfo = 'Standard exterior (1-3/4\")';
    } else {
      thicknessInfo = 'Non-standard thickness';
    }

    setState(() { _standardSize = standardSize; _hingeSide = 'Measure from exterior/hallway'; _swingDirection = thicknessInfo; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '32'; _heightController.text = '80'; _thicknessController.text = '1.375'; setState(() { _type = 'interior'; _style = 'panel'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Door Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['interior', 'exterior', 'bifold', 'pocket'], _type, {'interior': 'Interior', 'exterior': 'Exterior', 'bifold': 'Bifold', 'pocket': 'Pocket'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STYLE', ['panel', 'flush', 'french', 'slab'], _style, {'panel': 'Panel', 'flush': 'Flush', 'french': 'French', 'slab': 'Slab'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Door Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Door Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_standardSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STANDARD SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_standardSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Thickness', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_swingDirection!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Measure existing door, not opening. For pre-hung, add 2\" width and 2.5\" height for frame.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD DOOR SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '2-0 (24\")', 'Closet, utility'),
        _buildTableRow(colors, '2-6 (30\")', 'Bathroom minimum'),
        _buildTableRow(colors, '2-8 (32\")', 'Standard interior'),
        _buildTableRow(colors, '3-0 (36\")', 'Entry, ADA compliant'),
        _buildTableRow(colors, 'Height', '80\" or 96\" (8\')'),
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
