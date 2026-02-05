import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Dryer Circuit Calculator - Design System v2.6
class DryerCircuitScreen extends ConsumerStatefulWidget {
  const DryerCircuitScreen({super.key});
  @override
  ConsumerState<DryerCircuitScreen> createState() => _DryerCircuitScreenState();
}

class _DryerCircuitScreenState extends ConsumerState<DryerCircuitScreen> {
  int _dryerCount = 1;
  double _dryerWatts = 5000;
  int _voltage = 240;

  static const List<int> _voltageOptions = [208, 240];

  double get _demandFactor { if (_dryerCount <= 4) return 1.0; if (_dryerCount == 5) return 0.80; if (_dryerCount == 6) return 0.70; if (_dryerCount == 7) return 0.65; if (_dryerCount == 8) return 0.60; if (_dryerCount == 9) return 0.55; return 0.50; }
  double get _minLoadPerDryer => _dryerWatts < 5000 ? 5000 : _dryerWatts;
  double get _demandLoadW => _dryerCount == 1 ? _minLoadPerDryer : _dryerCount * _minLoadPerDryer * _demandFactor;
  double get _loadAmps => _demandLoadW / _voltage;
  int get _breakerSize { if (_dryerCount == 1 && _dryerWatts <= 5400) return 30; final amps = (_loadAmps * 1.25).ceil(); const sizes = [30, 40, 50, 60, 70, 80, 100, 125, 150]; for (final size in sizes) { if (size >= amps) return size; } return 200; }
  String get _wireSize { final b = _breakerSize; if (b <= 30) return '10 AWG'; if (b <= 40) return '8 AWG'; if (b <= 55) return '6 AWG'; if (b <= 70) return '4 AWG'; if (b <= 85) return '3 AWG'; if (b <= 100) return '2 AWG'; return '1/0 AWG+'; }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dryer Circuit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCountCard(colors),
          const SizedBox(height: 16),
          _buildRatingCard(colors),
          const SizedBox(height: 16),
          _buildVoltageCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
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
      child: Column(children: [
        Text('NUMBER OF DRYERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _dryerCount > 1 ? () { HapticFeedback.selectionClick(); setState(() => _dryerCount--); } : null, icon: Icon(LucideIcons.minusCircle, color: _dryerCount > 1 ? colors.accentPrimary : colors.textTertiary, size: 32)),
          const SizedBox(width: 20),
          Text('$_dryerCount', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          const SizedBox(width: 20),
          IconButton(onPressed: _dryerCount < 15 ? () { HapticFeedback.selectionClick(); setState(() => _dryerCount++); } : null, icon: Icon(LucideIcons.plusCircle, color: _dryerCount < 15 ? colors.accentPrimary : colors.textTertiary, size: 32)),
        ]),
        if (_dryerCount > 4) Text('Demand factor: ${(_demandFactor * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.accentPrimary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildRatingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DRYER NAMEPLATE (WATTS)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [4500.0, 5000.0, 5400.0, 5800.0, 6000.0].map((w) {
          final isSelected = _dryerWatts == w;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _dryerWatts = w); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${w.toStringAsFixed(0)}W', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text('NEC minimum: 5000W per dryer', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildVoltageCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VOLTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(children: _voltageOptions.map((v) {
          final isSelected = _voltage == v;
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _voltage = v); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          ));
        }).toList()),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_breakerSize}A', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('Circuit Breaker', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildRow(colors, 'Demand Load', '${(_demandLoadW / 1000).toStringAsFixed(1)} kW'),
            const SizedBox(height: 10),
            _buildRow(colors, 'Load Current', '${_loadAmps.toStringAsFixed(1)}A'),
            const SizedBox(height: 10),
            _buildRow(colors, 'Wire Size (Cu)', _wireSize, highlight: true),
            const SizedBox(height: 10),
            _buildRow(colors, 'Receptacle', _dryerCount == 1 ? 'NEMA 14-30R' : 'Hardwired'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 220.54', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Min 5000W or nameplate (larger)\n• Demand factors for 5+ units\n• 30A circuit standard for single dryer\n• 4-wire required for new installations', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
