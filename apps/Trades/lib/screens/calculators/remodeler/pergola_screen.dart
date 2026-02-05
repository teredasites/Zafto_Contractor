import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pergola Calculator - Pergola materials estimation
class PergolaScreen extends ConsumerStatefulWidget {
  const PergolaScreen({super.key});
  @override
  ConsumerState<PergolaScreen> createState() => _PergolaScreenState();
}

class _PergolaScreenState extends ConsumerState<PergolaScreen> {
  final _widthController = TextEditingController(text: '12');
  final _lengthController = TextEditingController(text: '14');
  final _heightController = TextEditingController(text: '9');

  String _material = 'cedar';
  String _style = 'attached';

  int? _posts;
  int? _beams;
  int? _rafters;
  int? _purlins;
  double? _concreteBags;

  @override
  void dispose() { _widthController.dispose(); _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 12;
    final length = double.tryParse(_lengthController.text) ?? 14;
    final height = double.tryParse(_heightController.text) ?? 9;

    // Posts: 4 for freestanding, 2 for attached
    int posts;
    switch (_style) {
      case 'attached':
        posts = 2;
        break;
      case 'freestanding':
        posts = width > 12 || length > 14 ? 6 : 4;
        break;
      case 'corner':
        posts = 2;
        break;
      default:
        posts = 4;
    }

    // Beams: 2 main beams spanning length
    final beams = 2;

    // Rafters: span width, typically 16\" OC
    final rafters = ((length * 12) / 16).ceil() + 1;

    // Purlins/slats: span length on top of rafters, 4-6\" spacing
    final purlins = ((width * 12) / 5).ceil();

    // Concrete: 2 bags per post for footing
    final concreteBags = posts * 2.0;

    setState(() { _posts = posts; _beams = beams; _rafters = rafters; _purlins = purlins; _concreteBags = concreteBags; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '12'; _lengthController.text = '14'; _heightController.text = '9'; setState(() { _material = 'cedar'; _style = 'attached'; }); _calculate(); }

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
            _buildSelector(colors, 'MATERIAL', ['cedar', 'pressure_treated', 'vinyl', 'aluminum'], _material, {'cedar': 'Cedar', 'pressure_treated': 'PT Wood', 'vinyl': 'Vinyl', 'aluminum': 'Aluminum'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STYLE', ['attached', 'freestanding', 'corner'], _style, {'attached': 'Attached', 'freestanding': 'Freestanding', 'corner': 'Corner'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Post Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_posts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS (6x6)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Beams (2x10)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_beams', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rafters (2x8)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rafters', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Purlins (2x2)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_purlins', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Post footings: 12\" diameter, below frost line. Use post anchors for concrete pads. Check local codes.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
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
        Text('TYPICAL LUMBER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Posts', '6x6 or 8x8'),
        _buildTableRow(colors, 'Beams', '2x10 or 2x12'),
        _buildTableRow(colors, 'Rafters', '2x8 at 16\" OC'),
        _buildTableRow(colors, 'Purlins', '2x2 or 2x4'),
        _buildTableRow(colors, 'Hardware', 'Post bases, brackets'),
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
