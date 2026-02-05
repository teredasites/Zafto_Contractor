import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Staking Calculator - Stakes and ties for new trees
class TreeStakingScreen extends ConsumerStatefulWidget {
  const TreeStakingScreen({super.key});
  @override
  ConsumerState<TreeStakingScreen> createState() => _TreeStakingScreenState();
}

class _TreeStakingScreenState extends ConsumerState<TreeStakingScreen> {
  final _treeCountController = TextEditingController(text: '5');
  final _caliperController = TextEditingController(text: '2');

  String _stakeType = 'wood';

  int? _stakesNeeded;
  int? _tiesNeeded;
  double? _stakeLengthFt;
  String? _stakingMethod;

  @override
  void dispose() { _treeCountController.dispose(); _caliperController.dispose(); super.dispose(); }

  void _calculate() {
    final treeCount = int.tryParse(_treeCountController.text) ?? 5;
    final caliper = double.tryParse(_caliperController.text) ?? 2;

    // Staking method based on caliper
    int stakesPerTree;
    double stakeLength;
    String method;

    if (caliper < 2) {
      stakesPerTree = 1;
      stakeLength = 5;
      method = 'Single stake';
    } else if (caliper < 4) {
      stakesPerTree = 2;
      stakeLength = 6;
      method = 'Two-stake guying';
    } else {
      stakesPerTree = 3;
      stakeLength = 8;
      method = 'Three-stake guying';
    }

    final totalStakes = treeCount * stakesPerTree;
    final totalTies = totalStakes; // One tie per stake

    setState(() {
      _stakesNeeded = totalStakes;
      _tiesNeeded = totalTies;
      _stakeLengthFt = stakeLength;
      _stakingMethod = method;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _treeCountController.text = '5'; _caliperController.text = '2'; setState(() { _stakeType = 'wood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Staking', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STAKE TYPE', ['wood', 'metal', 'lodge'], _stakeType, {'wood': 'Wood', 'metal': 'Metal T-Post', 'lodge': 'Lodgepole'}, (v) { setState(() => _stakeType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Tree Count', unit: '', controller: _treeCountController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Caliper', unit: 'in', controller: _caliperController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_stakesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STAKES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stakesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Method', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_stakingMethod', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stake length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_stakeLengthFt!.toStringAsFixed(0)}' stakes", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tree ties/straps', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tiesNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStakingGuide(colors),
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

  Widget _buildStakingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STAKING GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Stake distance', '18-24\" from trunk'),
        _buildTableRow(colors, 'Tie height', '1/3-1/2 up trunk'),
        _buildTableRow(colors, 'Tie type', 'Wide, flexible strap'),
        _buildTableRow(colors, 'Remove after', '1-2 years'),
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
