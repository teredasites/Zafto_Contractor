import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weight Distribution Calculator - Front/rear bias calculation
class WeightDistributionScreen extends ConsumerStatefulWidget {
  const WeightDistributionScreen({super.key});
  @override
  ConsumerState<WeightDistributionScreen> createState() => _WeightDistributionScreenState();
}

class _WeightDistributionScreenState extends ConsumerState<WeightDistributionScreen> {
  final _frontWeightController = TextEditingController();
  final _rearWeightController = TextEditingController();
  final _wheelbaseController = TextEditingController();

  double? _totalWeight;
  double? _frontPercent;
  double? _rearPercent;
  double? _cgFromFront;

  void _calculate() {
    final frontWeight = double.tryParse(_frontWeightController.text);
    final rearWeight = double.tryParse(_rearWeightController.text);
    final wheelbase = double.tryParse(_wheelbaseController.text);

    if (frontWeight == null || rearWeight == null) {
      setState(() { _totalWeight = null; });
      return;
    }

    final total = frontWeight + rearWeight;
    final frontPct = (frontWeight / total) * 100;
    final rearPct = (rearWeight / total) * 100;

    double? cgFromFront;
    if (wheelbase != null && wheelbase > 0) {
      cgFromFront = (rearWeight / total) * wheelbase;
    }

    setState(() {
      _totalWeight = total;
      _frontPercent = frontPct;
      _rearPercent = rearPct;
      _cgFromFront = cgFromFront;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _frontWeightController.clear();
    _rearWeightController.clear();
    _wheelbaseController.clear();
    setState(() { _totalWeight = null; });
  }

  @override
  void dispose() {
    _frontWeightController.dispose();
    _rearWeightController.dispose();
    _wheelbaseController.dispose();
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
        title: Text('Weight Distribution', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Front Axle Weight', unit: 'lbs', hint: 'Weight on front', controller: _frontWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rear Axle Weight', unit: 'lbs', hint: 'Weight on rear', controller: _rearWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheelbase (Optional)', unit: 'in', hint: 'For CG calculation', controller: _wheelbaseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalWeight != null) _buildResultsCard(colors),
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
        Text('Front% = Front Weight / Total × 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Balanced distribution improves handling', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_frontPercent! > 55) {
      analysis = 'Front-heavy (typical FWD) - prone to understeer';
    } else if (_frontPercent! < 45) {
      analysis = 'Rear-heavy (some sports cars) - can oversteer';
    } else {
      analysis = 'Well balanced - neutral handling characteristics';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Weight', '${_totalWeight!.toStringAsFixed(0)} lbs', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: colors.bgBase),
          child: Row(children: [
            Flexible(
              flex: _frontPercent!.round(),
              child: Container(
                decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
                alignment: Alignment.center,
                child: Text('${_frontPercent!.toStringAsFixed(1)}%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
            Flexible(
              flex: _rearPercent!.round(),
              child: Container(
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.5), borderRadius: const BorderRadius.horizontal(right: Radius.circular(8))),
                alignment: Alignment.center,
                child: Text('${_rearPercent!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Front', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('Rear', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ]),
        if (_cgFromFront != null) ...[
          const SizedBox(height: 16),
          _buildResultRow(colors, 'CG from Front Axle', '${_cgFromFront!.toStringAsFixed(1)}"'),
        ],
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
