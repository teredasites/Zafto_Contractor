import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gutter Calculator - Gutters and downspouts
class GutterScreen extends ConsumerStatefulWidget {
  const GutterScreen({super.key});
  @override
  ConsumerState<GutterScreen> createState() => _GutterScreenState();
}

class _GutterScreenState extends ConsumerState<GutterScreen> {
  final _gutterLengthController = TextEditingController(text: '150');
  final _roofAreaController = TextEditingController(text: '2000');

  String _gutterSize = '5inch';
  String _material = 'aluminum';

  int? _gutterSections;
  int? _downspouts;
  int? _elbows;
  int? _hangers;

  @override
  void dispose() { _gutterLengthController.dispose(); _roofAreaController.dispose(); super.dispose(); }

  void _calculate() {
    final gutterLength = double.tryParse(_gutterLengthController.text) ?? 0;
    final roofArea = double.tryParse(_roofAreaController.text) ?? 0;

    // Gutter sections: 10' standard lengths
    final gutterSections = (gutterLength / 10).ceil();

    // Downspouts: 1 per 30-40 ft of gutter, or 1 per 600-800 sqft roof
    final downspoutsByLength = (gutterLength / 35).ceil();
    final downspoutsByArea = (roofArea / 700).ceil();
    final downspouts = downspoutsByLength > downspoutsByArea ? downspoutsByLength : downspoutsByArea;

    // Elbows: 2 per downspout (top and bottom typically)
    final elbows = downspouts * 2 + 2; // Plus corners

    // Hangers: 1 every 2-3 feet
    final hangers = (gutterLength / 2.5).ceil();

    setState(() { _gutterSections = gutterSections; _downspouts = downspouts < 2 ? 2 : downspouts; _elbows = elbows; _hangers = hangers; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _gutterLengthController.text = '150'; _roofAreaController.text = '2000'; setState(() { _gutterSize = '5inch'; _material = 'aluminum'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gutters', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GUTTER SIZE', ['5inch', '6inch'], _gutterSize, {'5inch': '5\" K-Style', '6inch': '6\" K-Style'}, (v) { setState(() => _gutterSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['aluminum', 'copper', 'vinyl', 'steel'], _material, {'aluminum': 'Aluminum', 'copper': 'Copper', 'vinyl': 'Vinyl', 'steel': 'Steel'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Gutter Length', unit: 'feet', controller: _gutterLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Roof Area', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gutterSections != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('MATERIALS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gutter Sections (10\')', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_gutterSections', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Downspouts (10\')', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_downspouts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Elbows', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_elbows', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hangers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hangers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Slope 1/4\" per 10\'. Extend downspouts 4-6\' from foundation.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGutterTable(colors),
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

  Widget _buildGutterTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SIZING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '5\" gutter', 'Standard residential'),
        _buildTableRow(colors, '6\" gutter', 'High rainfall/large roof'),
        _buildTableRow(colors, '2x3\" downspout', 'With 5\" gutter'),
        _buildTableRow(colors, '3x4\" downspout', 'With 6\" gutter'),
        _buildTableRow(colors, 'Screens/guards', 'Reduce maintenance'),
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
