import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Arbor Calculator - Garden arbor materials estimation
class ArborScreen extends ConsumerStatefulWidget {
  const ArborScreen({super.key});
  @override
  ConsumerState<ArborScreen> createState() => _ArborScreenState();
}

class _ArborScreenState extends ConsumerState<ArborScreen> {
  final _widthController = TextEditingController(text: '4');
  final _depthController = TextEditingController(text: '2');
  final _heightController = TextEditingController(text: '8');

  String _style = 'classic';
  String _material = 'cedar';

  int? _posts;
  double? _beamFeet;
  double? _rafterFeet;
  double? _latticeSqft;
  double? _concreteBags;

  @override
  void dispose() { _widthController.dispose(); _depthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 4;
    final depth = double.tryParse(_depthController.text) ?? 2;
    final height = double.tryParse(_heightController.text) ?? 8;

    // Posts: typically 4 (2 on each side)
    const posts = 4;

    // Beams: 2 crossing the top
    final beamFeet = width * 2 + 2; // +2 for overhang

    // Rafters: perpendicular to beams
    final rafterCount = 4; // typical
    final rafterFeet = (depth + 0.5) * rafterCount; // +overhang

    // Lattice sides (if classic or cottage style)
    double latticeSqft;
    switch (_style) {
      case 'classic':
        latticeSqft = (depth * height * 2) * 0.5; // partial lattice
        break;
      case 'cottage':
        latticeSqft = (depth * height * 2) + (width * 2); // full sides + top
        break;
      case 'modern':
        latticeSqft = 0; // no lattice
        break;
      case 'rustic':
        latticeSqft = depth * height; // one side
        break;
      default:
        latticeSqft = 0;
    }

    // Concrete: 2 bags per post
    final concreteBags = posts * 2.0;

    setState(() { _posts = posts; _beamFeet = beamFeet; _rafterFeet = rafterFeet; _latticeSqft = latticeSqft; _concreteBags = concreteBags; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '4'; _depthController.text = '2'; _heightController.text = '8'; setState(() { _style = 'classic'; _material = 'cedar'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Arbor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['classic', 'cottage', 'modern', 'rustic'], _style, {'classic': 'Classic', 'cottage': 'Cottage', 'modern': 'Modern', 'rustic': 'Rustic'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['cedar', 'redwood', 'vinyl', 'metal'], _material, {'cedar': 'Cedar', 'redwood': 'Redwood', 'vinyl': 'Vinyl', 'metal': 'Metal'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'feet', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_posts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS (4x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Beams (2x6)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_beamFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rafters (2x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rafterFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_latticeSqft! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Lattice', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_latticeSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard walkway width: 3-4 feet. Set posts 24\" deep or below frost line. Allow for climbing plants to mature.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON ARBOR SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard', '4\' W x 2\' D x 8\' H'),
        _buildTableRow(colors, 'Wide', '5\' W x 3\' D x 8\' H'),
        _buildTableRow(colors, 'Grand', '6\' W x 4\' D x 9\' H'),
        _buildTableRow(colors, 'Double', '8\' W x 4\' D x 9\' H'),
        _buildTableRow(colors, 'Min width', '3\' for walkthrough'),
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
