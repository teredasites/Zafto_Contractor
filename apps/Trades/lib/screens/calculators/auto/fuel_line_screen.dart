import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Line Sizing Calculator - Determine proper fuel line diameter
class FuelLineScreen extends ConsumerStatefulWidget {
  const FuelLineScreen({super.key});
  @override
  ConsumerState<FuelLineScreen> createState() => _FuelLineScreenState();
}

class _FuelLineScreenState extends ConsumerState<FuelLineScreen> {
  final _targetHpController = TextEditingController();
  final _bsfcController = TextEditingController(text: '0.55');

  String? _recommendedSize;
  double? _requiredFlowGph;

  void _calculate() {
    final targetHp = double.tryParse(_targetHpController.text);
    final bsfc = double.tryParse(_bsfcController.text) ?? 0.55;

    if (targetHp == null) {
      setState(() { _recommendedSize = null; });
      return;
    }

    final lbsPerHour = targetHp * bsfc;
    final gph = lbsPerHour / 6.0;

    String size;
    if (gph <= 50) {
      size = '5/16" (AN-5)';
    } else if (gph <= 80) {
      size = '3/8" (AN-6)';
    } else if (gph <= 150) {
      size = '1/2" (AN-8)';
    } else if (gph <= 250) {
      size = '5/8" (AN-10)';
    } else {
      size = '3/4" (AN-12) or dual lines';
    }

    setState(() {
      _requiredFlowGph = gph;
      _recommendedSize = size;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _targetHpController.clear();
    _bsfcController.text = '0.55';
    setState(() { _recommendedSize = null; });
  }

  @override
  void dispose() {
    _targetHpController.dispose();
    _bsfcController.dispose();
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
        title: Text('Fuel Line Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'At crank', controller: _targetHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'BSFC', unit: 'lb/hp/hr', hint: 'NA: 0.45-0.50, FI: 0.55-0.65', controller: _bsfcController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedSize != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildLineReferenceCard(colors),
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
        Text('Larger lines = less restriction', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Always size for feed AND return lines', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Required Flow', '${_requiredFlowGph!.toStringAsFixed(1)} GPH'),
        const SizedBox(height: 16),
        Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_recommendedSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Return line can be one size smaller than feed line.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildLineReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LINE SIZE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildLineRow(colors, '5/16" (AN-5)', '~300 HP'),
        _buildLineRow(colors, '3/8" (AN-6)', '~450 HP'),
        _buildLineRow(colors, '1/2" (AN-8)', '~700 HP'),
        _buildLineRow(colors, '5/8" (AN-10)', '~1000 HP'),
        _buildLineRow(colors, '3/4" (AN-12)', '~1500 HP'),
      ]),
    );
  }

  Widget _buildLineRow(ZaftoColors colors, String size, String support) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        Text('Supports $support', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
