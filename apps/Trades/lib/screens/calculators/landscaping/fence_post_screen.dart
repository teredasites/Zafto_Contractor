import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fence Post Calculator - Posts, concrete, rails
class FencePostScreen extends ConsumerStatefulWidget {
  const FencePostScreen({super.key});
  @override
  ConsumerState<FencePostScreen> createState() => _FencePostScreenState();
}

class _FencePostScreenState extends ConsumerState<FencePostScreen> {
  final _lengthController = TextEditingController(text: '100');
  final _spacingController = TextEditingController(text: '8');
  final _heightController = TextEditingController(text: '6');

  String _postType = 'wood';
  int _corners = 2;
  int _gates = 1;

  int? _postsNeeded;
  int? _concreteBags;
  int? _rails;
  int? _pickets;

  @override
  void dispose() { _lengthController.dispose(); _spacingController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;
    final spacing = double.tryParse(_spacingController.text) ?? 8;
    final heightFt = double.tryParse(_heightController.text) ?? 6;

    // Posts = (length / spacing) + 1 + corners + gate posts
    final linePosts = (length / spacing).ceil() + 1;
    final totalPosts = linePosts + _corners + (_gates * 2);

    // Concrete: 2 bags per post for 4x4, 3 bags for 6x6
    final bagsPerPost = _postType == 'wood' ? 2 : 3;
    final concreteBags = totalPosts * bagsPerPost;

    // Rails: 2 for 4' fence, 3 for 6' fence
    final railsPerSection = heightFt >= 6 ? 3 : 2;
    final sections = (length / spacing).ceil();
    final rails = sections * railsPerSection;

    // Pickets for privacy: ~16 per 8' section (6" pickets)
    final picketsPerSection = (spacing * 12 / 6).ceil(); // 6" wide pickets
    final pickets = sections * picketsPerSection;

    setState(() {
      _postsNeeded = totalPosts;
      _concreteBags = concreteBags;
      _rails = rails;
      _pickets = pickets;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; _spacingController.text = '8'; _heightController.text = '6'; setState(() { _postType = 'wood'; _corners = 2; _gates = 1; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fence Posts', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'POST TYPE', ['wood', 'metal'], _postType, {'wood': '4x4 Wood', 'metal': '2-3/8" Metal'}, (v) { setState(() => _postType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Post Spacing', unit: 'ft', controller: _spacingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fence Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Corners', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  _buildCounterButton(colors, LucideIcons.minus, () { if (_corners > 0) setState(() { _corners--; _calculate(); }); }),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$_corners', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
                  _buildCounterButton(colors, LucideIcons.plus, () { setState(() { _corners++; _calculate(); }); }),
                ]),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gates', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Row(children: [
                  _buildCounterButton(colors, LucideIcons.minus, () { if (_gates > 0) setState(() { _gates--; _calculate(); }); }),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$_gates', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
                  _buildCounterButton(colors, LucideIcons.plus, () { setState(() { _gates++; _calculate(); }); }),
                ]),
              ])),
            ]),
            const SizedBox(height: 24),
            if (_postsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (50 lb bags)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_concreteBags bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rails (2x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rails', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pickets (6" privacy)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pickets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCounterButton(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Icon(icon, color: colors.textPrimary, size: 16),
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

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('POST INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Hole depth', '1/3 of post + 6"'),
        _buildTableRow(colors, 'Hole width', '3x post width'),
        _buildTableRow(colors, '6\' fence', '30" deep hole'),
        _buildTableRow(colors, 'Gravel base', '4-6" for drainage'),
        _buildTableRow(colors, 'Concrete set', '24-48 hours'),
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
