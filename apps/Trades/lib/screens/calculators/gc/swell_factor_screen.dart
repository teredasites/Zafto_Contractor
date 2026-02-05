import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Swell Factor Calculator - Bank to loose volume conversion
class SwellFactorScreen extends ConsumerStatefulWidget {
  const SwellFactorScreen({super.key});
  @override
  ConsumerState<SwellFactorScreen> createState() => _SwellFactorScreenState();
}

class _SwellFactorScreenState extends ConsumerState<SwellFactorScreen> {
  final _bankVolumeController = TextEditingController(text: '100');

  String _soilType = 'average';

  double? _swellFactor;
  double? _looseVolume;
  double? _volumeIncrease;

  @override
  void dispose() { _bankVolumeController.dispose(); super.dispose(); }

  void _calculate() {
    final bankVolume = double.tryParse(_bankVolumeController.text);

    if (bankVolume == null) {
      setState(() { _swellFactor = null; _looseVolume = null; _volumeIncrease = null; });
      return;
    }

    // Swell factors by soil type
    double swellFactor;
    switch (_soilType) {
      case 'sand': swellFactor = 1.10; break;
      case 'loam': swellFactor = 1.20; break;
      case 'average': swellFactor = 1.25; break;
      case 'clay': swellFactor = 1.35; break;
      case 'shale': swellFactor = 1.45; break;
      case 'rock': swellFactor = 1.50; break;
      default: swellFactor = 1.25;
    }

    final looseVolume = bankVolume * swellFactor;
    final volumeIncrease = looseVolume - bankVolume;

    setState(() { _swellFactor = swellFactor; _looseVolume = looseVolume; _volumeIncrease = volumeIncrease; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _bankVolumeController.text = '100'; setState(() => _soilType = 'average'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Swell Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SOIL TYPE', ['sand', 'loam', 'average'], _soilType, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['clay', 'shale', 'rock'], _soilType, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Bank Volume (in-ground)', unit: 'yd³', controller: _bankVolumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_looseVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOOSE VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_looseVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Swell Factor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${((_swellFactor! - 1) * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume Increase', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeIncrease!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSoilNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSwellTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSwellTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SWELL FACTOR REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Sand/Gravel', '10-15%'),
        _buildTableRow(colors, 'Loam', '15-20%'),
        _buildTableRow(colors, 'Common Earth', '20-30%'),
        _buildTableRow(colors, 'Clay', '30-40%'),
        _buildTableRow(colors, 'Shale', '40-50%'),
        _buildTableRow(colors, 'Rock', '50-70%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String material, String factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(material, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(factor, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _getSoilNote() {
    switch (_soilType) {
      case 'sand': return 'Sand/gravel: Minimal swell. Easy to handle and load.';
      case 'loam': return 'Loam: Garden soil mix. Moderate swell, good drainage.';
      case 'average': return 'Average earth: Typical excavation material. Plan for 25% swell.';
      case 'clay': return 'Clay: Heavy, sticky. High swell factor, difficult to handle wet.';
      case 'shale': return 'Shale: Layered rock. Breaks into irregular pieces when excavated.';
      case 'rock': return 'Rock: Maximum swell. May require specialized equipment.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'sand': 'Sand', 'loam': 'Loam', 'average': 'Average', 'clay': 'Clay', 'shale': 'Shale', 'rock': 'Rock'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
