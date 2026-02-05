import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheelchair Ramp Calculator - ADA compliant ramp dimensions
class WheelchairRampScreen extends ConsumerStatefulWidget {
  const WheelchairRampScreen({super.key});
  @override
  ConsumerState<WheelchairRampScreen> createState() => _WheelchairRampScreenState();
}

class _WheelchairRampScreenState extends ConsumerState<WheelchairRampScreen> {
  final _riseController = TextEditingController(text: '24');
  final _widthController = TextEditingController(text: '36');

  String _slope = '1:12';
  String _material = 'wood';

  double? _rampLength;
  double? _landingLength;
  double? _totalLength;
  int? _landingCount;
  double? _sqft;

  @override
  void dispose() { _riseController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final rise = double.tryParse(_riseController.text) ?? 24; // inches
    final width = double.tryParse(_widthController.text) ?? 36; // inches

    // Slope ratio (run per 1" of rise)
    double slopeRatio;
    switch (_slope) {
      case '1:8':
        slopeRatio = 8; // Steeper, for very limited space
        break;
      case '1:10':
        slopeRatio = 10; // Moderate
        break;
      case '1:12':
        slopeRatio = 12; // ADA standard
        break;
      case '1:16':
        slopeRatio = 16; // Easier, longer
        break;
      default:
        slopeRatio = 12;
    }

    // Calculate run (inches)
    final runInches = rise * slopeRatio;
    final rampLength = runInches / 12; // Convert to feet

    // Landings required every 30" of rise (ADA)
    final landingCount = (rise / 30).ceil();
    final landingLength = landingCount * 5; // 5' landing minimum

    // Total length
    final totalLength = rampLength + landingLength;

    // Square footage
    final widthFeet = width / 12;
    final sqft = totalLength * widthFeet;

    setState(() {
      _rampLength = rampLength;
      _landingLength = landingLength.toDouble();
      _totalLength = totalLength;
      _landingCount = landingCount;
      _sqft = sqft;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '24'; _widthController.text = '36'; setState(() { _slope = '1:12'; _material = 'wood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wheelchair Ramp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SLOPE', ['1:8', '1:10', '1:12', '1:16'], _slope, {'1:8': '1:8', '1:10': '1:10', '1:12': '1:12 (ADA)', '1:16': '1:16'}, (v) { setState(() => _slope = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['wood', 'aluminum', 'concrete'], _material, {'wood': 'Wood', 'aluminum': 'Aluminum', 'concrete': 'Concrete'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Ramp Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rampLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ramp Run', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rampLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landings', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_landingCount x 5 ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('ADA: 1:12 slope max, 36" min width, landings every 30" rise and at turns. Handrails required.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildADATable(colors),
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

  Widget _buildADATable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADA RAMP REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Max slope', '1:12 (8.33%)'),
        _buildTableRow(colors, 'Min width', '36"'),
        _buildTableRow(colors, 'Max rise/run', '30"'),
        _buildTableRow(colors, 'Landing size', '5\' x 5\' min'),
        _buildTableRow(colors, 'Edge protection', '2" curb or rail'),
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
