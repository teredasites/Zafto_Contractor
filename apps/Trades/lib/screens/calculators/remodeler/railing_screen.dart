import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Railing Calculator - Stair and deck railing estimation
class RailingScreen extends ConsumerStatefulWidget {
  const RailingScreen({super.key});
  @override
  ConsumerState<RailingScreen> createState() => _RailingScreenState();
}

class _RailingScreenState extends ConsumerState<RailingScreen> {
  final _lengthController = TextEditingController(text: '12');
  final _sectionsController = TextEditingController(text: '2');

  String _type = 'wood';
  String _style = 'standard';

  double? _railLF;
  int? _posts;
  int? _balusters;
  int? _brackets;

  @override
  void dispose() { _lengthController.dispose(); _sectionsController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final sections = int.tryParse(_sectionsController.text) ?? 1;

    // Top and bottom rail
    final railLF = length * 2;

    // Posts: at ends and every 6-8' max
    final postsPerSection = ((length / sections) / 6).ceil() + 1;
    final posts = postsPerSection * sections;

    // Balusters: 4\" spacing max = 3 per foot
    final balusters = (length * 3).ceil();

    // Wall brackets if wall-mounted
    final brackets = _style == 'wall' ? ((length / 4).ceil() + 1) : 0;

    setState(() { _railLF = railLF; _posts = posts; _balusters = balusters; _brackets = brackets; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '12'; _sectionsController.text = '2'; setState(() { _type = 'wood'; _style = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Railing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['wood', 'metal', 'cable', 'glass'], _type, {'wood': 'Wood', 'metal': 'Metal', 'cable': 'Cable', 'glass': 'Glass'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STYLE', ['standard', 'wall', 'half'], _style, {'standard': 'Standard', 'wall': 'Wall Mount', 'half': 'Half Wall'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Sections', unit: 'qty', controller: _sectionsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_railLF != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RAIL MATERIAL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_railLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Posts/Newels', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                if (_style != 'wall') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Balusters (~4\" OC)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_balusters', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_style == 'wall') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Brackets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_brackets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Code: 36\" min height (34\" graspable), 4\" max baluster spacing, posts every 6-8\'.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCodeTable(colors),
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

  Widget _buildCodeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CODE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min height (stairs)', '34\"'),
        _buildTableRow(colors, 'Min height (deck)', '36\"'),
        _buildTableRow(colors, 'Graspable rail', '1.25\" - 2\" dia'),
        _buildTableRow(colors, 'Baluster gap', '4\" max'),
        _buildTableRow(colors, 'Triangle rule', '4\" sphere test'),
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
