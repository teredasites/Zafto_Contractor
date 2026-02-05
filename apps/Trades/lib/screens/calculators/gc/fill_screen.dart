import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fill Calculator - Fill material requirements
class FillScreen extends ConsumerStatefulWidget {
  const FillScreen({super.key});
  @override
  ConsumerState<FillScreen> createState() => _FillScreenState();
}

class _FillScreenState extends ConsumerState<FillScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');
  final _depthController = TextEditingController(text: '12');

  String _fillType = 'structural';

  double? _compactedVolume;
  double? _looseVolumeNeeded;
  double? _tons;
  int? _truckLoads;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depthInches = double.tryParse(_depthController.text);

    if (length == null || width == null || depthInches == null) {
      setState(() { _compactedVolume = null; _looseVolumeNeeded = null; _tons = null; _truckLoads = null; });
      return;
    }

    final depthFeet = depthInches / 12;
    final compactedVolume = (length * width * depthFeet) / 27;

    // Shrinkage factor (loose to compacted)
    double shrinkFactor;
    double tonsPerYard;
    switch (_fillType) {
      case 'structural':
        shrinkFactor = 1.25; // Need 25% more loose
        tonsPerYard = 1.4;   // Crushed stone/gravel
        break;
      case 'common':
        shrinkFactor = 1.20;
        tonsPerYard = 1.3;   // Common fill
        break;
      case 'topsoil':
        shrinkFactor = 1.15;
        tonsPerYard = 1.1;   // Topsoil
        break;
      case 'sand':
        shrinkFactor = 1.10;
        tonsPerYard = 1.35;  // Sand
        break;
      default:
        shrinkFactor = 1.20;
        tonsPerYard = 1.3;
    }

    final looseVolumeNeeded = compactedVolume * shrinkFactor;
    final tons = looseVolumeNeeded * tonsPerYard;

    // Truck loads (assume 15 tons per truck)
    final truckLoads = (tons / 15).ceil();

    setState(() { _compactedVolume = compactedVolume; _looseVolumeNeeded = looseVolumeNeeded; _tons = tons; _truckLoads = truckLoads; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; _depthController.text = '12'; setState(() => _fillType = 'structural'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fill Material', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FILL TYPE', ['structural', 'common', 'topsoil', 'sand'], _fillType, (v) { setState(() => _fillType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compacted Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MATERIAL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Compacted Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_compactedVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Loose Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_looseVolumeNeeded!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Truck Loads (15 ton)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_truckLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getFillNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getFillNote() {
    switch (_fillType) {
      case 'structural': return 'Structural fill: Crushed stone or bank-run gravel. Compact in 6-8" lifts to 95%.';
      case 'common': return 'Common fill: Screened or unscreened soil. Not for beneath structures.';
      case 'topsoil': return 'Topsoil: For final grade landscaping. 4-6" typical depth for lawns.';
      case 'sand': return 'Sand: For bedding, leveling, or backfill around pipes.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'structural': 'Structural', 'common': 'Common', 'topsoil': 'Topsoil', 'sand': 'Sand'};
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
