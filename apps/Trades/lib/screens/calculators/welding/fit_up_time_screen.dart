import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fit-Up Time Calculator - Estimate joint preparation time
class FitUpTimeScreen extends ConsumerStatefulWidget {
  const FitUpTimeScreen({super.key});
  @override
  ConsumerState<FitUpTimeScreen> createState() => _FitUpTimeScreenState();
}

class _FitUpTimeScreenState extends ConsumerState<FitUpTimeScreen> {
  final _numberOfJointsController = TextEditingController(text: '1');
  String _jointType = 'Butt';
  String _complexity = 'Standard';
  String _fitMethod = 'Manual';

  double? _fitUpTime;
  double? _totalTime;
  String? _notes;

  // Base fit-up times in minutes per joint
  static const Map<String, double> _baseTimes = {
    'Butt': 15,
    'Fillet': 8,
    'Corner': 10,
    'Lap': 5,
    'Pipe': 25,
    'Branch': 35,
  };

  // Complexity multipliers
  static const Map<String, double> _complexityMult = {
    'Simple': 0.7,
    'Standard': 1.0,
    'Complex': 1.5,
    'Critical': 2.0,
  };

  // Fit method multipliers
  static const Map<String, double> _methodMult = {
    'Manual': 1.0,
    'Fixture': 0.6,
    'Tack Welded': 0.8,
    'Clamped': 0.7,
  };

  void _calculate() {
    final numberOfJoints = int.tryParse(_numberOfJointsController.text) ?? 1;

    final baseTime = _baseTimes[_jointType] ?? 15;
    final complexityMult = _complexityMult[_complexity] ?? 1.0;
    final methodMult = _methodMult[_fitMethod] ?? 1.0;

    final fitUpTimePerJoint = baseTime * complexityMult * methodMult;
    final totalTime = fitUpTimePerJoint * numberOfJoints;

    String notes;
    if (_complexity == 'Critical') {
      notes = 'Critical tolerance fit-up - allow extra time for verification';
    } else if (_fitMethod == 'Fixture') {
      notes = 'Fixture fit-up reduces time but requires setup';
    } else {
      notes = 'Standard $_jointType joint fit-up estimate';
    }

    setState(() {
      _fitUpTime = fitUpTimePerJoint;
      _totalTime = totalTime;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _numberOfJointsController.text = '1';
    setState(() { _fitUpTime = null; });
  }

  @override
  void dispose() {
    _numberOfJointsController.dispose();
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
        title: Text('Fit-Up Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Joint Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildJointSelector(colors),
            const SizedBox(height: 16),
            Text('Complexity', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildComplexitySelector(colors),
            const SizedBox(height: 16),
            Text('Fit Method', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMethodSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Number of Joints', unit: '#', hint: 'Quantity', controller: _numberOfJointsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fitUpTime != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _baseTimes.keys.map((j) => ChoiceChip(
        label: Text(j),
        selected: _jointType == j,
        onSelected: (_) => setState(() { _jointType = j; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildComplexitySelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _complexityMult.keys.map((c) => ChoiceChip(
        label: Text(c),
        selected: _complexity == c,
        onSelected: (_) => setState(() { _complexity = c; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _methodMult.keys.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 12)),
        selected: _fitMethod == m,
        onSelected: (_) => setState(() { _fitMethod = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Fit-Up Time Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate joint preparation and alignment time', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Fit-Up', '${_totalTime!.toStringAsFixed(0)} min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Joint', '${_fitUpTime!.toStringAsFixed(0)} min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hours', '${(_totalTime! / 60).toStringAsFixed(2)} hrs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
