import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Chipper Output Calculator - Wood chips from branches
class ChipperOutputScreen extends ConsumerStatefulWidget {
  const ChipperOutputScreen({super.key});
  @override
  ConsumerState<ChipperOutputScreen> createState() => _ChipperOutputScreenState();
}

class _ChipperOutputScreenState extends ConsumerState<ChipperOutputScreen> {
  final _branchCuYdController = TextEditingController(text: '5');

  String _woodType = 'mixed';

  double? _chipsCuYd;
  double? _reductionPercent;
  int? _truckLoads;
  double? _mulchCoverage;

  @override
  void dispose() { _branchCuYdController.dispose(); super.dispose(); }

  void _calculate() {
    final branchVolume = double.tryParse(_branchCuYdController.text) ?? 5;

    // Reduction ratio varies by wood type
    double reductionRatio;
    switch (_woodType) {
      case 'softwood':
        reductionRatio = 0.25; // Soft compacts more
        break;
      case 'hardwood':
        reductionRatio = 0.35;
        break;
      case 'mixed':
        reductionRatio = 0.30;
        break;
      default:
        reductionRatio = 0.30;
    }

    final chips = branchVolume * reductionRatio;
    final reduction = (1 - reductionRatio) * 100;

    // Truck loads (chip truck ~12 cu yd)
    final trucks = (chips / 12).ceil();

    // Mulch coverage at 3" depth: 1 cu yd = 108 sq ft
    final coverage = chips * 108;

    setState(() {
      _chipsCuYd = chips;
      _reductionPercent = reduction;
      _truckLoads = trucks < 1 ? 1 : trucks;
      _mulchCoverage = coverage;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _branchCuYdController.text = '5'; setState(() { _woodType = 'mixed'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Chipper Output', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WOOD TYPE', ['softwood', 'mixed', 'hardwood'], _woodType, {'softwood': 'Softwood', 'mixed': 'Mixed', 'hardwood': 'Hardwood'}, (v) { setState(() => _woodType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Brush/Branch Volume', unit: 'cu yd', controller: _branchCuYdController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_chipsCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CHIP OUTPUT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_chipsCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume reduction', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_reductionPercent!.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Chip truck loads', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_truckLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mulch coverage @ 3\"', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchCoverage!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildChipperGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildChipperGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CHIPPER NOTES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Reduction', '65-75%'),
        _buildTableRow(colors, 'Fresh chips', 'Age 3-6 months'),
        _buildTableRow(colors, 'N tie-up', 'Add nitrogen if fresh'),
        _buildTableRow(colors, 'Best use', 'Paths, not beds'),
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
