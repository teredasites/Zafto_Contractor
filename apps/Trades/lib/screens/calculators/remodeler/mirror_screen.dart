import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mirror Calculator - Mirror sizing and weight estimation
class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});
  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '48');

  String _thickness = 'quarter';
  String _type = 'frameless';

  double? _sqft;
  double? _weight;
  String? _hangingMethod;
  int? _clips;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 48;

    final widthFt = width / 12;
    final heightFt = height / 12;
    final sqft = widthFt * heightFt;

    // Weight: 1/4" mirror ~3.3 lbs/sqft, 3/8" ~5 lbs/sqft
    double lbsPerSqft;
    switch (_thickness) {
      case 'eighth':
        lbsPerSqft = 1.6;
        break;
      case 'quarter':
        lbsPerSqft = 3.3;
        break;
      case 'threeeighth':
        lbsPerSqft = 5.0;
        break;
      default:
        lbsPerSqft = 3.3;
    }

    final weight = sqft * lbsPerSqft;

    // Hanging method based on weight and type
    String hangingMethod;
    int clips;

    if (weight < 20) {
      hangingMethod = 'J-channel or clips';
      clips = 4;
    } else if (weight < 50) {
      hangingMethod = 'Mirror clips + adhesive';
      clips = 6;
    } else {
      hangingMethod = 'Heavy-duty clips + Z-clips';
      clips = 8;
    }

    setState(() { _sqft = sqft; _weight = weight; _hangingMethod = hangingMethod; _clips = clips; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _heightController.text = '48'; setState(() { _thickness = 'quarter'; _type = 'frameless'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mirror', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'THICKNESS', ['eighth', 'quarter', 'threeeighth'], _thickness, {'eighth': '1/8\"', 'quarter': '1/4\"', 'threeeighth': '3/8\"'}, (v) { setState(() => _thickness = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TYPE', ['frameless', 'framed', 'beveled'], _type, {'frameless': 'Frameless', 'framed': 'Framed', 'beveled': 'Beveled'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ESTIMATED WEIGHT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weight!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hanging Method', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_hangingMethod!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Clips/Brackets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_clips min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Large mirrors: mount into studs or use toggle bolts. Use mirror mastic + clips for security.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWeightTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWeightTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MIRROR WEIGHT BY THICKNESS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1/8\" mirror', '~1.6 lbs/sq ft'),
        _buildTableRow(colors, '1/4\" mirror', '~3.3 lbs/sq ft'),
        _buildTableRow(colors, '3/8\" mirror', '~5.0 lbs/sq ft'),
        _buildTableRow(colors, 'Vanity (3\'x4\')', '~40 lbs'),
        _buildTableRow(colors, 'Full length (2\'x6\')', '~40 lbs'),
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
