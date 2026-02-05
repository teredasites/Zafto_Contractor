import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Dynamic Compression Ratio Calculator - DCR based on intake valve closing
class DynamicCompressionScreen extends ConsumerStatefulWidget {
  const DynamicCompressionScreen({super.key});
  @override
  ConsumerState<DynamicCompressionScreen> createState() => _DynamicCompressionScreenState();
}

class _DynamicCompressionScreenState extends ConsumerState<DynamicCompressionScreen> {
  final _staticCrController = TextEditingController();
  final _intakeCloseController = TextEditingController(text: '70');
  final _rodLengthController = TextEditingController();
  final _strokeController = TextEditingController();

  double? _dynamicCr;
  double? _effectiveStroke;

  void _calculate() {
    final staticCr = double.tryParse(_staticCrController.text);
    final intakeClose = double.tryParse(_intakeCloseController.text);
    final rodLength = double.tryParse(_rodLengthController.text);
    final stroke = double.tryParse(_strokeController.text);

    if (staticCr == null || intakeClose == null || rodLength == null || stroke == null) {
      setState(() { _dynamicCr = null; });
      return;
    }

    // Calculate effective stroke percentage based on intake valve closing ABDC
    final radians = intakeClose * math.pi / 180;
    final effectivePercent = (1 + math.cos(radians)) / 2;
    final effStroke = stroke * effectivePercent;

    // DCR = ((Effective Stroke * Bore Area) + Clearance) / Clearance
    // Simplified: DCR ≈ 1 + (SCR - 1) * Effective%
    final dcr = 1 + (staticCr - 1) * effectivePercent;

    setState(() {
      _dynamicCr = dcr;
      _effectiveStroke = effStroke;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _staticCrController.clear();
    _intakeCloseController.text = '70';
    _rodLengthController.clear();
    _strokeController.clear();
    setState(() { _dynamicCr = null; });
  }

  @override
  void dispose() {
    _staticCrController.dispose();
    _intakeCloseController.dispose();
    _rodLengthController.dispose();
    _strokeController.dispose();
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
        title: Text('Dynamic Compression', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Static Compression Ratio', unit: ':1', hint: 'e.g. 10.5', controller: _staticCrController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Intake Valve Closing', unit: 'ABDC', hint: 'Degrees after BDC', controller: _intakeCloseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rod Length', unit: 'in', hint: 'Connecting rod', controller: _rodLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Piston travel', controller: _strokeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_dynamicCr != null) _buildResultsCard(colors),
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
        Text('DCR = 1 + (SCR - 1) × Eff%', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Actual compression based on when intake valve closes', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_dynamicCr! < 7.5) {
      analysis = 'Low DCR - safe for boost, may lack NA response';
    } else if (_dynamicCr! < 8.5) {
      analysis = 'Moderate DCR - good for forced induction';
    } else if (_dynamicCr! < 9.0) {
      analysis = 'Street DCR - balanced for pump gas';
    } else {
      analysis = 'High DCR - race gas recommended';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Dynamic CR', '${_dynamicCr!.toStringAsFixed(2)}:1', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Effective Stroke', '${_effectiveStroke!.toStringAsFixed(3)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
