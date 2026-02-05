import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Backpressure Calculator - Exhaust backpressure effects
class BackpressureScreen extends ConsumerStatefulWidget {
  const BackpressureScreen({super.key});
  @override
  ConsumerState<BackpressureScreen> createState() => _BackpressureScreenState();
}

class _BackpressureScreenState extends ConsumerState<BackpressureScreen> {
  final _cfmController = TextEditingController();
  final _pipeDiameterController = TextEditingController(text: '2.5');
  final _pipeLengthController = TextEditingController(text: '10');
  final _bendsController = TextEditingController(text: '2');

  double? _backpressurePsi;
  double? _flowVelocity;
  double? _powerLoss;
  String? _assessment;

  void _calculate() {
    final cfm = double.tryParse(_cfmController.text);
    final pipeD = double.tryParse(_pipeDiameterController.text);
    final pipeL = double.tryParse(_pipeLengthController.text);
    final bends = double.tryParse(_bendsController.text);

    if (cfm == null || pipeD == null || pipeL == null || bends == null || pipeD <= 0) {
      setState(() { _backpressurePsi = null; });
      return;
    }

    // Pipe cross-sectional area in square feet
    final areaFt2 = 3.14159 * (pipeD / 24) * (pipeD / 24);

    // Flow velocity in ft/min
    final velocity = cfm / areaFt2;

    // Simplified backpressure calculation (PSI)
    // Based on Darcy-Weisbach with typical exhaust conditions
    // Each 90-degree bend adds equivalent of ~2ft of pipe
    final effectiveLength = pipeL + (bends * 2);

    // Friction factor approximation for hot exhaust gas
    final frictionFactor = 0.02;

    // Pressure drop in PSI (simplified)
    final velocityFps = velocity / 60;
    final pressureDrop = frictionFactor * (effectiveLength / (pipeD / 12)) * (velocityFps * velocityFps) / (2 * 32.2) * 0.036;

    // Power loss estimate: roughly 1% HP per 1 PSI backpressure
    final hpLoss = pressureDrop * 1.5;

    // Assessment
    String assess;
    if (pressureDrop < 1.0) {
      assess = 'Excellent - minimal restriction';
    } else if (pressureDrop < 2.0) {
      assess = 'Good - acceptable for street use';
    } else if (pressureDrop < 3.5) {
      assess = 'Marginal - consider larger pipe';
    } else {
      assess = 'Poor - significant power loss, upgrade needed';
    }

    setState(() {
      _backpressurePsi = pressureDrop;
      _flowVelocity = velocity;
      _powerLoss = hpLoss;
      _assessment = assess;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _cfmController.clear();
    _pipeDiameterController.text = '2.5';
    _pipeLengthController.text = '10';
    _bendsController.text = '2';
    setState(() { _backpressurePsi = null; });
  }

  @override
  void dispose() {
    _cfmController.dispose();
    _pipeDiameterController.dispose();
    _pipeLengthController.dispose();
    _bendsController.dispose();
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
        title: Text('Backpressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Exhaust Flow', unit: 'CFM', hint: 'HP x 1.5 for NA engines', controller: _cfmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pipe Diameter', unit: 'in', hint: 'Inside diameter', controller: _pipeDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pipe Length', unit: 'ft', hint: 'Total exhaust length', controller: _pipeLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Bends', unit: 'qty', hint: '90-degree bends', controller: _bendsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_backpressurePsi != null) _buildResultsCard(colors),
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
        Text('dP = f x (L/D) x (v^2/2g)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Darcy-Weisbach pressure drop with bend equivalents', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _backpressurePsi! < 2.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Backpressure', '${_backpressurePsi!.toStringAsFixed(2)} PSI', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Velocity', '${_flowVelocity!.toStringAsFixed(0)} ft/min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Power Loss', '${_powerLoss!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isGood ? colors.accentSuccess.withValues(alpha: 0.1) : colors.accentWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_assessment!, style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 12),
        _buildGuidelineCard(colors),
      ]),
    );
  }

  Widget _buildGuidelineCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Backpressure Guidelines:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildGuideRow(colors, '< 1.0 PSI', 'Race-level, minimal loss'),
        _buildGuideRow(colors, '1.0-2.0 PSI', 'Street performance'),
        _buildGuideRow(colors, '2.0-3.5 PSI', 'Stock/mild build'),
        _buildGuideRow(colors, '> 3.5 PSI', 'Restrictive, needs upgrade'),
      ]),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String range, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 90, child: Text(range, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace'))),
        Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
