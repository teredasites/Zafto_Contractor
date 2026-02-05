import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Excavation Volume Calculator - Earthwork quantities
class ExcavationVolumeScreen extends ConsumerStatefulWidget {
  const ExcavationVolumeScreen({super.key});
  @override
  ConsumerState<ExcavationVolumeScreen> createState() => _ExcavationVolumeScreenState();
}

class _ExcavationVolumeScreenState extends ConsumerState<ExcavationVolumeScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');
  final _depthController = TextEditingController(text: '4');

  String _excavationType = 'rectangular';
  String _soilType = 'average';

  double? _bankVolume;
  double? _looseVolume;
  int? _truckLoads;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || width == null || depth == null) {
      setState(() { _bankVolume = null; _looseVolume = null; _truckLoads = null; });
      return;
    }

    // Bank volume (in-ground)
    double bankVolume;
    switch (_excavationType) {
      case 'rectangular':
        bankVolume = (length * width * depth) / 27; // Convert to cubic yards
        break;
      case 'trapezoidal':
        // Assume 1:1 slope on all sides
        final bottomLength = length - (depth * 2);
        final bottomWidth = width - (depth * 2);
        final avgLength = (length + bottomLength) / 2;
        final avgWidth = (width + bottomWidth) / 2;
        bankVolume = (avgLength * avgWidth * depth) / 27;
        break;
      case 'sloped':
        // Add 20% for slopes
        bankVolume = (length * width * depth * 1.2) / 27;
        break;
      default:
        bankVolume = (length * width * depth) / 27;
    }

    // Swell factor based on soil type
    double swellFactor;
    switch (_soilType) {
      case 'sand': swellFactor = 1.10; break;
      case 'average': swellFactor = 1.25; break;
      case 'clay': swellFactor = 1.35; break;
      case 'rock': swellFactor = 1.50; break;
      default: swellFactor = 1.25;
    }

    final looseVolume = bankVolume * swellFactor;

    // Truck loads (assume 10 CY per truck)
    final truckLoads = (looseVolume / 10).ceil();

    setState(() { _bankVolume = bankVolume; _looseVolume = looseVolume; _truckLoads = truckLoads; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; _depthController.text = '4'; setState(() { _excavationType = 'rectangular'; _soilType = 'average'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Excavation Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EXCAVATION TYPE', ['rectangular', 'trapezoidal', 'sloped'], _excavationType, (v) { setState(() => _excavationType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SOIL TYPE', ['sand', 'average', 'clay', 'rock'], _soilType, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'ft', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bankVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOOSE VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_looseVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bank Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bankVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Truck Loads (10 yd)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_truckLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
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
      case 'sand': return 'Sandy soil: Swell factor 10%. May require shoring in deep excavations.';
      case 'average': return 'Average soil: Swell factor 25%. Typical for most residential/commercial work.';
      case 'clay': return 'Clay soil: Swell factor 35%. Heavy, sticky when wet. Harder to compact.';
      case 'rock': return 'Rock: Swell factor 50%. May require blasting or hoe-ram for removal.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'rectangular': 'Rectangular', 'trapezoidal': 'Trapezoidal', 'sloped': 'Sloped', 'sand': 'Sand', 'average': 'Average', 'clay': 'Clay', 'rock': 'Rock'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
