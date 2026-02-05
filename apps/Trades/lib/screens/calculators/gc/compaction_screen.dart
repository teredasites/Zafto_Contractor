import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compaction Calculator - Soil/aggregate compaction requirements
class CompactionScreen extends ConsumerStatefulWidget {
  const CompactionScreen({super.key});
  @override
  ConsumerState<CompactionScreen> createState() => _CompactionScreenState();
}

class _CompactionScreenState extends ConsumerState<CompactionScreen> {
  final _volumeController = TextEditingController(text: '100');
  final _targetDensityController = TextEditingController(text: '95');

  String _soilType = 'granular';

  double? _looseVolume;
  double? _compactedVolume;
  int? _liftCount;
  int? _passesPerLift;

  @override
  void dispose() { _volumeController.dispose(); _targetDensityController.dispose(); super.dispose(); }

  void _calculate() {
    final compactedVolume = double.tryParse(_volumeController.text);
    final targetDensity = double.tryParse(_targetDensityController.text);

    if (compactedVolume == null || targetDensity == null) {
      setState(() { _looseVolume = null; _compactedVolume = null; _liftCount = null; _passesPerLift = null; });
      return;
    }

    // Swell factor by soil type (how much more loose volume vs compacted)
    double swellFactor;
    int maxLiftInches;
    int passesRequired;

    switch (_soilType) {
      case 'granular': // Sand, gravel
        swellFactor = 1.15;
        maxLiftInches = 12;
        passesRequired = 3;
        break;
      case 'cohesive': // Clay, silt
        swellFactor = 1.30;
        maxLiftInches = 6;
        passesRequired = 5;
        break;
      case 'rock': // Crushed rock
        swellFactor = 1.40;
        maxLiftInches = 8;
        passesRequired = 4;
        break;
      case 'topsoil': // Organic topsoil
        swellFactor = 1.25;
        maxLiftInches = 4;
        passesRequired = 6;
        break;
      default:
        swellFactor = 1.20;
        maxLiftInches = 8;
        passesRequired = 4;
    }

    // Loose volume needed
    final looseVolume = compactedVolume * swellFactor;

    // Assume 2' total depth, calculate lifts
    final totalDepthInches = 24;
    final liftCount = (totalDepthInches / maxLiftInches).ceil();

    // Adjust passes based on target density
    final densityFactor = targetDensity / 95; // 95% is baseline
    final passesPerLift = (passesRequired * densityFactor).ceil();

    setState(() {
      _looseVolume = looseVolume;
      _compactedVolume = compactedVolume;
      _liftCount = liftCount;
      _passesPerLift = passesPerLift;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _volumeController.text = '100'; _targetDensityController.text = '95'; setState(() => _soilType = 'granular'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compaction', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SOIL TYPE', ['granular', 'cohesive', 'rock', 'topsoil'], _soilType, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Compacted Volume', unit: 'yd³', controller: _volumeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target Density', unit: '%', controller: _targetDensityController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_looseVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOOSE VOLUME NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_looseVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Final Compacted Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_compactedVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Lifts Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_liftCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Passes per Lift', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_passesPerLift', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSoilNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getSoilNote() {
    switch (_soilType) {
      case 'granular': return 'Granular soils: Vibratory compactor preferred. Moisture near optimum.';
      case 'cohesive': return 'Cohesive soils: Sheepsfoot or padfoot roller. Control moisture carefully.';
      case 'rock': return 'Crushed rock: Heavy vibratory roller. Water for dust control.';
      case 'topsoil': return 'Topsoil: Light compaction only. Not suitable for structural support.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'granular': 'Granular', 'cohesive': 'Cohesive', 'rock': 'Rock', 'topsoil': 'Topsoil'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
