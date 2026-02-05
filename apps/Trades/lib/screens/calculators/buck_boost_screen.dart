import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Buck-Boost Calculator - Design System v2.6
/// Voltage correction transformer sizing
class BuckBoostScreen extends ConsumerStatefulWidget {
  const BuckBoostScreen({super.key});
  @override
  ConsumerState<BuckBoostScreen> createState() => _BuckBoostScreenState();
}

class _BuckBoostScreenState extends ConsumerState<BuckBoostScreen> {
  double _supplyVoltage = 208;
  double _desiredVoltage = 230;
  double _loadKva = 10;
  bool _isBuck = false; // false = boost, true = buck

  double? _voltageChange;
  double? _percentChange;
  double? _transformerKva;
  String? _connection;
  String? _recommendation;

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
        title: Text('Buck-Boost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VOLTAGE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Supply Voltage', value: _supplyVoltage, min: 180, max: 520, unit: 'V', onChanged: (v) { setState(() => _supplyVoltage = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Desired Voltage', value: _desiredVoltage, min: 180, max: 520, unit: 'V', onChanged: (v) { setState(() => _desiredVoltage = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Load', value: _loadKva, min: 1, max: 500, unit: ' kVA', onChanged: (v) { setState(() => _loadKva = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BUCK-BOOST SIZING'),
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
        Expanded(child: Text('Autotransformer for ±5-20% voltage correction', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
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

  Widget _buildResultCard(ZaftoColors colors) {
    final isBuck = _supplyVoltage > _desiredVoltage;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: isBuck ? colors.warning.withValues(alpha: 0.1) : colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(isBuck ? 'BUCK (Step Down)' : 'BOOST (Step Up)', style: TextStyle(color: isBuck ? colors.warning : colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(height: 20),
        Text('${_transformerKva?.toStringAsFixed(2) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('kVA buck-boost', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Supply voltage', '${_supplyVoltage.toStringAsFixed(0)} V'),
        _buildCalcRow(colors, 'Desired voltage', '${_desiredVoltage.toStringAsFixed(0)} V'),
        _buildCalcRow(colors, 'Voltage change', '${_voltageChange?.toStringAsFixed(0) ?? '0'} V'),
        _buildCalcRow(colors, 'Percent change', '${_percentChange?.toStringAsFixed(1) ?? '0'}%'),
        _buildCalcRow(colors, 'Load', '${_loadKva.toStringAsFixed(1)} kVA'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Buck-boost kVA', '${_transformerKva?.toStringAsFixed(2) ?? '0'} kVA', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('Connection', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(_connection ?? 'Series aiding (boost)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text(_recommendation ?? '', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final voltChange = (_desiredVoltage - _supplyVoltage).abs();
    final pctChange = (voltChange / _supplyVoltage) * 100;

    // Buck-boost kVA = Load kVA × (% voltage change / 100)
    // This is because it only transforms the difference, not the full load
    final bbKva = _loadKva * (pctChange / 100);

    // Determine connection type
    String conn;
    String rec;
    final isBuck = _supplyVoltage > _desiredVoltage;

    if (isBuck) {
      conn = 'Series opposing (buck)';
    } else {
      conn = 'Series aiding (boost)';
    }

    // Check if within typical buck-boost range
    if (pctChange > 20) {
      rec = 'Warning: >20% change may require isolation transformer instead';
    } else if (pctChange < 5) {
      rec = 'Tip: Consider if voltage drop is the actual issue';
    } else {
      rec = 'Standard buck-boost application';
    }

    setState(() {
      _voltageChange = voltChange;
      _percentChange = pctChange;
      _transformerKva = bbKva;
      _isBuck = isBuck;
      _connection = conn;
      _recommendation = rec;
    });
  }

  void _reset() {
    setState(() {
      _supplyVoltage = 208;
      _desiredVoltage = 230;
      _loadKva = 10;
    });
    _calculate();
  }
}
