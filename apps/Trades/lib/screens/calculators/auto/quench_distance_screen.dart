import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Quench Distance Calculator - Piston to head clearance optimization
class QuenchDistanceScreen extends ConsumerStatefulWidget {
  const QuenchDistanceScreen({super.key});
  @override
  ConsumerState<QuenchDistanceScreen> createState() => _QuenchDistanceScreenState();
}

class _QuenchDistanceScreenState extends ConsumerState<QuenchDistanceScreen> {
  final _deckClearanceController = TextEditingController();
  final _gasketThicknessController = TextEditingController(text: '0.040');
  final _gasketCompressController = TextEditingController(text: '0.038');

  double? _quenchDistance;

  void _calculate() {
    final deckClearance = double.tryParse(_deckClearanceController.text);
    final gasketThickness = double.tryParse(_gasketThicknessController.text);
    final gasketCompress = double.tryParse(_gasketCompressController.text);

    if (deckClearance == null || gasketThickness == null) {
      setState(() { _quenchDistance = null; });
      return;
    }

    // Quench = Deck Clearance + Compressed Gasket Thickness
    final compressed = gasketCompress ?? (gasketThickness * 0.95);
    final quench = deckClearance + compressed;

    setState(() {
      _quenchDistance = quench;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _deckClearanceController.clear();
    _gasketThicknessController.text = '0.040';
    _gasketCompressController.text = '0.038';
    setState(() { _quenchDistance = null; });
  }

  @override
  void dispose() {
    _deckClearanceController.dispose();
    _gasketThicknessController.dispose();
    _gasketCompressController.dispose();
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
        title: Text('Quench Distance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Deck Clearance', unit: 'in', hint: 'Piston to deck', controller: _deckClearanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Gasket Thickness', unit: 'in', hint: 'Uncompressed', controller: _gasketThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compressed Thickness', unit: 'in', hint: 'After torque', controller: _gasketCompressController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_quenchDistance != null) _buildResultsCard(colors),
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
        Text('Quench = Deck + Compressed Gasket', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Critical for detonation control and power', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    Color statusColor = colors.textSecondary;
    if (_quenchDistance! < 0.035) {
      analysis = 'Very tight - risk of piston/head contact. Verify with clay.';
      statusColor = colors.error;
    } else if (_quenchDistance! < 0.045) {
      analysis = 'Optimal range - excellent quench effect, good for performance.';
      statusColor = colors.accentSuccess;
    } else if (_quenchDistance! < 0.060) {
      analysis = 'Acceptable - slight reduction in quench effectiveness.';
    } else {
      analysis = 'Too large - poor quench, increased detonation risk, less power.';
      statusColor = colors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Quench Distance', '${_quenchDistance!.toStringAsFixed(4)}"', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(analysis, style: TextStyle(color: statusColor, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Target: 0.035" - 0.045" for street, 0.028" - 0.035" for race', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
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
