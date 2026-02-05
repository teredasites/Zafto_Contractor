import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dilution Calculator - Weld metal dilution percentage
class DilutionScreen extends ConsumerStatefulWidget {
  const DilutionScreen({super.key});
  @override
  ConsumerState<DilutionScreen> createState() => _DilutionScreenState();
}

class _DilutionScreenState extends ConsumerState<DilutionScreen> {
  final _penetrationController = TextEditingController();
  final _reinforcementController = TextEditingController();
  String _process = 'GMAW';
  String _jointType = 'Fillet';

  double? _dilution;
  double? _baseMetal;
  String? _notes;

  // Typical dilution ranges by process
  static const Map<String, List<double>> _processDilution = {
    'SMAW': [20, 35],
    'GMAW': [15, 30],
    'FCAW': [20, 40],
    'SAW': [40, 70],
    'GTAW': [10, 25],
  };

  void _calculate() {
    final penetration = double.tryParse(_penetrationController.text);
    final reinforcement = double.tryParse(_reinforcementController.text);

    double dilution;
    String notes;

    if (penetration != null && reinforcement != null && (penetration + reinforcement) > 0) {
      // Dilution = Base metal melted / Total weld metal
      // Approximation: Dilution ≈ Penetration / (Penetration + Reinforcement)
      dilution = (penetration / (penetration + reinforcement)) * 100;
      notes = 'Calculated from penetration/reinforcement ratio';
    } else {
      // Use process typical values
      final range = _processDilution[_process] ?? [25, 35];
      dilution = (range[0] + range[1]) / 2;

      // Adjust for joint type
      if (_jointType == 'Groove') {
        dilution *= 1.1; // Groove welds typically have more dilution
      } else if (_jointType == 'Overlay') {
        dilution *= 0.7; // Surfacing welds minimize dilution
      }

      notes = 'Estimated from typical $_process values. Enter dimensions for calculation';
    }

    final baseMetal = dilution;

    setState(() {
      _dilution = dilution;
      _baseMetal = baseMetal;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _penetrationController.clear();
    _reinforcementController.clear();
    setState(() { _dilution = null; });
  }

  @override
  void dispose() {
    _penetrationController.dispose();
    _reinforcementController.dispose();
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
        title: Text('Dilution', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            Text('Joint Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildJointSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Penetration Depth', unit: 'in', hint: 'Optional - measured', controller: _penetrationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Reinforcement', unit: 'in', hint: 'Optional - measured', controller: _reinforcementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_dilution != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _processDilution.keys.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    final types = ['Fillet', 'Groove', 'Overlay'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _jointType == t,
        onSelected: (_) => setState(() { _jointType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('D = Base Metal / Total Weld', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Percent of weld metal from base material', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Dilution', '${_dilution!.toStringAsFixed(0)}%', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Base Metal', '${_baseMetal!.toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Filler Metal', '${(100 - _baseMetal!).toStringAsFixed(0)}%'),
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
