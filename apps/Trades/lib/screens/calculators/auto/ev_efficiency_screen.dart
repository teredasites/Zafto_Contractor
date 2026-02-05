import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// EV Efficiency Calculator - Miles per kWh
class EvEfficiencyScreen extends ConsumerStatefulWidget {
  const EvEfficiencyScreen({super.key});
  @override
  ConsumerState<EvEfficiencyScreen> createState() => _EvEfficiencyScreenState();
}

class _EvEfficiencyScreenState extends ConsumerState<EvEfficiencyScreen> {
  final _distanceController = TextEditingController();
  final _energyUsedController = TextEditingController();
  final _electricityRateController = TextEditingController(text: '0.12');

  double? _milesPerKwh;
  double? _whPerMile;
  double? _mpge;
  double? _costPerMile;

  void _calculate() {
    final distance = double.tryParse(_distanceController.text);
    final energyUsed = double.tryParse(_energyUsedController.text);
    final rate = double.tryParse(_electricityRateController.text) ?? 0.12;

    if (distance == null || energyUsed == null || energyUsed <= 0) {
      setState(() { _milesPerKwh = null; });
      return;
    }

    final milesPerKwh = distance / energyUsed;
    final whPerMile = (energyUsed * 1000) / distance;
    // MPGe: 33.7 kWh = 1 gallon of gas equivalent
    final mpge = milesPerKwh * 33.7;
    final costPerMile = rate / milesPerKwh;

    setState(() {
      _milesPerKwh = milesPerKwh;
      _whPerMile = whPerMile;
      _mpge = mpge;
      _costPerMile = costPerMile;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _distanceController.clear();
    _energyUsedController.clear();
    _electricityRateController.text = '0.12';
    setState(() { _milesPerKwh = null; });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _energyUsedController.dispose();
    _electricityRateController.dispose();
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
        title: Text('EV Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Distance Traveled', unit: 'miles', hint: 'Trip or total', controller: _distanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Energy Used', unit: 'kWh', hint: 'From dash or charger', controller: _energyUsedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Electricity Rate', unit: '\$/kWh', hint: 'For cost calc', controller: _electricityRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_milesPerKwh != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildEfficiencyTips(colors),
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
        Text('Efficiency = Miles / kWh', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('MPGe = (mi/kWh) × 33.7', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String rating;
    Color ratingColor;

    if (_milesPerKwh! >= 4.0) {
      rating = 'Excellent efficiency';
      ratingColor = colors.accentSuccess;
    } else if (_milesPerKwh! >= 3.5) {
      rating = 'Good efficiency';
      ratingColor = colors.accentSuccess;
    } else if (_milesPerKwh! >= 3.0) {
      rating = 'Average efficiency';
      ratingColor = colors.accentPrimary;
    } else if (_milesPerKwh! >= 2.5) {
      rating = 'Below average';
      ratingColor = colors.warning;
    } else {
      rating = 'Poor efficiency';
      ratingColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: ratingColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('EV EFFICIENCY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_milesPerKwh!.toStringAsFixed(2)} mi/kWh', style: TextStyle(color: ratingColor, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildMetricBox(colors, 'Wh/mi', '${_whPerMile!.toStringAsFixed(0)}')),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricBox(colors, 'MPGe', '${_mpge!.toStringAsFixed(0)}')),
        ]),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cost Per Mile', '\$${_costPerMile!.toStringAsFixed(3)}'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: ratingColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(rating, style: TextStyle(color: ratingColor, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildMetricBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildEfficiencyTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IMPROVE EFFICIENCY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Moderate speeds (55-65 mph optimal)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Gentle acceleration', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Maximize regenerative braking', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Pre-condition while plugged in', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check tire pressure', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Use eco mode', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
