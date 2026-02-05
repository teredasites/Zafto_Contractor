import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fence Material Calculator - Complete fence materials
class FenceMaterialScreen extends ConsumerStatefulWidget {
  const FenceMaterialScreen({super.key});
  @override
  ConsumerState<FenceMaterialScreen> createState() => _FenceMaterialScreenState();
}

class _FenceMaterialScreenState extends ConsumerState<FenceMaterialScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _fenceType = 'privacy';
  String _height = '6';

  int? _postsNeeded;
  int? _railsNeeded;
  int? _picketsNeeded;
  double? _concreteBags;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;
    final heightFt = double.tryParse(_height) ?? 6;

    // Post spacing: 8' on center
    final posts = (length / 8).ceil() + 1;

    // Rails: 2 for 4' fence, 3 for 6' fence
    final railsPerSection = heightFt >= 6 ? 3 : 2;
    final sections = posts - 1;
    final rails = sections * railsPerSection;

    // Pickets vary by type
    int pickets;
    switch (_fenceType) {
      case 'privacy':
        // 5.5" wide pickets, no gap
        pickets = ((length * 12) / 5.5).ceil();
        break;
      case 'shadowbox':
        // Both sides, 50% overlap
        pickets = ((length * 12) / 5.5 * 1.5).ceil();
        break;
      case 'picket':
        // 3.5" pickets with 2" gap
        pickets = ((length * 12) / 5.5).ceil();
        break;
      default:
        pickets = ((length * 12) / 5.5).ceil();
    }

    // Concrete: 2 bags per post for 6' fence, 1.5 for 4'
    final bagsPerPost = heightFt >= 6 ? 2.0 : 1.5;
    final concrete = posts * bagsPerPost;

    setState(() {
      _postsNeeded = posts;
      _railsNeeded = rails;
      _picketsNeeded = pickets;
      _concreteBags = concrete;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _fenceType = 'privacy'; _height = '6'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fence Materials', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FENCE TYPE', ['picket', 'privacy', 'shadowbox'], _fenceType, {'picket': 'Picket', 'privacy': 'Privacy', 'shadowbox': 'Shadowbox'}, (v) { setState(() => _fenceType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'HEIGHT', ['4', '6', '8'], _height, {'4': "4'", '6': "6'", '8': "8'"}, (v) { setState(() => _height = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Fence Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_postsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MATERIALS NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildMaterialRow(colors, 'Posts (4×4)', '$_postsNeeded'),
                _buildMaterialRow(colors, 'Rails (2×4)', '$_railsNeeded'),
                _buildMaterialRow(colors, 'Pickets', '$_picketsNeeded'),
                _buildMaterialRow(colors, 'Concrete (80 lb)', '${_concreteBags!.toStringAsFixed(0)} bags'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFenceGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
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

  Widget _buildFenceGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FENCE SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Post spacing', "8' on center"),
        _buildTableRow(colors, 'Post depth', "1/3 of length + 6\""),
        _buildTableRow(colors, 'Rail position', 'Top, middle, bottom'),
        _buildTableRow(colors, 'Picket gap', '0\" privacy, 2-3\" picket'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
