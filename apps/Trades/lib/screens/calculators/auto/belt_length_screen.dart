import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Belt Length Calculator - Calculate serpentine/V-belt length
class BeltLengthScreen extends ConsumerStatefulWidget {
  const BeltLengthScreen({super.key});
  @override
  ConsumerState<BeltLengthScreen> createState() => _BeltLengthScreenState();
}

class _BeltLengthScreenState extends ConsumerState<BeltLengthScreen> {
  final _pulley1Controller = TextEditingController();
  final _pulley2Controller = TextEditingController();
  final _centerDistanceController = TextEditingController();

  double? _beltLength;

  void _calculate() {
    final d1 = double.tryParse(_pulley1Controller.text);
    final d2 = double.tryParse(_pulley2Controller.text);
    final c = double.tryParse(_centerDistanceController.text);

    if (d1 == null || d2 == null || c == null || c <= 0) {
      setState(() { _beltLength = null; });
      return;
    }

    // Belt length formula for two pulleys:
    // L = 2C + π(D1+D2)/2 + (D1-D2)²/(4C)
    final pi = 3.14159;
    final length = (2 * c) + (pi * (d1 + d2) / 2) + ((d1 - d2) * (d1 - d2) / (4 * c));

    setState(() {
      _beltLength = length;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pulley1Controller.clear();
    _pulley2Controller.clear();
    _centerDistanceController.clear();
    setState(() { _beltLength = null; });
  }

  @override
  void dispose() {
    _pulley1Controller.dispose();
    _pulley2Controller.dispose();
    _centerDistanceController.dispose();
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
        title: Text('Belt Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pulley 1 Diameter', unit: 'in', hint: 'Larger pulley', controller: _pulley1Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pulley 2 Diameter', unit: 'in', hint: 'Smaller pulley', controller: _pulley2Controller, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Center Distance', unit: 'in', hint: 'Between shafts', controller: _centerDistanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_beltLength != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTipsCard(colors),
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
        Text('L = 2C + π(D1+D2)/2 + (D1-D2)²/4C', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Calculate belt length for two-pulley system', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BELT LENGTH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_beltLength!.toStringAsFixed(2)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('≈ ${(_beltLength! * 25.4).toStringAsFixed(0)} mm', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Order closest standard size. Multi-pulley systems require measurement or software.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BELT SIZING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Measure existing belt if available', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• For serpentine: match rib count', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• For V-belts: match profile (A, B, etc.)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check tensioner range on new belt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• AC delete requires shorter belt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
