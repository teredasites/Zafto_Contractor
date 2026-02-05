import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mailbox Post Calculator - Mailbox installation materials estimation
class MailboxPostScreen extends ConsumerStatefulWidget {
  const MailboxPostScreen({super.key});
  @override
  ConsumerState<MailboxPostScreen> createState() => _MailboxPostScreenState();
}

class _MailboxPostScreenState extends ConsumerState<MailboxPostScreen> {
  final _heightController = TextEditingController(text: '42');
  final _countController = TextEditingController(text: '1');

  String _style = 'standard';
  String _postMaterial = 'wood';

  double? _postLength;
  double? _concreteBags;
  bool? _needsArm;
  String? _postSize;

  @override
  void dispose() { _heightController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final height = double.tryParse(_heightController.text) ?? 42;
    final count = int.tryParse(_countController.text) ?? 1;

    // USPS requires mailbox bottom at 41-45\" from road surface
    // Post in ground: 24\" minimum
    final postLength = (height + 24) / 12; // in feet

    // Concrete: 2 bags per post for standard, 3 for decorative
    double bagsPerPost;
    switch (_style) {
      case 'standard':
        bagsPerPost = 2;
        break;
      case 'decorative':
        bagsPerPost = 3;
        break;
      case 'cluster':
        bagsPerPost = 4;
        break;
      default:
        bagsPerPost = 2;
    }
    final concreteBags = bagsPerPost * count;

    // Post size depends on style
    String postSize;
    switch (_style) {
      case 'standard':
        postSize = '4x4';
        break;
      case 'decorative':
        postSize = '6x6';
        break;
      case 'cluster':
        postSize = '6x6 or 8x8';
        break;
      default:
        postSize = '4x4';
    }

    // Arm needed for standard posts
    final needsArm = _style == 'standard';

    setState(() { _postLength = postLength; _concreteBags = concreteBags; _needsArm = needsArm; _postSize = postSize; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _heightController.text = '42'; _countController.text = '1'; setState(() { _style = 'standard'; _postMaterial = 'wood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mailbox Post', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['standard', 'decorative', 'cluster'], _style, {'standard': 'Standard', 'decorative': 'Decorative', 'cluster': 'Cluster'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'POST MATERIAL', ['wood', 'metal', 'composite', 'brick'], _postMaterial, {'wood': 'Wood', 'metal': 'Metal', 'composite': 'Composite', 'brick': 'Brick'}, (v) { setState(() => _postMaterial = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Mailbox Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Quantity', unit: 'qty', controller: _countController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_postLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POST LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_postLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Post Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_postSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_needsArm!) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mailbox Arm', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1 per post', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('USPS requires: Bottom of mailbox 41-45\" from road. Front 6-8\" from curb. Use breakaway post in traffic areas.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRequirementsTable(colors),
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

  Widget _buildRequirementsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('USPS REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mailbox height', '41-45\" from road'),
        _buildTableRow(colors, 'Setback', '6-8\" from curb'),
        _buildTableRow(colors, 'Post depth', '24\" minimum'),
        _buildTableRow(colors, 'Box size', 'Approved sizes only'),
        _buildTableRow(colors, 'Numbers', '1\" min, visible'),
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
