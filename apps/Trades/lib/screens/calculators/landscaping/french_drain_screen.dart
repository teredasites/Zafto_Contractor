import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// French Drain Calculator - Material quantities
class FrenchDrainScreen extends ConsumerStatefulWidget {
  const FrenchDrainScreen({super.key});
  @override
  ConsumerState<FrenchDrainScreen> createState() => _FrenchDrainScreenState();
}

class _FrenchDrainScreenState extends ConsumerState<FrenchDrainScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '12');
  final _depthController = TextEditingController(text: '18');

  String _pipeSize = '4';

  double? _gravelTons;
  double? _fabricSqFt;
  double? _pipeFeet;
  double? _excavationCuYd;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final widthInches = double.tryParse(_widthController.text) ?? 12;
    final depthInches = double.tryParse(_depthController.text) ?? 18;

    final widthFt = widthInches / 12;
    final depthFt = depthInches / 12;

    // Excavation volume
    final excavationCuFt = length * widthFt * depthFt;
    final excavationCuYd = excavationCuFt / 27;

    // Gravel: fills trench minus pipe volume
    final pipeRadius = (double.tryParse(_pipeSize) ?? 4) / 2 / 12;
    final pipeVolume = 3.14159 * pipeRadius * pipeRadius * length;
    final gravelCuFt = excavationCuFt - pipeVolume;
    final gravelTons = (gravelCuFt / 27) * 1.35;

    // Fabric: wraps trench (2 sides + bottom + overlap)
    final fabricPerimeter = widthFt + (depthFt * 2) + 1; // +1 for overlap
    final fabricSqFt = fabricPerimeter * length;

    setState(() {
      _gravelTons = gravelTons;
      _fabricSqFt = fabricSqFt;
      _pipeFeet = length;
      _excavationCuYd = excavationCuYd;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '12'; _depthController.text = '18'; setState(() { _pipeSize = '4'; }); _calculate(); }

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
            _buildSelector(colors, 'PIPE SIZE', ['3', '4', '6'], _pipeSize, {'3': '3"', '4': '4"', '6': '6"'}, (v) { setState(() => _pipeSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Drain Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trench Width', unit: 'in', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Trench Depth', unit: 'in', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gravelTons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAVEL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Perforated pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_pipeFeet!.toStringAsFixed(0)}' of $_pipeSize\"", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landscape fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Excavation', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_excavationCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
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

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Slope', '1% min (1"/8\')'),
        _buildTableRow(colors, 'Gravel', '3/4" washed stone'),
        _buildTableRow(colors, 'Pipe position', '2" gravel below'),
        _buildTableRow(colors, 'Holes', 'Face down'),
        _buildTableRow(colors, 'Fabric overlap', '4-6" at top'),
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
