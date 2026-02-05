import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// French Drain Calculator - Drainage system materials
class FrenchDrainScreen extends ConsumerStatefulWidget {
  const FrenchDrainScreen({super.key});
  @override
  ConsumerState<FrenchDrainScreen> createState() => _FrenchDrainScreenState();
}

class _FrenchDrainScreenState extends ConsumerState<FrenchDrainScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '12');
  final _depthController = TextEditingController(text: '24');

  String _pipeSize = '4';

  double? _trenchVolume;
  double? _gravelVolume;
  int? _pipeLF;
  int? _fabricSF;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final widthInches = double.tryParse(_widthController.text);
    final depthInches = double.tryParse(_depthController.text);

    if (length == null || widthInches == null || depthInches == null) {
      setState(() { _trenchVolume = null; _gravelVolume = null; _pipeLF = null; _fabricSF = null; });
      return;
    }

    final widthFeet = widthInches / 12;
    final depthFeet = depthInches / 12;

    final trenchVolume = (length * widthFeet * depthFeet) / 27;

    final pipeRadius = (int.tryParse(_pipeSize) ?? 4) / 24;
    final pipeVolume = (3.14159 * pipeRadius * pipeRadius * length) / 27;
    final gravelVolume = trenchVolume - pipeVolume;

    final pipeLF = (length * 1.1).ceil();

    final fabricWidth = widthFeet + (depthFeet * 2) + 1;
    final fabricSF = (length * fabricWidth).ceil();

    setState(() { _trenchVolume = trenchVolume; _gravelVolume = gravelVolume; _pipeLF = pipeLF; _fabricSF = fabricSF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '12'; _depthController.text = '24'; setState(() => _pipeSize = '4'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('French Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PIPE DIAMETER', ['3', '4', '6'], _pipeSize, (v) { setState(() => _pipeSize = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Drain Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trench Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Trench Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gravelVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAVEL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trench Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_trenchVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perforated Pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pipeLF LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Filter Fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fabricSF sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use 3/4" clean washed stone. Slope 1% min toward outlet. Holes face DOWN on pipe.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
