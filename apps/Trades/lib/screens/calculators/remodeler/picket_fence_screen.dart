import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Picket Fence Calculator - Picket fence materials estimation
class PicketFenceScreen extends ConsumerStatefulWidget {
  const PicketFenceScreen({super.key});
  @override
  ConsumerState<PicketFenceScreen> createState() => _PicketFenceScreenState();
}

class _PicketFenceScreenState extends ConsumerState<PicketFenceScreen> {
  final _lengthController = TextEditingController(text: '100');
  final _heightController = TextEditingController(text: '4');
  final _gapController = TextEditingController(text: '2.5');

  String _style = 'pointed';
  String _material = 'cedar';

  int? _posts;
  int? _rails;
  int? _pickets;
  double? _concreteBags;
  int? _postCaps;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); _gapController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;
    final height = double.tryParse(_heightController.text) ?? 4;
    final gap = double.tryParse(_gapController.text) ?? 2.5;

    // Posts: every 6-8 feet
    final postSpacing = 6.0;
    final posts = (length / postSpacing).ceil() + 1;

    // Rails: 2 for standard picket fence
    final rails = (posts - 1) * 2;

    // Pickets: 3.5\" picket width + gap
    final picketWidth = 3.5;
    final picketsPerFoot = 12 / (picketWidth + gap);
    final pickets = (length * picketsPerFoot).ceil();

    // Concrete: 1.5 bags per post (shallower than privacy fence)
    final concreteBags = posts * 1.5;

    // Post caps
    final postCaps = posts;

    setState(() { _posts = posts; _rails = rails; _pickets = pickets; _concreteBags = concreteBags; _postCaps = postCaps; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; _heightController.text = '4'; _gapController.text = '2.5'; setState(() { _style = 'pointed'; _material = 'cedar'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Picket Fence', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PICKET STYLE', ['pointed', 'flat', 'dog_ear', 'french_gothic'], _style, {'pointed': 'Pointed', 'flat': 'Flat Top', 'dog_ear': 'Dog Ear', 'french_gothic': 'Gothic'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['cedar', 'pine', 'vinyl', 'composite'], _material, {'cedar': 'Cedar', 'pine': 'PT Pine', 'vinyl': 'Vinyl', 'composite': 'Composite'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Fence Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Picket Gap', unit: 'inches', controller: _gapController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_posts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PICKETS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pickets', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Posts (4x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rails (2x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rails', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Post Caps', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postCaps', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard picket gap: 2-3\". Space pickets using a scrap board as a guide. Prime or seal cut ends.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
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

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PICKET FENCE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard height', '3-4 feet'),
        _buildTableRow(colors, 'Picket width', '3.5\" typical'),
        _buildTableRow(colors, 'Picket thickness', '3/4\" to 1\"'),
        _buildTableRow(colors, 'Post spacing', '6-8 feet'),
        _buildTableRow(colors, 'Rail size', '2x4 or 2x3'),
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
