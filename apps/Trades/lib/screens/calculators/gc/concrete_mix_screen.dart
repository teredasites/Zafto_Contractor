import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Concrete Mix Calculator - Mix ratios and materials
class ConcreteMixScreen extends ConsumerStatefulWidget {
  const ConcreteMixScreen({super.key});
  @override
  ConsumerState<ConcreteMixScreen> createState() => _ConcreteMixScreenState();
}

class _ConcreteMixScreenState extends ConsumerState<ConcreteMixScreen> {
  final _volumeController = TextEditingController(text: '5');

  String _mixType = '3000';

  double? _cement;
  double? _sand;
  double? _gravel;
  double? _water;
  int? _bags94lb;

  @override
  void dispose() { _volumeController.dispose(); super.dispose(); }

  void _calculate() {
    final cubicYards = double.tryParse(_volumeController.text);

    if (cubicYards == null) {
      setState(() { _cement = null; _sand = null; _gravel = null; _water = null; _bags94lb = null; });
      return;
    }

    final cubicFeet = cubicYards * 27;

    // Mix ratios by strength (cement:sand:gravel by volume)
    double cementRatio, sandRatio, gravelRatio, waterCementRatio;
    switch (_mixType) {
      case '2500': // 1:3:5
        cementRatio = 1; sandRatio = 3; gravelRatio = 5; waterCementRatio = 0.55;
        break;
      case '3000': // 1:2.5:4
        cementRatio = 1; sandRatio = 2.5; gravelRatio = 4; waterCementRatio = 0.50;
        break;
      case '3500': // 1:2:3
        cementRatio = 1; sandRatio = 2; gravelRatio = 3; waterCementRatio = 0.45;
        break;
      case '4000': // 1:1.5:3
        cementRatio = 1; sandRatio = 1.5; gravelRatio = 3; waterCementRatio = 0.40;
        break;
      default:
        cementRatio = 1; sandRatio = 2.5; gravelRatio = 4; waterCementRatio = 0.50;
    }

    final totalParts = cementRatio + sandRatio + gravelRatio;

    // Volumes in cubic feet
    final cementCF = (cementRatio / totalParts) * cubicFeet * 1.5; // 50% waste/shrinkage factor
    final sandCF = (sandRatio / totalParts) * cubicFeet * 1.5;
    final gravelCF = (gravelRatio / totalParts) * cubicFeet * 1.5;

    // 94lb bag of cement = 1 cu ft
    final bags94lb = cementCF.ceil();

    // Cement weighs ~94 lbs per cu ft
    final cementLbs = cementCF * 94;
    final waterGallons = (cementLbs * waterCementRatio) / 8.34; // 8.34 lbs per gallon

    setState(() {
      _cement = cementCF;
      _sand = sandCF / 27; // Convert to cubic yards
      _gravel = gravelCF / 27;
      _water = waterGallons;
      _bags94lb = bags94lb;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _volumeController.text = '5'; setState(() => _mixType = '3000'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Concrete Mix', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MIX STRENGTH (PSI)', ['2500', '3000', '3500', '4000'], _mixType, (v) { setState(() => _mixType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Concrete Volume', unit: 'yd³', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cement != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CEMENT BAGS (94lb)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags94lb', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cement', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cement!.toStringAsFixed(1)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sand', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sand!.toStringAsFixed(2)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravel!.toStringAsFixed(2)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_water!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('For structural work, order ready-mix with certified batch tickets. Site mixing for non-structural only.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
