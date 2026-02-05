import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Plant Spacing Calculator - Grid or triangular layout
class PlantSpacingScreen extends ConsumerStatefulWidget {
  const PlantSpacingScreen({super.key});
  @override
  ConsumerState<PlantSpacingScreen> createState() => _PlantSpacingScreenState();
}

class _PlantSpacingScreenState extends ConsumerState<PlantSpacingScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '10');
  final _spacingController = TextEditingController(text: '18');

  String _pattern = 'grid';

  int? _plantsNeeded;
  int? _rows;
  int? _plantsPerRow;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _spacingController.dispose(); super.dispose(); }

  void _calculate() {
    final lengthFt = double.tryParse(_lengthController.text) ?? 20;
    final widthFt = double.tryParse(_widthController.text) ?? 10;
    final spacingIn = double.tryParse(_spacingController.text) ?? 18;

    final lengthIn = lengthFt * 12;
    final widthIn = widthFt * 12;

    int plants;
    int rows;
    int perRow;

    if (_pattern == 'grid') {
      perRow = (lengthIn / spacingIn).floor() + 1;
      rows = (widthIn / spacingIn).floor() + 1;
      plants = perRow * rows;
    } else {
      perRow = (lengthIn / spacingIn).floor() + 1;
      final rowSpacing = spacingIn * 0.866;
      rows = (widthIn / rowSpacing).floor() + 1;
      final fullRows = (rows / 2).ceil();
      final shortRows = rows - fullRows;
      plants = (fullRows * perRow) + (shortRows * (perRow - 1));
    }

    setState(() {
      _plantsNeeded = plants;
      _rows = rows;
      _plantsPerRow = perRow;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '10'; _spacingController.text = '18'; setState(() { _pattern = 'grid'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Plant Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PLANTING PATTERN', ['grid', 'triangle'], _pattern, {'grid': 'Square Grid', 'triangle': 'Triangular'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bed Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Plant Spacing', unit: 'inches', controller: _spacingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_plantsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PLANTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plantsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Number of rows', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rows', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plants per row', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plantsPerRow', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpacingGuide(colors),
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

  Widget _buildSpacingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SPACINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Groundcover', '6-12"'),
        _buildTableRow(colors, 'Perennials', '12-18"'),
        _buildTableRow(colors, 'Small shrubs', '24-36"'),
        _buildTableRow(colors, 'Medium shrubs', '36-48"'),
        _buildTableRow(colors, 'Large shrubs', '48-72"'),
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
