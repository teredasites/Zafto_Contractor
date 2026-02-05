import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conduit Length Estimator - Design System v2.6
/// Calculates total conduit run from layout measurements
class ConduitLengthEstimatorScreen extends ConsumerStatefulWidget {
  const ConduitLengthEstimatorScreen({super.key});
  @override
  ConsumerState<ConduitLengthEstimatorScreen> createState() => _ConduitLengthEstimatorScreenState();
}

class _ConduitLengthEstimatorScreenState extends ConsumerState<ConduitLengthEstimatorScreen> {
  final _horizontalController = TextEditingController(text: '50');
  final _verticalController = TextEditingController(text: '12');
  final _dropsController = TextEditingController(text: '4');
  final _dropLengthController = TextEditingController(text: '8');
  int _num90Bends = 4;
  int _num45Bends = 2;
  int _couplings = 6;
  double _wastePercent = 10;

  double? _straightLength;
  double? _bendAllowance;
  double? _couplingAllowance;
  double? _subtotal;
  double? _waste;
  double? _totalLength;
  int? _sticks;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _dropsController.dispose();
    _dropLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Conduit Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RUN MEASUREMENTS'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Horizontal Run', _horizontalController, 'ft'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Vertical Run', _verticalController, 'ft'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInputRow(colors, 'Drops', _dropsController, '')),
                const SizedBox(width: 12),
                Expanded(child: _buildInputRow(colors, 'Drop Length', _dropLengthController, 'ft')),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FITTINGS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: '90° Bends', value: _num90Bends, min: 0, max: 20, unit: '', onChanged: (v) { setState(() => _num90Bends = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: '45° Bends', value: _num45Bends, min: 0, max: 20, unit: '', onChanged: (v) { setState(() => _num45Bends = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Couplings', value: _couplings, min: 0, max: 30, unit: '', onChanged: (v) { setState(() => _couplings = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Waste Factor', value: _wastePercent.round(), min: 0, max: 25, unit: '%', onChanged: (v) { setState(() => _wastePercent = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TOTAL CONDUIT NEEDED'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Estimates total conduit with bend allowances and waste', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildInputRow(ZaftoColors colors, String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              suffixText: unit,
              suffixStyle: TextStyle(color: colors.textTertiary),
            ),
            onChanged: (_) => _calculate(),
          ),
        ),
      ]),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required int value, required int min, required int max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('$value$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: max - min, onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_totalLength?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('feet total', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_sticks ?? 0} sticks (10 ft)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Straight runs', '${_straightLength?.toStringAsFixed(1) ?? '0'} ft'),
        _buildCalcRow(colors, 'Bend allowance (${_num90Bends}×90° + ${_num45Bends}×45°)', '${_bendAllowance?.toStringAsFixed(1) ?? '0'} ft'),
        _buildCalcRow(colors, 'Coupling allowance ($_couplings)', '${_couplingAllowance?.toStringAsFixed(1) ?? '0'} ft'),
        _buildCalcRow(colors, 'Subtotal', '${_subtotal?.toStringAsFixed(1) ?? '0'} ft'),
        _buildCalcRow(colors, 'Waste (${_wastePercent.round()}%)', '${_waste?.toStringAsFixed(1) ?? '0'} ft'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Total conduit', '${_totalLength?.toStringAsFixed(1) ?? '0'} ft', highlight: true),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13))),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final horizontal = double.tryParse(_horizontalController.text) ?? 0;
    final vertical = double.tryParse(_verticalController.text) ?? 0;
    final drops = double.tryParse(_dropsController.text) ?? 0;
    final dropLength = double.tryParse(_dropLengthController.text) ?? 0;

    // Straight run calculation
    final straight = horizontal + vertical + (drops * dropLength);

    // Bend allowance: ~6" per 90°, ~3" per 45° (typical for 3/4" EMT)
    final bendAllow = (_num90Bends * 0.5) + (_num45Bends * 0.25);

    // Coupling allowance: ~1" per coupling
    final couplingAllow = _couplings * (1 / 12);

    final sub = straight + bendAllow + couplingAllow;
    final wasteAmount = sub * (_wastePercent / 100);
    final total = sub + wasteAmount;

    // Calculate sticks (10 ft standard)
    final sticksNeeded = (total / 10).ceil();

    setState(() {
      _straightLength = straight;
      _bendAllowance = bendAllow;
      _couplingAllowance = couplingAllow;
      _subtotal = sub;
      _waste = wasteAmount;
      _totalLength = total;
      _sticks = sticksNeeded;
    });
  }

  void _reset() {
    _horizontalController.text = '50';
    _verticalController.text = '12';
    _dropsController.text = '4';
    _dropLengthController.text = '8';
    setState(() {
      _num90Bends = 4;
      _num45Bends = 2;
      _couplings = 6;
      _wastePercent = 10;
    });
    _calculate();
  }
}
