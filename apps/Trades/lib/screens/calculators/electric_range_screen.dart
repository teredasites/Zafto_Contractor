import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Electric Range Calculator - Design System v2.6
class ElectricRangeScreen extends ConsumerStatefulWidget {
  const ElectricRangeScreen({super.key});
  @override
  ConsumerState<ElectricRangeScreen> createState() => _ElectricRangeScreenState();
}

class _ElectricRangeScreenState extends ConsumerState<ElectricRangeScreen> {
  int _rangeCount = 1;
  double _rangeRatingKw = 12.0;

  static const Map<int, double> _columnC = {1: 8.0, 2: 11.0, 3: 14.0, 4: 17.0, 5: 20.0, 6: 21.0, 7: 22.0, 8: 23.0, 9: 24.0, 10: 25.0, 11: 26.0, 12: 27.0, 13: 28.0, 14: 29.0, 15: 30.0, 16: 31.0, 17: 32.0, 18: 33.0, 19: 34.0, 20: 35.0, 21: 36.0, 22: 37.0, 23: 38.0, 24: 39.0, 25: 40.0};
  static const Map<int, double> _columnAB = {1: 0.80, 2: 0.75, 3: 0.70, 4: 0.66, 5: 0.62, 6: 0.59, 7: 0.56, 8: 0.53, 9: 0.51, 10: 0.49, 11: 0.47, 12: 0.45};

  double get _demandLoadKw {
    if (_rangeCount <= 0) return 0;
    if (_rangeRatingKw <= 12) { final factor = _columnAB[_rangeCount.clamp(1, 12)] ?? 0.45; return _rangeCount * _rangeRatingKw * factor; }
    final baseKw = _columnC[_rangeCount.clamp(1, 25)] ?? (15 + (_rangeCount - 15) * 1.0);
    final kwOver12 = (_rangeRatingKw - 12).clamp(0, 100);
    return baseKw * (1.0 + (kwOver12 * 0.05));
  }

  double get _demandAmps240 => (_demandLoadKw * 1000) / 240;
  double get _demandAmps208 => (_demandLoadKw * 1000) / 208;
  int get _breakerSize240 => _getStandardBreakerSize(_demandAmps240.ceil());
  int _getStandardBreakerSize(int amps) { const sizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100]; for (final size in sizes) { if (size >= amps) return size; } return ((amps / 10).ceil() * 10); }
  String get _wireSize { final b = _breakerSize240; if (b <= 30) return '10 AWG'; if (b <= 40) return '8 AWG'; if (b <= 60) return '6 AWG'; if (b <= 80) return '4 AWG'; if (b <= 100) return '3 AWG'; return '2 AWG+'; }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Electric Range Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCountCard(colors),
          const SizedBox(height: 16),
          _buildRatingCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildCountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NUMBER OF RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _rangeCount > 1 ? () { HapticFeedback.selectionClick(); setState(() => _rangeCount--); } : null, icon: Icon(LucideIcons.minusCircle, color: _rangeCount > 1 ? colors.accentPrimary : colors.textTertiary, size: 32)),
          const SizedBox(width: 20),
          Text('$_rangeCount', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          IconButton(onPressed: _rangeCount < 25 ? () { HapticFeedback.selectionClick(); setState(() => _rangeCount++); } : null, icon: Icon(LucideIcons.plusCircle, color: _rangeCount < 25 ? colors.accentPrimary : colors.textTertiary, size: 32)),
        ]),
        Center(child: Text('household cooking appliance(s)', style: TextStyle(color: colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildRatingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NAMEPLATE RATING PER UNIT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [8.0, 10.0, 12.0, 14.0, 16.0, 18.0].map((kw) {
          final isSelected = _rangeRatingKw == kw;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _rangeRatingKw = kw); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${kw.toStringAsFixed(0)} kW', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_rangeRatingKw.toStringAsFixed(1)} kW', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _rangeRatingKw, min: 3.0, max: 27.0, divisions: 48, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _rangeRatingKw = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_demandLoadKw.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('kW Demand Load', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Connected Load', '${(_rangeCount * _rangeRatingKw).toStringAsFixed(1)} kW'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Demand @ 240V', '${_demandAmps240.toStringAsFixed(1)}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Demand @ 208V', '${_demandAmps208.toStringAsFixed(1)}A'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Breaker (240V)', '${_breakerSize240}A', highlight: true),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Wire Size (Cu)', _wireSize),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC TABLE 220.55 COLUMN C', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('Max demand (kW) for ranges over 12kW through 27kW', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        Wrap(spacing: 4, runSpacing: 4, children: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) {
          final demand = _columnC[n] ?? 0;
          final isHighlighted = n == _rangeCount;
          return Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase, borderRadius: BorderRadius.circular(6), border: isHighlighted ? Border.all(color: colors.accentPrimary) : null),
            child: Column(children: [
              Text('$n', style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${demand.toStringAsFixed(0)}kW', style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textTertiary, fontSize: 10)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 220.55', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Table 220.55 - Demand factors for ranges\n• Note 1: Add 5% for each kW over 12kW\n• Note 2: kVA = kW for resistive loads\n• 210.19(A)(3) - Min 40A for ranges', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
