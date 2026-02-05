import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Transformer Tap Settings Calculator - Design System v2.6
/// Determine correct tap position for voltage adjustment
class TransformerTapsScreen extends ConsumerStatefulWidget {
  const TransformerTapsScreen({super.key});
  @override
  ConsumerState<TransformerTapsScreen> createState() => _TransformerTapsScreenState();
}

class _TransformerTapsScreenState extends ConsumerState<TransformerTapsScreen> {
  double _primaryVoltage = 480;
  double _measuredSecondary = 215;
  double _desiredSecondary = 208;
  String _currentTap = 'nominal';

  double? _currentRatio;
  double? _requiredRatio;
  String? _recommendedTap;
  double? _expectedVoltage;
  double? _voltageError;

  final _tapPositions = [
    ('FCBN (Full Capacity Below Normal)', 'fcbn', 1.05),
    ('2.5% Below Normal', 'bn25', 1.025),
    ('Nominal', 'nominal', 1.0),
    ('2.5% Above Normal', 'an25', 0.975),
    ('FCAN (Full Capacity Above Normal)', 'fcan', 0.95),
  ];

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Transformer Taps', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VOLTAGES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Primary Voltage', value: _primaryVoltage, min: 208, max: 600, unit: 'V', onChanged: (v) { setState(() => _primaryVoltage = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Measured Secondary', value: _measuredSecondary, min: 100, max: 520, unit: 'V', onChanged: (v) { setState(() => _measuredSecondary = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Desired Secondary', value: _desiredSecondary, min: 100, max: 520, unit: 'V', onChanged: (v) { setState(() => _desiredSecondary = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CURRENT TAP'),
              const SizedBox(height: 12),
              _buildTapSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TAP RECOMMENDATION'),
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
        Expanded(child: Text('Adjust taps to correct secondary voltage', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildTapSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: _tapPositions.map((tap) {
          final isSelected = _currentTap == tap.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _currentTap = tap.$2); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
                ),
                child: Row(children: [
                  Icon(isSelected ? LucideIcons.checkCircle : LucideIcons.circle, color: isSelected ? colors.accentPrimary : colors.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tap.$1, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13))),
                  Text('${((tap.$3 - 1) * 100).toStringAsFixed(1)}%', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final isGoodMatch = (_voltageError ?? 100).abs() <= 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isGoodMatch ? colors.accentPrimary.withValues(alpha: 0.3) : colors.warning.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendedTap ?? 'Nominal', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(height: 20),
        Text('${_expectedVoltage?.toStringAsFixed(1) ?? '0'}V', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('expected secondary', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isGoodMatch ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGoodMatch ? colors.accentPrimary : colors.warning, size: 16),
          const SizedBox(width: 4),
          Text('${_voltageError?.toStringAsFixed(1) ?? '0'}% from target', style: TextStyle(color: isGoodMatch ? colors.accentPrimary : colors.warning, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Current tap', _getCurrentTapName()),
        _buildCalcRow(colors, 'Measured secondary', '${_measuredSecondary.toStringAsFixed(0)} V'),
        _buildCalcRow(colors, 'Desired secondary', '${_desiredSecondary.toStringAsFixed(0)} V'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Recommended tap', _recommendedTap ?? 'Nominal', highlight: true),
        _buildCalcRow(colors, 'Expected voltage', '${_expectedVoltage?.toStringAsFixed(1) ?? '0'} V', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TIP', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Move tap to higher % to DECREASE secondary voltage. Move tap to lower % to INCREASE secondary voltage.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  String _getCurrentTapName() {
    for (final tap in _tapPositions) {
      if (tap.$2 == _currentTap) return tap.$1;
    }
    return 'Nominal';
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Flexible(child: Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14), textAlign: TextAlign.right)),
      ]),
    );
  }

  void _calculate() {
    // Get current tap ratio
    double currentTapRatio = 1.0;
    for (final tap in _tapPositions) {
      if (tap.$2 == _currentTap) {
        currentTapRatio = tap.$3;
        break;
      }
    }

    // Calculate actual turns ratio based on measured values
    // Measured secondary = Primary / (turns ratio × tap)
    final effectiveRatio = _primaryVoltage / _measuredSecondary;

    // What ratio do we need for desired voltage?
    final desiredRatio = _primaryVoltage / _desiredSecondary;

    // Find best tap
    String bestTap = 'Nominal';
    double bestTapRatio = 1.0;
    double minError = double.infinity;

    for (final tap in _tapPositions) {
      // Expected voltage with this tap
      final expectedV = _measuredSecondary * (currentTapRatio / tap.$3);
      final error = (expectedV - _desiredSecondary).abs();

      if (error < minError) {
        minError = error;
        bestTap = tap.$1;
        bestTapRatio = tap.$3;
      }
    }

    final expectedVoltage = _measuredSecondary * (currentTapRatio / bestTapRatio);
    final voltageError = ((expectedVoltage - _desiredSecondary) / _desiredSecondary) * 100;

    setState(() {
      _currentRatio = effectiveRatio;
      _requiredRatio = desiredRatio;
      _recommendedTap = bestTap;
      _expectedVoltage = expectedVoltage;
      _voltageError = voltageError;
    });
  }

  void _reset() {
    setState(() {
      _primaryVoltage = 480;
      _measuredSecondary = 215;
      _desiredSecondary = 208;
      _currentTap = 'nominal';
    });
    _calculate();
  }
}
