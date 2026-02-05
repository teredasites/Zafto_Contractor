import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Privacy Fence Calculator - Privacy fence materials estimation
class PrivacyFenceScreen extends ConsumerStatefulWidget {
  const PrivacyFenceScreen({super.key});
  @override
  ConsumerState<PrivacyFenceScreen> createState() => _PrivacyFenceScreenState();
}

class _PrivacyFenceScreenState extends ConsumerState<PrivacyFenceScreen> {
  final _lengthController = TextEditingController(text: '150');
  final _heightController = TextEditingController(text: '6');

  String _style = 'solid';
  String _material = 'cedar';

  int? _posts;
  int? _rails;
  int? _pickets;
  double? _concreteBags;
  int? _gates;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 150;
    final height = double.tryParse(_heightController.text) ?? 6;

    // Posts: every 8 feet + end posts
    final postSpacing = 8.0;
    final posts = (length / postSpacing).ceil() + 1;

    // Rails: typically 2 for 4' fence, 3 for 6'+ fence
    final railsPerSection = height >= 6 ? 3 : 2;
    final rails = (posts - 1) * railsPerSection;

    // Pickets: 5.5\" wide pickets with 0\" gap for privacy
    final picketsPerFoot = 12 / 5.5;
    final pickets = (length * picketsPerFoot).ceil();

    // Concrete: 2 bags per post
    final concreteBags = posts * 2.0;

    // Estimate 1 gate per 50' of fence
    final gates = (length / 50).ceil();

    setState(() { _posts = posts; _rails = rails; _pickets = pickets; _concreteBags = concreteBags; _gates = gates; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '150'; _heightController.text = '6'; setState(() { _style = 'solid'; _material = 'cedar'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Privacy Fence', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['solid', 'shadowbox', 'board_on_board'], _style, {'solid': 'Solid', 'shadowbox': 'Shadowbox', 'board_on_board': 'Board on Board'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['cedar', 'pine', 'redwood', 'composite'], _material, {'cedar': 'Cedar', 'pine': 'PT Pine', 'redwood': 'Redwood', 'composite': 'Composite'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gates (est.)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_gates', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check property lines before building. Many areas limit fence height to 6\'. Post depth: 1/3 of total post length.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMaterialTable(colors),
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

  Widget _buildMaterialTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('POST SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '4\' fence', '6\' post (2\' in ground)'),
        _buildTableRow(colors, '5\' fence', '7\' post (2\' in ground)'),
        _buildTableRow(colors, '6\' fence', '9\' post (3\' in ground)'),
        _buildTableRow(colors, '8\' fence', '11\' post (3\' in ground)'),
        _buildTableRow(colors, 'Post spacing', '6-8\' on center'),
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
