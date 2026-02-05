import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pipe Fit-Up Calculator - Pipe joint preparation
class PipeFitUpScreen extends ConsumerStatefulWidget {
  const PipeFitUpScreen({super.key});
  @override
  ConsumerState<PipeFitUpScreen> createState() => _PipeFitUpScreenState();
}

class _PipeFitUpScreenState extends ConsumerState<PipeFitUpScreen> {
  final _pipeSizeController = TextEditingController(text: '4');
  final _wallThicknessController = TextEditingController(text: '0.237');
  String _jointType = 'Butt';
  String _process = 'GTAW Root';

  double? _rootOpening;
  double? _rootFace;
  double? _bevelAngle;
  int? _tackCount;
  String? _notes;

  void _calculate() {
    final pipeSize = double.tryParse(_pipeSizeController.text) ?? 4;
    final wallThickness = double.tryParse(_wallThicknessController.text) ?? 0.237;

    double rootOpening, rootFace, bevelAngle;
    int tackCount;
    String notes;

    if (_jointType == 'Butt') {
      if (_process == 'GTAW Root') {
        rootOpening = 0.09375; // 3/32"
        rootFace = 0.0625;    // 1/16"
        bevelAngle = 37.5;
        notes = 'Standard GTAW root setup - tight root, land for keyhole';
      } else if (_process == 'SMAW Root') {
        rootOpening = 0.125;   // 1/8"
        rootFace = 0.0625;
        bevelAngle = 37.5;
        notes = 'SMAW root - slightly wider gap for electrode access';
      } else {
        rootOpening = 0.09375;
        rootFace = 0.09375;
        bevelAngle = 30;
        notes = 'Consumable insert - precise fit-up required';
      }
    } else {
      // Socket weld
      rootOpening = 0.0625; // 1/16" gap at bottom
      rootFace = wallThickness;
      bevelAngle = 0;
      notes = 'Socket weld - 1/16" gap for expansion';
    }

    // Tack count based on pipe diameter
    if (pipeSize <= 2) {
      tackCount = 3;
    } else if (pipeSize <= 6) {
      tackCount = 4;
    } else if (pipeSize <= 12) {
      tackCount = 6;
    } else {
      tackCount = 8;
    }

    setState(() {
      _rootOpening = rootOpening;
      _rootFace = rootFace;
      _bevelAngle = bevelAngle;
      _tackCount = tackCount;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeSizeController.text = '4';
    _wallThicknessController.text = '0.237';
    setState(() { _rootOpening = null; });
  }

  @override
  void dispose() {
    _pipeSizeController.dispose();
    _wallThicknessController.dispose();
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
        title: Text('Pipe Fit-Up', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            Text('Root Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pipe Size', unit: 'NPS', hint: 'Nominal diameter', controller: _pipeSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wall Thickness', unit: 'in', hint: 'Sch 40 = 0.237', controller: _wallThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rootOpening != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    final types = ['Butt', 'Socket'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _jointType == t,
        onSelected: (_) => setState(() { _jointType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['GTAW Root', 'SMAW Root', 'Consumable Insert'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p, style: const TextStyle(fontSize: 12)),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Pipe Joint Fit-Up Guide', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Standard fit-up dimensions for pipe welding', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Root Opening', '${(_rootOpening! * 16).round()}/16" (${_rootOpening!.toStringAsFixed(3)}")', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Root Face', '${(_rootFace! * 16).round()}/16"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Bevel Angle', '${_bevelAngle!.toStringAsFixed(1)}\u00B0'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tack Welds', '$_tackCount minimum'),
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
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 18 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
