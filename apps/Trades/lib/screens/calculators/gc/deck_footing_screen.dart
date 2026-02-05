import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Footing Calculator - Concrete footings for deck posts
class DeckFootingScreen extends ConsumerStatefulWidget {
  const DeckFootingScreen({super.key});
  @override
  ConsumerState<DeckFootingScreen> createState() => _DeckFootingScreenState();
}

class _DeckFootingScreenState extends ConsumerState<DeckFootingScreen> {
  final _countController = TextEditingController(text: '6');
  final _depthController = TextEditingController(text: '42');

  String _diameter = '12';
  String _sonotubeHeight = '6';

  double? _volumeEach;
  double? _totalVolume;
  int? _bags80lb;
  int? _sonotubes;

  @override
  void dispose() { _countController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final count = int.tryParse(_countController.text);
    final depthInches = double.tryParse(_depthController.text);
    final diameterInches = int.tryParse(_diameter) ?? 12;
    final sonotubeHeightInches = int.tryParse(_sonotubeHeight) ?? 6;

    if (count == null || depthInches == null) {
      setState(() { _volumeEach = null; _totalVolume = null; _bags80lb = null; _sonotubes = null; });
      return;
    }

    // Footing + sonotube volume
    // Footing: flared base, use 1.5x diameter at bottom
    final footingDiameterInches = diameterInches * 1.5;
    final footingDepthInches = 12.0; // Standard 12" footing depth
    final sonotubeDepthInches = depthInches - footingDepthInches + sonotubeHeightInches;

    // Volume of footing (tapered cylinder approximation)
    final footingRadiusTop = (diameterInches / 2) / 12;
    final footingRadiusBottom = (footingDiameterInches / 2) / 12;
    final footingDepthFeet = footingDepthInches / 12;
    final footingVolume = (math.pi * footingDepthFeet / 3) *
        (footingRadiusTop * footingRadiusTop +
         footingRadiusTop * footingRadiusBottom +
         footingRadiusBottom * footingRadiusBottom);

    // Volume of sonotube (cylinder)
    final tubeRadiusFeet = (diameterInches / 2) / 12;
    final tubeDepthFeet = sonotubeDepthInches / 12;
    final tubeVolume = math.pi * tubeRadiusFeet * tubeRadiusFeet * tubeDepthFeet;

    final volumeEach = footingVolume + tubeVolume;
    final totalVolume = volumeEach * count;

    // 80lb bag = 0.6 cu ft, add 10% waste
    final bags80lb = ((totalVolume / 0.6) * 1.1).ceil();

    // Sonotubes needed
    final sonotubes = count;

    setState(() { _volumeEach = volumeEach; _totalVolume = totalVolume; _bags80lb = bags80lb; _sonotubes = sonotubes; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _countController.text = '6'; _depthController.text = '42'; setState(() { _diameter = '12'; _sonotubeHeight = '6'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Deck Footings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FOOTING DIAMETER', ['10', '12', '14', '16'], _diameter, (v) { setState(() => _diameter = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'ABOVE GRADE', ['0', '6', '12'], _sonotubeHeight, (v) { setState(() => _sonotubeHeight = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Number of Footings', unit: 'qty', controller: _countController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Frost Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('80LB BAGS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags80lb', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume Each', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeEach!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalVolume!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sonotubes ($_diameter")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sonotubes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Dig bell-shaped holes for uplift resistance. Set J-bolts or post anchors before concrete sets.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
