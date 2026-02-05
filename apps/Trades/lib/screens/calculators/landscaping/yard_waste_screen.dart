import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Yard Waste Calculator - Debris removal
class YardWasteScreen extends ConsumerStatefulWidget {
  const YardWasteScreen({super.key});
  @override
  ConsumerState<YardWasteScreen> createState() => _YardWasteScreenState();
}

class _YardWasteScreenState extends ConsumerState<YardWasteScreen> {
  final _cubicYardsController = TextEditingController(text: '5');

  String _wasteType = 'mixed';

  int? _trailerLoads;
  int? _dumpsterSize;
  double? _estimatedWeight;
  double? _disposalCost;

  @override
  void dispose() { _cubicYardsController.dispose(); super.dispose(); }

  void _calculate() {
    final cubicYards = double.tryParse(_cubicYardsController.text) ?? 5;

    // Weight varies by waste type (lbs per cubic yard)
    double lbsPerCuYd;
    switch (_wasteType) {
      case 'leaves':
        lbsPerCuYd = 200;
        break;
      case 'branches':
        lbsPerCuYd = 300;
        break;
      case 'mixed':
        lbsPerCuYd = 350;
        break;
      case 'dirt':
        lbsPerCuYd = 2000;
        break;
      default:
        lbsPerCuYd = 350;
    }

    final weight = cubicYards * lbsPerCuYd;

    // Trailer loads (6×12 trailer ~4-5 cu yd capacity)
    final trailers = (cubicYards / 4).ceil();

    // Recommended dumpster size
    int dumpster;
    if (cubicYards <= 3) {
      dumpster = 3;
    } else if (cubicYards <= 6) {
      dumpster = 6;
    } else if (cubicYards <= 10) {
      dumpster = 10;
    } else if (cubicYards <= 20) {
      dumpster = 20;
    } else {
      dumpster = 30;
    }

    // Disposal cost estimate: ~$50-100 per ton
    final tons = weight / 2000;
    final cost = tons * 75;

    setState(() {
      _trailerLoads = trailers;
      _dumpsterSize = dumpster;
      _estimatedWeight = weight;
      _disposalCost = cost;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _cubicYardsController.text = '5'; setState(() { _wasteType = 'mixed'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Yard Waste', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WASTE TYPE', ['leaves', 'branches', 'mixed', 'dirt'], _wasteType, {'leaves': 'Leaves', 'branches': 'Branches', 'mixed': 'Mixed', 'dirt': 'Dirt/Sod'}, (v) { setState(() => _wasteType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Volume', unit: 'cu yd', controller: _cubicYardsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedWeight != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. WEIGHT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_estimatedWeight!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trailer loads (4 yd)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_trailerLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Dumpster size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_dumpsterSize yard', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. disposal cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_disposalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWasteGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWasteGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WEIGHT REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Leaves (loose)', '~200 lbs/cu yd'),
        _buildTableRow(colors, 'Branches', '~300 lbs/cu yd'),
        _buildTableRow(colors, 'Mixed debris', '~350 lbs/cu yd'),
        _buildTableRow(colors, 'Dirt/soil', '~2,000 lbs/cu yd'),
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
