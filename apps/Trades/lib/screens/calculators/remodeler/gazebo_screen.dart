import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gazebo Calculator - Gazebo materials estimation
class GazeboScreen extends ConsumerStatefulWidget {
  const GazeboScreen({super.key});
  @override
  ConsumerState<GazeboScreen> createState() => _GazeboScreenState();
}

class _GazeboScreenState extends ConsumerState<GazeboScreen> {
  final _sizeController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '10');

  String _shape = 'octagon';
  String _roof = 'shingle';

  int? _posts;
  double? _railingFeet;
  double? _roofSqft;
  double? _floorSqft;
  double? _concreteBags;

  @override
  void dispose() { _sizeController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final size = double.tryParse(_sizeController.text) ?? 12;
    final height = double.tryParse(_heightController.text) ?? 10;

    int posts;
    double railingFeet;
    double floorSqft;
    double roofSqft;

    switch (_shape) {
      case 'octagon':
        posts = 8;
        // Octagon perimeter: 8 * side length, side = size * 0.414
        final sideLength = size * 0.414;
        railingFeet = 8 * sideLength;
        // Octagon area: 2 * side^2 * (1 + sqrt(2))
        floorSqft = 2 * sideLength * sideLength * 2.414;
        // Roof slightly larger
        roofSqft = floorSqft * 1.25;
        break;
      case 'hexagon':
        posts = 6;
        final sideLength = size / 2;
        railingFeet = 6 * sideLength;
        // Hexagon area
        floorSqft = (3 * 1.732 / 2) * sideLength * sideLength;
        roofSqft = floorSqft * 1.25;
        break;
      case 'rectangle':
        posts = 4;
        railingFeet = size * 4;
        floorSqft = size * size;
        roofSqft = floorSqft * 1.15;
        break;
      case 'oval':
        posts = 6;
        railingFeet = size * 3.14;
        floorSqft = (size / 2) * (size / 2) * 3.14 * 0.75;
        roofSqft = floorSqft * 1.2;
        break;
      default:
        posts = 8;
        railingFeet = size * 3;
        floorSqft = size * size * 0.8;
        roofSqft = floorSqft * 1.25;
    }

    // Concrete: 2 bags per post
    final concreteBags = posts * 2.0;

    setState(() { _posts = posts; _railingFeet = railingFeet; _roofSqft = roofSqft; _floorSqft = floorSqft; _concreteBags = concreteBags; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sizeController.text = '12'; _heightController.text = '10'; setState(() { _shape = 'octagon'; _roof = 'shingle'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gazebo', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHAPE', ['octagon', 'hexagon', 'rectangle', 'oval'], _shape, {'octagon': 'Octagon', 'hexagon': 'Hexagon', 'rectangle': 'Rectangle', 'oval': 'Oval'}, (v) { setState(() => _shape = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'ROOF', ['shingle', 'metal', 'cedar_shake'], _roof, {'shingle': 'Shingle', 'metal': 'Metal', 'cedar_shake': 'Cedar Shake'}, (v) { setState(() => _roof = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Size (diameter)', unit: 'feet', controller: _sizeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_posts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_floorSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Roof Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_roofSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Railing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_railingFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (60lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check setback requirements. May require building permit. Consider electrical for lighting/fans.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
        Text('COMMON SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '8\' octagon', '~50 sq ft, 2-4 people'),
        _buildTableRow(colors, '10\' octagon', '~80 sq ft, 4-6 people'),
        _buildTableRow(colors, '12\' octagon', '~115 sq ft, 6-8 people'),
        _buildTableRow(colors, '14\' octagon', '~155 sq ft, 8-10 people'),
        _buildTableRow(colors, 'Height', '8-12\' typical'),
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
