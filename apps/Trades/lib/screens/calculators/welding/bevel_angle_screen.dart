import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Bevel Angle Calculator - Groove angle calculations
class BevelAngleScreen extends ConsumerStatefulWidget {
  const BevelAngleScreen({super.key});
  @override
  ConsumerState<BevelAngleScreen> createState() => _BevelAngleScreenState();
}

class _BevelAngleScreenState extends ConsumerState<BevelAngleScreen> {
  final _thicknessController = TextEditingController();
  final _rootFaceController = TextEditingController(text: '0.0625');
  String _jointType = 'Single V';
  String _process = 'SMAW';

  double? _bevelAngle;
  double? _includedAngle;
  double? _grooveDepth;
  String? _notes;

  // Recommended angles by process
  static const Map<String, Map<String, double>> _recommendedAngles = {
    'SMAW': {'Single V': 30, 'Double V': 30, 'Single Bevel': 45, 'J-Groove': 20},
    'GMAW': {'Single V': 25, 'Double V': 25, 'Single Bevel': 40, 'J-Groove': 15},
    'GTAW': {'Single V': 25, 'Double V': 25, 'Single Bevel': 37.5, 'J-Groove': 15},
    'FCAW': {'Single V': 30, 'Double V': 30, 'Single Bevel': 45, 'J-Groove': 20},
    'SAW': {'Single V': 20, 'Double V': 20, 'Single Bevel': 35, 'J-Groove': 10},
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final rootFace = double.tryParse(_rootFaceController.text) ?? 0.0625;

    final processAngles = _recommendedAngles[_process] ?? _recommendedAngles['SMAW']!;
    final bevelAngle = processAngles[_jointType] ?? 30;

    double includedAngle;
    if (_jointType == 'Single Bevel') {
      includedAngle = bevelAngle;
    } else {
      includedAngle = bevelAngle * 2;
    }

    double? grooveDepth;
    if (thickness != null && thickness > 0) {
      grooveDepth = thickness - rootFace;
    }

    String notes;
    if (_process == 'SAW') {
      notes = 'SAW uses narrower grooves due to deep penetration';
    } else if (_process == 'SMAW') {
      notes = 'Wider angles for electrode access in stick welding';
    } else if (_process == 'GTAW') {
      notes = 'TIG allows tighter angles with precise control';
    } else {
      notes = 'Standard groove preparation for ${_process}';
    }

    setState(() {
      _bevelAngle = bevelAngle;
      _includedAngle = includedAngle;
      _grooveDepth = grooveDepth;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _rootFaceController.text = '0.0625';
    setState(() { _bevelAngle = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _rootFaceController.dispose();
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
        title: Text('Bevel Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            Text('Welding Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Optional - for groove depth', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Root Face', unit: 'in', hint: '1/16" typical', controller: _rootFaceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bevelAngle != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    final types = ['Single V', 'Double V', 'Single Bevel', 'J-Groove'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _jointType == t,
        onSelected: (_) => setState(() { _jointType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['SMAW', 'GMAW', 'GTAW', 'FCAW', 'SAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
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
        Text('Recommended Bevel Angles', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Per AWS D1.1 prequalified joint details', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Bevel Angle', '${_bevelAngle!.toStringAsFixed(0)}\u00B0', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Included Angle', '${_includedAngle!.toStringAsFixed(0)}\u00B0'),
        if (_grooveDepth != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Groove Depth', '${_grooveDepth!.toStringAsFixed(3)}"'),
        ],
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
