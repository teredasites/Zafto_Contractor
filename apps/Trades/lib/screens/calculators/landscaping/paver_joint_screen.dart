import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Paver Joint Sand Calculator - Polymeric or regular sand
class PaverJointScreen extends ConsumerStatefulWidget {
  const PaverJointScreen({super.key});
  @override
  ConsumerState<PaverJointScreen> createState() => _PaverJointScreenState();
}

class _PaverJointScreenState extends ConsumerState<PaverJointScreen> {
  final _areaController = TextEditingController(text: '200');

  String _paverType = 'standard';
  String _sandType = 'polymeric';

  double? _sandLbs;
  double? _bags50Lb;
  double? _jointWidth;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 200;

    // Joint width and depth vary by paver type
    double jointWidthIn;
    double jointDepthIn;
    switch (_paverType) {
      case 'standard':
        jointWidthIn = 0.125; // 1/8"
        jointDepthIn = 2.375; // Standard paver thickness
        break;
      case 'tumbled':
        jointWidthIn = 0.25; // 1/4" wider joints
        jointDepthIn = 2.375;
        break;
      case 'permeable':
        jointWidthIn = 0.5; // 1/2" for permeability
        jointDepthIn = 3.0;
        break;
      default:
        jointWidthIn = 0.125;
        jointDepthIn = 2.375;
    }

    // Calculate sand needed
    // Approximately 1 lb per sq ft per 1/16" joint width
    final baseRate = 16.0; // lbs per sq ft at 1/8" joints
    final widthFactor = jointWidthIn / 0.125;
    final depthFactor = jointDepthIn / 2.375;

    double lbsPerSqFt = baseRate * widthFactor * depthFactor;

    // Polymeric uses slightly less due to density
    if (_sandType == 'polymeric') {
      lbsPerSqFt *= 0.9;
    }

    final totalLbs = area * lbsPerSqFt / 10; // Simplified calculation
    final bags = totalLbs / 50;

    setState(() {
      _sandLbs = totalLbs;
      _bags50Lb = bags;
      _jointWidth = jointWidthIn;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '200'; setState(() { _paverType = 'standard'; _sandType = 'polymeric'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paver Joint Sand', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PAVER TYPE', ['standard', 'tumbled', 'permeable'], _paverType, {'standard': 'Standard', 'tumbled': 'Tumbled', 'permeable': 'Permeable'}, (v) { setState(() => _paverType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'SAND TYPE', ['polymeric', 'regular'], _sandType, {'polymeric': 'Polymeric', 'regular': 'Regular'}, (v) { setState(() => _sandType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Paver Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sandLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('JOINT SAND', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('50 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags50Lb!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joint width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_jointWidth! * 8).toStringAsFixed(0)}/8\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildJointGuide(colors),
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

  Widget _buildJointGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JOINT SAND TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Polymeric', 'Hardens, resists weeds'),
        _buildTableRow(colors, 'Regular', 'Requires re-sanding'),
        _buildTableRow(colors, 'Application', 'Sweep, compact, mist'),
        _buildTableRow(colors, 'Dry time', '24-48 hrs before rain'),
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
