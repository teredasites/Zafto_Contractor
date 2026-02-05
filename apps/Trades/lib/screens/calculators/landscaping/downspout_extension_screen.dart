import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Downspout Extension Calculator - Underground drainage
class DownspoutExtensionScreen extends ConsumerStatefulWidget {
  const DownspoutExtensionScreen({super.key});
  @override
  ConsumerState<DownspoutExtensionScreen> createState() => _DownspoutExtensionScreenState();
}

class _DownspoutExtensionScreenState extends ConsumerState<DownspoutExtensionScreen> {
  final _downspoutsController = TextEditingController(text: '4');
  final _runLengthController = TextEditingController(text: '30');

  String _pipeSize = '4';

  int? _totalPipe;
  int? _elbows;
  int? _adapters;
  int? _popUps;

  @override
  void dispose() { _downspoutsController.dispose(); _runLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final downspouts = int.tryParse(_downspoutsController.text) ?? 4;
    final runLength = double.tryParse(_runLengthController.text) ?? 30;

    // Total pipe (add 5' per downspout for vertical run)
    final totalPipe = ((runLength + 5) * downspouts).ceil();

    // Elbows: 2 per downspout (one at base, one turn to horizontal)
    final elbows = downspouts * 2;

    // Adapters: 1 per downspout (3x4 reducer)
    final adapters = downspouts;

    // Pop-up emitters: 1 per run
    final popUps = downspouts;

    setState(() {
      _totalPipe = totalPipe;
      _elbows = elbows;
      _adapters = adapters;
      _popUps = popUps;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _downspoutsController.text = '4'; _runLengthController.text = '30'; setState(() { _pipeSize = '4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Downspout Extension', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PIPE SIZE', ['3', '4', '6'], _pipeSize, {'3': '3"', '4': '4"', '6': '6"'}, (v) { setState(() => _pipeSize = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Downspouts', unit: '', controller: _downspoutsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Run Length', unit: 'ft', controller: _runLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Minimum 10\' from foundation. Maintain 1/8" per foot slope.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_totalPipe != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MATERIALS LIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildResultRow(colors, '$_pipeSize" SDR-35 pipe', "$_totalPipe'"),
                _buildResultRow(colors, '$_pipeSize" elbows', '$_elbows'),
                _buildResultRow(colors, '3×4 to $_pipeSize" adapters', '$_adapters'),
                _buildResultRow(colors, 'Pop-up emitters', '$_popUps'),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text('ALSO NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('• PVC glue & primer\n• Filter cloth for outlets\n• Gravel for pop-up bed', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
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

  Widget _buildTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Slope', '1/8" per foot minimum'),
        _buildTableRow(colors, 'Depth', '6-12" typical'),
        _buildTableRow(colors, 'Pipe type', 'SDR-35 or sewer & drain'),
        _buildTableRow(colors, 'Glue joints', 'All buried connections'),
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
