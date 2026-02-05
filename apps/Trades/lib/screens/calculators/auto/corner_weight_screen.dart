import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Corner Weight Calculator - Weight distribution analysis
class CornerWeightScreen extends ConsumerStatefulWidget {
  const CornerWeightScreen({super.key});
  @override
  ConsumerState<CornerWeightScreen> createState() => _CornerWeightScreenState();
}

class _CornerWeightScreenState extends ConsumerState<CornerWeightScreen> {
  final _lfController = TextEditingController();
  final _rfController = TextEditingController();
  final _lrController = TextEditingController();
  final _rrController = TextEditingController();

  double? _totalWeight;
  double? _frontPercent;
  double? _leftPercent;
  double? _crossWeight;

  void _calculate() {
    final lf = double.tryParse(_lfController.text);
    final rf = double.tryParse(_rfController.text);
    final lr = double.tryParse(_lrController.text);
    final rr = double.tryParse(_rrController.text);

    if (lf == null || rf == null || lr == null || rr == null) {
      setState(() { _totalWeight = null; });
      return;
    }

    final total = lf + rf + lr + rr;
    final front = lf + rf;
    final left = lf + lr;
    final cross = lf + rr; // Left front + Right rear diagonal

    setState(() {
      _totalWeight = total;
      _frontPercent = (front / total) * 100;
      _leftPercent = (left / total) * 100;
      _crossWeight = (cross / total) * 100;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lfController.clear();
    _rfController.clear();
    _lrController.clear();
    _rrController.clear();
    setState(() { _totalWeight = null; });
  }

  @override
  void dispose() {
    _lfController.dispose();
    _rfController.dispose();
    _lrController.dispose();
    _rrController.dispose();
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
        title: Text('Corner Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Left Front', unit: 'lbs', hint: 'LF', controller: _lfController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Right Front', unit: 'lbs', hint: 'RF', controller: _rfController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Left Rear', unit: 'lbs', hint: 'LR', controller: _lrController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Right Rear', unit: 'lbs', hint: 'RR', controller: _rrController, onChanged: (_) => _calculate())),
            ]),
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
        Text('Cross Weight = (LF + RR) / Total', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('50% cross weight = balanced handling', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final crossDiff = (_crossWeight! - 50).abs();
    Color crossColor = crossDiff < 1 ? colors.accentSuccess : (crossDiff < 3 ? colors.warning : colors.error);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Weight', '${_totalWeight!.toStringAsFixed(0)} lbs', isPrimary: true),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatCard(colors, 'Front', '${_frontPercent!.toStringAsFixed(1)}%')),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard(colors, 'Left', '${_leftPercent!.toStringAsFixed(1)}%')),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard(colors, 'Cross', '${_crossWeight!.toStringAsFixed(1)}%', highlight: crossColor)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            _crossWeight! > 50
                ? 'Tight (LF heavy) - car will oversteer on entry'
                : (_crossWeight! < 50 ? 'Loose (RF heavy) - car will understeer on entry' : 'Balanced - neutral handling'),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String label, String value, {Color? highlight}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: highlight ?? colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
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
