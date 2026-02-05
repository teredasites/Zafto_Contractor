import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pergola Calculator - Posts, beams, rafters, slats
class PergolaScreen extends ConsumerStatefulWidget {
  const PergolaScreen({super.key});
  @override
  ConsumerState<PergolaScreen> createState() => _PergolaScreenState();
}

class _PergolaScreenState extends ConsumerState<PergolaScreen> {
  final _lengthController = TextEditingController(text: '12');
  final _widthController = TextEditingController(text: '10');
  final _heightController = TextEditingController(text: '9');

  String _postSize = '6x6';
  int _rafterSpacing = 16; // inches

  int? _posts;
  int? _beams;
  int? _rafters;
  int? _slats;
  int? _concreteBags;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 12;
    final width = double.tryParse(_widthController.text) ?? 10;

    // Posts: 4 corners minimum, add intermediate for spans over 8'
    int posts = 4;
    if (length > 8) posts += 2; // Add middle posts on long sides
    if (width > 8) posts += 2; // Add middle posts on short sides

    // Beams: 2 (one on each long side)
    const beams = 2;

    // Rafters: span the width, spaced per setting
    final lengthInches = length * 12;
    final rafters = (lengthInches / _rafterSpacing).ceil() + 1;

    // Slats/purlins: perpendicular to rafters, ~12" spacing
    final widthInches = width * 12;
    final slats = (widthInches / 12).ceil() + 1;

    // Concrete: 3 bags per 6x6 post, 4 bags per 8x8
    final bagsPerPost = _postSize == '6x6' ? 3 : 4;
    final concreteBags = posts * bagsPerPost;

    setState(() {
      _posts = posts;
      _beams = beams;
      _rafters = rafters;
      _slats = slats;
      _concreteBags = concreteBags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '12'; _widthController.text = '10'; _heightController.text = '9'; setState(() { _postSize = '6x6'; _rafterSpacing = 16; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pergola', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'POST SIZE', ['6x6', '8x8'], _postSize, {'6x6': '6×6"', '8x8': '8×8"'}, (v) { setState(() => _postSize = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Rafter spacing:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(children: [12, 16, 24].map((s) {
                  final isSelected = _rafterSpacing == s;
                  return Expanded(child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() { _rafterSpacing = s; }); _calculate(); },
                    child: Container(margin: EdgeInsets.only(right: s != 24 ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
                      child: Text('$s"', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ));
                }).toList()),
              ),
            ]),
            const SizedBox(height: 24),
            if (_posts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('MATERIALS LIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildResultRow(colors, 'Posts ($_postSize)', '$_posts'),
                _buildResultRow(colors, 'Beams (2×10 or 2×12)', '$_beams'),
                _buildResultRow(colors, 'Rafters (2×8)', '$_rafters'),
                _buildResultRow(colors, 'Slats (2×2 or 2×4)', '$_slats'),
                _buildResultRow(colors, 'Concrete bags', '$_concreteBags'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPergolaGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildPergolaGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONSTRUCTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Post depth', '24-36" below frost'),
        _buildTableRow(colors, 'Post height', "8-10' typical"),
        _buildTableRow(colors, 'Beam overhang', '12-18" past posts'),
        _buildTableRow(colors, 'Rafter overhang', '12-24" past beams'),
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
