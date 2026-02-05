import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tire Wear Calculator - Remaining life and diagnosis
class TireWearScreen extends ConsumerStatefulWidget {
  const TireWearScreen({super.key});
  @override
  ConsumerState<TireWearScreen> createState() => _TireWearScreenState();
}

class _TireWearScreenState extends ConsumerState<TireWearScreen> {
  final _currentDepthController = TextEditingController();
  final _milesDrivenController = TextEditingController();

  double? _remainingLife;
  double? _milesRemaining;

  void _calculate() {
    final currentDepth = double.tryParse(_currentDepthController.text);
    final milesDriven = double.tryParse(_milesDrivenController.text);

    if (currentDepth == null) {
      setState(() { _remainingLife = null; });
      return;
    }

    // New tire = 10/32", worn out = 2/32"
    const newDepth = 10.0;
    const minDepth = 2.0;
    final usableDepth = newDepth - minDepth; // 8/32"
    final remainingUsable = currentDepth - minDepth;
    final percentRemaining = (remainingUsable / usableDepth) * 100;

    double? miles;
    if (milesDriven != null && milesDriven > 0) {
      final usedDepth = newDepth - currentDepth;
      if (usedDepth > 0) {
        final milesPerDepth = milesDriven / usedDepth;
        miles = remainingUsable * milesPerDepth;
      }
    }

    setState(() {
      _remainingLife = percentRemaining.clamp(0, 100);
      _milesRemaining = miles;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentDepthController.clear();
    _milesDrivenController.clear();
    setState(() { _remainingLife = null; });
  }

  @override
  void dispose() {
    _currentDepthController.dispose();
    _milesDrivenController.dispose();
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
        title: Text('Tire Wear', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Tread Depth', unit: '/32"', hint: 'Measure in 32nds', controller: _currentDepthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Miles on Tires', unit: 'mi', hint: 'Optional - for projection', controller: _milesDrivenController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_remainingLife != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildWearPatternCard(colors),
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
        Text('New = 10/32" | Replace at 2/32"', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Use penny test: Lincoln head visible = replace', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    String status;
    if (_remainingLife! > 50) {
      statusColor = colors.accentSuccess;
      status = 'Good condition';
    } else if (_remainingLife! > 25) {
      statusColor = colors.warning;
      status = 'Monitor closely';
    } else {
      statusColor = colors.error;
      status = 'Replace soon';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Tread Life Remaining', '${_remainingLife!.toStringAsFixed(0)}%', isPrimary: true),
        if (_milesRemaining != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Estimated Miles Left', '${_milesRemaining!.toStringAsFixed(0)} mi'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildWearPatternCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WEAR PATTERN DIAGNOSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildWearRow(colors, 'Center wear', 'Over-inflation'),
        _buildWearRow(colors, 'Edge wear (both)', 'Under-inflation'),
        _buildWearRow(colors, 'One edge', 'Alignment (camber)'),
        _buildWearRow(colors, 'Feathering', 'Toe misalignment'),
        _buildWearRow(colors, 'Cupping/scalloping', 'Worn shocks/struts'),
        _buildWearRow(colors, 'Flat spots', 'Brake lock-up or storage'),
      ]),
    );
  }

  Widget _buildWearRow(ZaftoColors colors, String pattern, String cause) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(pattern, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Expanded(child: Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
