import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Boost by Gear Calculator - Traction-based boost targeting
class BoostByGearScreen extends ConsumerStatefulWidget {
  const BoostByGearScreen({super.key});
  @override
  ConsumerState<BoostByGearScreen> createState() => _BoostByGearScreenState();
}

class _BoostByGearScreenState extends ConsumerState<BoostByGearScreen> {
  final _maxBoostController = TextEditingController();
  final _firstGearController = TextEditingController(text: '50');
  final _secondGearController = TextEditingController(text: '70');
  final _thirdGearController = TextEditingController(text: '85');

  List<double>? _boostTargets;

  void _calculate() {
    final maxBoost = double.tryParse(_maxBoostController.text);
    final firstPct = double.tryParse(_firstGearController.text) ?? 50;
    final secondPct = double.tryParse(_secondGearController.text) ?? 70;
    final thirdPct = double.tryParse(_thirdGearController.text) ?? 85;

    if (maxBoost == null) {
      setState(() { _boostTargets = null; });
      return;
    }

    setState(() {
      _boostTargets = [
        maxBoost * (firstPct / 100),
        maxBoost * (secondPct / 100),
        maxBoost * (thirdPct / 100),
        maxBoost * 0.95,
        maxBoost,
        maxBoost,
      ];
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _maxBoostController.clear();
    _firstGearController.text = '50';
    _secondGearController.text = '70';
    _thirdGearController.text = '85';
    setState(() { _boostTargets = null; });
  }

  @override
  void dispose() {
    _maxBoostController.dispose();
    _firstGearController.dispose();
    _secondGearController.dispose();
    _thirdGearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Boost by Gear', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Max Boost', unit: 'psi', hint: 'Full boost target', controller: _maxBoostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: '1st Gear %', unit: '%', hint: 'Traction limited', controller: _firstGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: '2nd Gear %', unit: '%', hint: 'Building traction', controller: _secondGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: '3rd Gear %', unit: '%', hint: 'Nearly full', controller: _thirdGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_boostTargets != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Manage traction with boost control', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Lower gears = more torque multiplication', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final gears = ['1st', '2nd', '3rd', '4th', '5th', '6th'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BOOST TARGETS BY GEAR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...List.generate(6, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildGearRow(colors, gears[i], _boostTargets![i]),
        )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Adjust percentages based on tire grip, weight transfer, and suspension setup.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildGearRow(ZaftoColors colors, String gear, double boost) {
    final maxBoost = double.tryParse(_maxBoostController.text) ?? 1;
    final percentage = (boost / maxBoost * 100).round();

    return Row(children: [
      SizedBox(width: 40, child: Text(gear, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
      Expanded(
        child: Container(
          height: 24,
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(width: 70, child: Text('${boost.toStringAsFixed(1)} psi', style: TextStyle(color: colors.textSecondary, fontSize: 14), textAlign: TextAlign.right)),
    ]);
  }
}
