import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landscape Lighting Calculator - Watts, transformer, wire
class LandscapeLightingScreen extends ConsumerStatefulWidget {
  const LandscapeLightingScreen({super.key});
  @override
  ConsumerState<LandscapeLightingScreen> createState() => _LandscapeLightingScreenState();
}

class _LandscapeLightingScreenState extends ConsumerState<LandscapeLightingScreen> {
  final _pathLightsController = TextEditingController(text: '10');
  final _spotLightsController = TextEditingController(text: '4');
  final _wellLightsController = TextEditingController(text: '2');
  final _runLengthController = TextEditingController(text: '100');

  String _bulbType = 'led';

  double? _totalWatts;
  int? _transformerSize;
  String? _wireGauge;
  double? _amps;

  @override
  void dispose() { _pathLightsController.dispose(); _spotLightsController.dispose(); _wellLightsController.dispose(); _runLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final pathLights = int.tryParse(_pathLightsController.text) ?? 10;
    final spotLights = int.tryParse(_spotLightsController.text) ?? 4;
    final wellLights = int.tryParse(_wellLightsController.text) ?? 2;
    final runLength = double.tryParse(_runLengthController.text) ?? 100;

    // Watts per fixture by type
    double pathWatts, spotWatts, wellWatts;
    if (_bulbType == 'led') {
      pathWatts = 3;
      spotWatts = 5;
      wellWatts = 7;
    } else {
      pathWatts = 11;
      spotWatts = 20;
      wellWatts = 35;
    }

    final totalWatts = (pathLights * pathWatts) + (spotLights * spotWatts) + (wellLights * wellWatts);

    // Transformer sizing (80% max load rule)
    int transformerSize;
    if (totalWatts <= 120) transformerSize = 150;
    else if (totalWatts <= 240) transformerSize = 300;
    else if (totalWatts <= 480) transformerSize = 600;
    else transformerSize = 900;

    // Wire gauge based on wattage and run length
    final voltAmperes = totalWatts;
    String wireGauge;
    if (runLength <= 50 && voltAmperes <= 150) wireGauge = '16 AWG';
    else if (runLength <= 100 && voltAmperes <= 200) wireGauge = '14 AWG';
    else if (runLength <= 150 && voltAmperes <= 300) wireGauge = '12 AWG';
    else wireGauge = '10 AWG';

    // Amps at 12V
    final amps = totalWatts / 12;

    setState(() {
      _totalWatts = totalWatts;
      _transformerSize = transformerSize;
      _wireGauge = wireGauge;
      _amps = amps;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _pathLightsController.text = '10'; _spotLightsController.text = '4'; _wellLightsController.text = '2'; _runLengthController.text = '100'; setState(() { _bulbType = 'led'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landscape Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BULB TYPE', ['led', 'halogen'], _bulbType, {'led': 'LED', 'halogen': 'Halogen'}, (v) { setState(() => _bulbType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Path Lights', unit: '', controller: _pathLightsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Spot Lights', unit: '', controller: _spotLightsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Well Lights', unit: '', controller: _wellLightsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wire Run', unit: 'ft', controller: _runLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalWatts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LOAD', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalWatts!.toStringAsFixed(0)} W', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Transformer size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_transformerSize}W', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wire gauge', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_wireGauge', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Current draw', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_amps!.toStringAsFixed(1)} A', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLightingGuide(colors),
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

  Widget _buildLightingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DESIGN TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Path spacing', "8-10' apart"),
        _buildTableRow(colors, 'Uplights', '1 per major tree'),
        _buildTableRow(colors, 'Max load', '80% of transformer'),
        _buildTableRow(colors, 'Voltage drop', 'Keep runs under 150\''),
        _buildTableRow(colors, 'Hub method', 'Reduces voltage drop'),
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
