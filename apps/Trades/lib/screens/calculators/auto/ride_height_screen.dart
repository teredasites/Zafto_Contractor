import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ride Height Calculator - Suspension height adjustment
class RideHeightScreen extends ConsumerStatefulWidget {
  const RideHeightScreen({super.key});
  @override
  ConsumerState<RideHeightScreen> createState() => _RideHeightScreenState();
}

class _RideHeightScreenState extends ConsumerState<RideHeightScreen> {
  final _lfController = TextEditingController();
  final _rfController = TextEditingController();
  final _lrController = TextEditingController();
  final _rrController = TextEditingController();

  double? _frontAvg;
  double? _rearAvg;
  double? _rake;

  void _calculate() {
    final lf = double.tryParse(_lfController.text);
    final rf = double.tryParse(_rfController.text);
    final lr = double.tryParse(_lrController.text);
    final rr = double.tryParse(_rrController.text);

    if (lf == null || rf == null || lr == null || rr == null) {
      setState(() { _frontAvg = null; });
      return;
    }

    final frontAvg = (lf + rf) / 2;
    final rearAvg = (lr + rr) / 2;
    final rake = rearAvg - frontAvg;

    setState(() {
      _frontAvg = frontAvg;
      _rearAvg = rearAvg;
      _rake = rake;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lfController.clear();
    _rfController.clear();
    _lrController.clear();
    _rrController.clear();
    setState(() { _frontAvg = null; });
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
        title: Text('Ride Height', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Left Front', unit: 'in', hint: 'LF height', controller: _lfController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Right Front', unit: 'in', hint: 'RF height', controller: _rfController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Left Rear', unit: 'in', hint: 'LR height', controller: _lrController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Right Rear', unit: 'in', hint: 'RR height', controller: _rrController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_frontAvg != null) _buildResultsCard(colors),
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
        Text('Rake = Rear Avg - Front Avg', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Measure from fender to ground or control arm to ground', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final lf = double.tryParse(_lfController.text) ?? 0;
    final rf = double.tryParse(_rfController.text) ?? 0;
    final lr = double.tryParse(_lrController.text) ?? 0;
    final rr = double.tryParse(_rrController.text) ?? 0;
    final lfRfDiff = (lf - rf).abs();
    final lrRrDiff = (lr - rr).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(children: [
            Text('FRONT AVG', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            Text('${_frontAvg!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          ])),
          Expanded(child: Column(children: [
            Text('REAR AVG', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            Text('${_rearAvg!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Rake', '${_rake! >= 0 ? '+' : ''}${_rake!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Front Side Diff', '${lfRfDiff.toStringAsFixed(2)}"'),
        _buildResultRow(colors, 'Rear Side Diff', '${lrRrDiff.toStringAsFixed(2)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            _rake! > 0.5 ? 'Positive rake - rear higher, aids rear grip' : (_rake! < -0.25 ? 'Negative rake - unusual, check rear springs' : 'Near level - balanced aerodynamics'),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ]),
    );
  }
}
