import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Arc Length Calculator - Optimal arc length for process
class ArcLengthScreen extends ConsumerStatefulWidget {
  const ArcLengthScreen({super.key});
  @override
  ConsumerState<ArcLengthScreen> createState() => _ArcLengthScreenState();
}

class _ArcLengthScreenState extends ConsumerState<ArcLengthScreen> {
  String _process = 'SMAW';
  String _electrodeSize = '1/8';
  String _transferMode = 'Short Circuit';

  double? _minArcLength;
  double? _maxArcLength;
  double? _optimalArcLength;
  String? _notes;

  // Electrode diameters in decimal inches
  static const Map<String, double> _electrodeDiameters = {
    '3/32': 0.09375,
    '1/8': 0.125,
    '5/32': 0.15625,
    '3/16': 0.1875,
    '7/32': 0.21875,
    '1/4': 0.25,
  };

  void _calculate() {
    double minArc, maxArc, optimal;
    String notes;

    final electrodeDia = _electrodeDiameters[_electrodeSize] ?? 0.125;

    if (_process == 'SMAW') {
      // Rule: Arc length = electrode diameter
      minArc = electrodeDia * 0.75;
      maxArc = electrodeDia * 1.25;
      optimal = electrodeDia;
      notes = 'Arc length equals electrode diameter. Too long = porosity, too short = sticking';
    } else if (_process == 'GTAW') {
      // TIG: Arc length = electrode diameter or less
      minArc = electrodeDia * 0.5;
      maxArc = electrodeDia * 1.0;
      optimal = electrodeDia * 0.75;
      notes = 'Keep arc tight for best gas coverage. Increase for fillet corners';
    } else if (_process == 'GMAW') {
      // MIG depends on transfer mode
      if (_transferMode == 'Short Circuit') {
        minArc = 0.25;
        maxArc = 0.5;
        optimal = 0.375;
        notes = 'Short circuit - short arc, listen for consistent crackle';
      } else if (_transferMode == 'Spray') {
        minArc = 0.5;
        maxArc = 0.75;
        optimal = 0.625;
        notes = 'Spray transfer - longer arc, consistent hissing sound';
      } else {
        // Globular
        minArc = 0.375;
        maxArc = 0.625;
        optimal = 0.5;
        notes = 'Globular - avoid if possible, spatter prone';
      }
    } else {
      // FCAW
      minArc = 0.5;
      maxArc = 0.875;
      optimal = 0.75;
      notes = 'FCAW typically runs longer arc than solid wire MIG';
    }

    setState(() {
      _minArcLength = minArc;
      _maxArcLength = maxArc;
      _optimalArcLength = optimal;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() { _minArcLength = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Arc Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            if (_process == 'SMAW' || _process == 'GTAW') ...[
              Text('Electrode Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              _buildSizeSelector(colors),
            ],
            if (_process == 'GMAW') ...[
              Text('Transfer Mode', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              _buildTransferSelector(colors),
            ],
            const SizedBox(height: 32),
            if (_minArcLength != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['SMAW', 'GTAW', 'GMAW', 'FCAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _electrodeDiameters.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _electrodeSize == size,
        onSelected: (_) => setState(() { _electrodeSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildTransferSelector(ZaftoColors colors) {
    final modes = ['Short Circuit', 'Globular', 'Spray'];
    return Wrap(
      spacing: 8,
      children: modes.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 12)),
        selected: _transferMode == m,
        onSelected: (_) => setState(() { _transferMode = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Optimal Arc Length', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('SMAW rule: Arc length = electrode diameter', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Optimal Arc', '${_optimalArcLength!.toStringAsFixed(3)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Range', '${_minArcLength!.toStringAsFixed(3)}" - ${_maxArcLength!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${(_optimalArcLength! * 25.4).toStringAsFixed(1)} mm'),
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
