import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dry Creek Bed Calculator - Rock and liner
class DryCreekScreen extends ConsumerStatefulWidget {
  const DryCreekScreen({super.key});
  @override
  ConsumerState<DryCreekScreen> createState() => _DryCreekScreenState();
}

class _DryCreekScreenState extends ConsumerState<DryCreekScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '3');

  String _rockSize = 'mixed';
  String _depthIn = '4';

  double? _rockTons;
  double? _fabricSqFt;
  int? _boulders;
  double? _borderRockTons;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 3;
    final depth = double.tryParse(_depthIn) ?? 4;

    final area = length * width;
    final depthFt = depth / 12;
    final volumeCuFt = area * depthFt;
    final volumeCuYd = volumeCuFt / 27;

    // River rock weight: ~1.35 tons per cubic yard
    final rockTons = volumeCuYd * 1.35;

    // Landscape fabric: bed area + 6" overlap on sides
    final fabricSqFt = length * (width + 1);

    // Boulders: decorative, 1 per 5-10 linear feet
    final boulders = (length / 7).ceil();

    // Border rock: larger stones along edges
    final borderLength = length * 2;
    final borderVolume = borderLength * 0.5 * (4 / 12); // 6" wide, 4" deep
    final borderTons = (borderVolume / 27) * 1.4;

    setState(() {
      _rockTons = rockTons;
      _fabricSqFt = fabricSqFt;
      _boulders = boulders;
      _borderRockTons = borderTons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '3'; setState(() { _rockSize = 'mixed'; _depthIn = '4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dry Creek Bed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROCK SIZE', ['small', 'mixed', 'large'], _rockSize, {'small': '1-2\"', 'mixed': 'Mixed', 'large': '3-5\"'}, (v) { setState(() => _rockSize = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'DEPTH', ['3', '4', '6'], _depthIn, {'3': '3\"', '4': '4\"', '6': '6\"'}, (v) { setState(() => _depthIn = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rockTons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RIVER ROCK', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rockTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Border stone', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_borderRockTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Accent boulders', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_boulders', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landscape fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCreekGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCreekGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DESIGN TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Natural look', 'Curve, vary width'),
        _buildTableRow(colors, 'Rock mix', '3 sizes minimum'),
        _buildTableRow(colors, 'Drainage', 'Grade toward outlet'),
        _buildTableRow(colors, 'Plants', 'Native grasses at edges'),
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
