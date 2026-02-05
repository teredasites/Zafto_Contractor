import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Fertilizer Calculator - Fertilizing trees and shrubs
class TreeFertilizerScreen extends ConsumerStatefulWidget {
  const TreeFertilizerScreen({super.key});
  @override
  ConsumerState<TreeFertilizerScreen> createState() => _TreeFertilizerScreenState();
}

class _TreeFertilizerScreenState extends ConsumerState<TreeFertilizerScreen> {
  final _trunkDiameterController = TextEditingController(text: '6');
  final _treeCountController = TextEditingController(text: '3');

  String _fertType = 'granular';

  double? _lbsPerTree;
  double? _totalLbs;
  double? _dripLineRadius;
  String? _method;

  @override
  void dispose() { _trunkDiameterController.dispose(); _treeCountController.dispose(); super.dispose(); }

  void _calculate() {
    final trunkDiameter = double.tryParse(_trunkDiameterController.text) ?? 6;
    final treeCount = int.tryParse(_treeCountController.text) ?? 3;

    // General rule: 1-3 lbs of actual N per 1000 sq ft of root zone
    // Root zone ≈ drip line, roughly 1 ft radius per inch of trunk
    final dripLineRadius = trunkDiameter * 1.0; // feet
    final rootZoneSqFt = 3.14159 * dripLineRadius * dripLineRadius;

    double lbsPerTree;
    String method;
    if (_fertType == 'granular') {
      // Granular: 2-4 lbs per inch of trunk diameter
      lbsPerTree = trunkDiameter * 3;
      method = 'Surface broadcast';
    } else if (_fertType == 'spikes') {
      // Spikes: 1 spike per inch diameter
      lbsPerTree = trunkDiameter; // spikes count
      method = 'Around drip line';
    } else {
      // Liquid deep root
      lbsPerTree = rootZoneSqFt * 0.002; // oz per sq ft × conversion
      method = 'Deep root injection';
    }

    final total = lbsPerTree * treeCount;

    setState(() {
      _lbsPerTree = lbsPerTree;
      _totalLbs = total;
      _dripLineRadius = dripLineRadius;
      _method = method;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _trunkDiameterController.text = '6'; _treeCountController.text = '3'; setState(() { _fertType = 'granular'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Fertilizer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FERTILIZER TYPE', ['granular', 'spikes', 'liquid'], _fertType, {'granular': 'Granular', 'spikes': 'Spikes', 'liquid': 'Liquid'}, (v) { setState(() => _fertType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trunk Diameter', unit: 'in', controller: _trunkDiameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tree Count', unit: '', controller: _treeCountController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_lbsPerTree != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fertType == 'spikes' ? 'SPIKES NEEDED' : 'FERTILIZER NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_fertType == 'spikes' ? '${_totalLbs!.toStringAsFixed(0)}' : '${_totalLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per tree', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_fertType == 'spikes' ? '${_lbsPerTree!.toStringAsFixed(0)} spikes' : '${_lbsPerTree!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drip line radius', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_dripLineRadius!.toStringAsFixed(0)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Method', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_method', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTreeFertGuide(colors),
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

  Widget _buildTreeFertGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TREE FERTILIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best time', 'Early spring or fall'),
        _buildTableRow(colors, 'Application zone', 'Drip line, not trunk'),
        _buildTableRow(colors, 'Avoid if', 'Drought stressed'),
        _buildTableRow(colors, 'New trees', 'Wait 1 year'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
