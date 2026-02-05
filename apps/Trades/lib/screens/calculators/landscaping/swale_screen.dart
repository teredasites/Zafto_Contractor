import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Swale Calculator - Drainage channel dimensions
class SwaleScreen extends ConsumerStatefulWidget {
  const SwaleScreen({super.key});
  @override
  ConsumerState<SwaleScreen> createState() => _SwaleScreenState();
}

class _SwaleScreenState extends ConsumerState<SwaleScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _drainageAreaController = TextEditingController(text: '5000');

  String _swaleType = 'grass';

  double? _width;
  double? _depth;
  double? _excavationCuYd;
  double? _capacity;

  @override
  void dispose() { _lengthController.dispose(); _drainageAreaController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final drainageArea = double.tryParse(_drainageAreaController.text) ?? 5000;

    // Size based on drainage area (rough sizing)
    // ~1 sq ft swale cross-section per 500 sq ft drainage
    final crossSectionSqFt = drainageArea / 500;

    // Calculate width and depth based on type
    double width;
    double depth;
    switch (_swaleType) {
      case 'grass':
        // Shallow and wide (6:1 side slopes)
        depth = (crossSectionSqFt / 3).clamp(0.5, 1.5);
        width = depth * 6;
        break;
      case 'rock':
        // Moderate depth (3:1 side slopes)
        depth = (crossSectionSqFt / 2).clamp(0.5, 2.0);
        width = depth * 4;
        break;
      case 'channel':
        // Deeper, narrower
        depth = (crossSectionSqFt / 1.5).clamp(0.75, 2.0);
        width = depth * 2;
        break;
      default:
        depth = 1;
        width = 4;
    }

    // Excavation volume (trapezoidal cross-section)
    final avgWidth = width * 0.75; // Account for sloped sides
    final excavationCuFt = length * avgWidth * depth;
    final excavationCuYd = excavationCuFt / 27;

    // Capacity in gallons (100-year storm = 1" rain)
    final capacity = drainageArea * 0.623; // gallons per sq ft at 1"

    setState(() {
      _width = width;
      _depth = depth;
      _excavationCuYd = excavationCuYd;
      _capacity = capacity;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _drainageAreaController.text = '5000'; setState(() { _swaleType = 'grass'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Swale Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SWALE TYPE', ['grass', 'rock', 'channel'], _swaleType, {'grass': 'Grass Swale', 'rock': 'Rock/Riprap', 'channel': 'Channel'}, (v) { setState(() => _swaleType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Swale Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Drainage Area', unit: 'sq ft', controller: _drainageAreaController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_width != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('RECOMMENDED DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Top width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_width!.toStringAsFixed(1)}'", style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_depth!.toStringAsFixed(1)}'", style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Excavation', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_excavationCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Runoff capacity (1")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_capacity!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSwaleGuide(colors),
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

  Widget _buildSwaleGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SWALE DESIGN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Minimum slope', '1-2%'),
        _buildTableRow(colors, 'Maximum slope', '5% (grass), 10% (rock)'),
        _buildTableRow(colors, 'Grass side slopes', '6:1 or flatter'),
        _buildTableRow(colors, 'Rock side slopes', '3:1'),
        _buildTableRow(colors, 'Outlet', 'To storm drain or rain garden'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
