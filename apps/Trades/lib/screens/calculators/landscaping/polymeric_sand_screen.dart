import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Polymeric Sand Calculator - Joint filling for pavers
class PolymericSandScreen extends ConsumerStatefulWidget {
  const PolymericSandScreen({super.key});
  @override
  ConsumerState<PolymericSandScreen> createState() => _PolymericSandScreenState();
}

class _PolymericSandScreenState extends ConsumerState<PolymericSandScreen> {
  final _areaController = TextEditingController(text: '300');

  String _jointWidth = 'narrow';
  String _jointDepth = 'standard';

  double? _bagsNeeded;
  int? _bags50lb;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 300;

    // Coverage varies by joint width and depth
    // Standard coverage: 30-50 sq ft per 50 lb bag
    double sqFtPerBag;
    switch (_jointWidth) {
      case 'narrow': // 1/8" - 1/4"
        sqFtPerBag = 50;
        break;
      case 'medium': // 1/4" - 3/8"
        sqFtPerBag = 35;
        break;
      case 'wide': // 3/8" - 1/2"+
        sqFtPerBag = 25;
        break;
      default:
        sqFtPerBag = 35;
    }

    // Adjust for depth
    double depthFactor;
    switch (_jointDepth) {
      case 'shallow': depthFactor = 0.75; break; // 1"
      case 'standard': depthFactor = 1.0; break; // 1.5"
      case 'deep': depthFactor = 1.5; break; // 2"+
      default: depthFactor = 1.0;
    }

    final adjustedCoverage = sqFtPerBag / depthFactor;
    final bagsNeeded = area / adjustedCoverage;
    final bags50lb = bagsNeeded.ceil();

    setState(() {
      _bagsNeeded = bagsNeeded;
      _bags50lb = bags50lb;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '300'; setState(() { _jointWidth = 'narrow'; _jointDepth = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Polymeric Sand', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'JOINT WIDTH', ['narrow', 'medium', 'wide'], _jointWidth, {'narrow': '1/8-1/4"', 'medium': '1/4-3/8"', 'wide': '3/8-1/2"+'}, (v) { setState(() => _jointWidth = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'JOINT DEPTH', ['shallow', 'standard', 'deep'], _jointDepth, {'shallow': '1" (thin)', 'standard': '1.5" (typical)', 'deep': '2"+ (thick)'}, (v) { setState(() => _jointDepth = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Paver Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bagsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BAGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags50lb', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Text('50 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Precise amount', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bagsNeeded!.toStringAsFixed(1)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildApplicationGuide(colors),
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

  Widget _buildApplicationGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1. Prep', 'Pavers must be dry'),
        _buildTableRow(colors, '2. Pour', 'Spread across surface'),
        _buildTableRow(colors, '3. Sweep', 'Into joints, compact'),
        _buildTableRow(colors, '4. Blow off', 'Remove excess from tops'),
        _buildTableRow(colors, '5. Mist', 'Light water to activate'),
        _buildTableRow(colors, '6. Cure', '24 hours before rain'),
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
