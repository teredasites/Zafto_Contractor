import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pop-up Drain Calculator - Downspout drainage
class PopUpDrainScreen extends ConsumerStatefulWidget {
  const PopUpDrainScreen({super.key});
  @override
  ConsumerState<PopUpDrainScreen> createState() => _PopUpDrainScreenState();
}

class _PopUpDrainScreenState extends ConsumerState<PopUpDrainScreen> {
  final _roofAreaController = TextEditingController(text: '500');
  final _runLengthController = TextEditingController(text: '30');

  String _pipeSize = '4';

  double? _flowGpm;
  double? _minSlope;
  bool? _adequateSize;
  double? _pipeCapacity;

  @override
  void dispose() { _roofAreaController.dispose(); _runLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 500;
    final runLength = double.tryParse(_runLengthController.text) ?? 30;
    final pipeIn = double.tryParse(_pipeSize) ?? 4;

    // Peak flow from roof: assume 4 in/hr rain
    // 1 sq ft roof × 4 in/hr = 0.623 × 4 = 2.49 gal/hr = 0.04 GPM
    final flowGpm = roofArea * 0.04;

    // Pipe capacity at 1/8" per ft slope
    double capacity;
    switch (pipeIn.toInt()) {
      case 3:
        capacity = 20; // GPM
        break;
      case 4:
        capacity = 40;
        break;
      case 6:
        capacity = 100;
        break;
      default:
        capacity = 40;
    }

    final adequate = flowGpm <= capacity;

    // Minimum slope: 1/8" per foot standard
    final minSlope = 0.125;

    setState(() {
      _flowGpm = flowGpm;
      _minSlope = minSlope;
      _adequateSize = adequate;
      _pipeCapacity = capacity;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '500'; _runLengthController.text = '30'; setState(() { _pipeSize = '4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pop-up Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PIPE SIZE', ['3', '4', '6'], _pipeSize, {'3': '3\"', '4': '4\"', '6': '6\"'}, (v) { setState(() => _pipeSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Area (this downspout)', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Run Length', unit: 'ft', controller: _runLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_flowGpm != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PEAK FLOW', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_flowGpm!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pipe capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pipeCapacity!.toStringAsFixed(0)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size adequate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_adequateSize! ? 'Yes' : 'No - upsize', style: TextStyle(color: _adequateSize! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min slope', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1/8\" per ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDrainGuide(colors),
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

  Widget _buildDrainGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min distance', "6' from foundation"),
        _buildTableRow(colors, 'Trench depth', '6-12\"'),
        _buildTableRow(colors, 'Use solid pipe', 'First 10\' from house'),
        _buildTableRow(colors, 'Filter grate', 'At downspout adapter'),
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
