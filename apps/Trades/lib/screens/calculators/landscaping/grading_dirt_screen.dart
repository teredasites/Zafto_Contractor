import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grading Dirt Calculator - Fill/cut volume
class GradingDirtScreen extends ConsumerStatefulWidget {
  const GradingDirtScreen({super.key});
  @override
  ConsumerState<GradingDirtScreen> createState() => _GradingDirtScreenState();
}

class _GradingDirtScreenState extends ConsumerState<GradingDirtScreen> {
  final _areaController = TextEditingController(text: '1000');
  final _avgDepthController = TextEditingController(text: '6');

  String _operation = 'fill';

  double? _volumeCuYd;
  int? _truckLoads;
  double? _costEstimate;

  @override
  void dispose() { _areaController.dispose(); _avgDepthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 1000;
    final avgDepthIn = double.tryParse(_avgDepthController.text) ?? 6;

    final avgDepthFt = avgDepthIn / 12;
    final volumeCuFt = area * avgDepthFt;
    final volumeCuYd = volumeCuFt / 27;

    // Truck loads (10 cu yd typical dump truck)
    final trucks = (volumeCuYd / 10).ceil();

    // Cost estimate: fill ~$15-25/cu yd, removal ~$25-40/cu yd
    double costPerYd;
    if (_operation == 'fill') {
      costPerYd = 20;
    } else {
      costPerYd = 35;
    }
    final cost = volumeCuYd * costPerYd;

    setState(() {
      _volumeCuYd = volumeCuYd;
      _truckLoads = trucks;
      _costEstimate = cost;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '1000'; _avgDepthController.text = '6'; setState(() { _operation = 'fill'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grading Dirt', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'OPERATION', ['fill', 'cut'], _operation, {'fill': 'Fill (Import)', 'cut': 'Cut (Export)'}, (v) { setState(() => _operation = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Grading Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'in', controller: _avgDepthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_volumeCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_operation == 'fill' ? 'FILL NEEDED' : 'CUT VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Truck loads (10 yd)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_truckLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. material cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_costEstimate!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGradingGuide(colors),
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

  Widget _buildGradingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GRADING NOTES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Compacted swell', '+10-15%'),
        _buildTableRow(colors, 'Loose swell', '+25-30%'),
        _buildTableRow(colors, 'Min slope away', '2% grade'),
        _buildTableRow(colors, 'Topsoil depth', '4-6\" for lawn'),
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
