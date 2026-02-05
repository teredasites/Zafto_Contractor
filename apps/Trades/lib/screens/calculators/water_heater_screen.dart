import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Water Heater Calculator - Design System v2.6
class WaterHeaterScreen extends ConsumerStatefulWidget {
  const WaterHeaterScreen({super.key});
  @override
  ConsumerState<WaterHeaterScreen> createState() => _WaterHeaterScreenState();
}

class _WaterHeaterScreenState extends ConsumerState<WaterHeaterScreen> {
  bool _isTankless = false;
  double _watts = 4500;
  int _voltage = 240;

  static const List<double> _tankWattages = [3000, 3800, 4500, 5500, 6000];
  static const List<double> _tanklessWattages = [11000, 13000, 18000, 24000, 27000, 36000];
  static const List<int> _voltageOptions = [208, 240];

  double get _amps => _watts / _voltage;
  int get _breakerSize { final minAmps = _isTankless ? _amps : (_amps * 1.25); return _getStandardBreakerSize(minAmps.ceil()); }
  int _getStandardBreakerSize(int amps) { const sizes = [15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100, 125, 150, 175, 200]; for (final size in sizes) { if (size >= amps) return size; } return ((amps / 50).ceil() * 50); }
  String get _wireSize { final b = _breakerSize; if (b <= 20) return '12 AWG'; if (b <= 30) return '10 AWG'; if (b <= 40) return '8 AWG'; if (b <= 55) return '6 AWG'; if (b <= 70) return '4 AWG'; if (b <= 85) return '3 AWG'; if (b <= 100) return '2 AWG'; if (b <= 115) return '1 AWG'; if (b <= 130) return '1/0 AWG'; if (b <= 150) return '2/0 AWG'; return '3/0+ AWG'; }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Water Heater', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTypeSelector(colors),
          const SizedBox(height: 16),
          _buildWattageCard(colors),
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEATER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() { _isTankless = false; _watts = 4500; }); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: !_isTankless ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase, borderRadius: BorderRadius.circular(10), border: Border.all(color: !_isTankless ? colors.accentPrimary : colors.borderSubtle)),
              child: Column(children: [
                Icon(LucideIcons.droplet, color: !_isTankless ? colors.accentPrimary : colors.textSecondary, size: 28),
                const SizedBox(height: 8),
                Text('Tank', style: TextStyle(color: !_isTankless ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('3-6 kW typical', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() { _isTankless = true; _watts = 18000; }); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: _isTankless ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase, borderRadius: BorderRadius.circular(10), border: Border.all(color: _isTankless ? colors.accentPrimary : colors.borderSubtle)),
              child: Column(children: [
                Icon(LucideIcons.zap, color: _isTankless ? colors.accentPrimary : colors.textSecondary, size: 28),
                const SizedBox(height: 8),
                Text('Tankless', style: TextStyle(color: _isTankless ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('11-36 kW typical', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _buildWattageCard(ZaftoColors colors) {
    final wattages = _isTankless ? _tanklessWattages : _tankWattages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NAMEPLATE WATTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: wattages.map((w) {
          final isSelected = _watts == w;
          final label = w >= 1000 ? '${(w/1000).toStringAsFixed(0)}kW' : '${w.toStringAsFixed(0)}W';
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _watts = w); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          );
        }).toList()),
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
            _buildRow(colors, 'Load', '${(_watts/1000).toStringAsFixed(1)} kW'),
            const SizedBox(height: 10),
            _buildRow(colors, 'Current Draw', '${_amps.toStringAsFixed(1)}A'),
            const SizedBox(height: 10),
            _buildRow(colors, 'Wire Size (Cu 75°C)', _wireSize, highlight: true),
            const SizedBox(height: 10),
            _buildRow(colors, 'Connection', 'Hardwired'),
          ]),
        ),
        if (_isTankless) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3))),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Tankless heaters may require service upgrade', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 422.11 / 422.13', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Storage heaters >120gal = 125%\n• Individual branch circuit required\n• Disconnect within sight or lockable\n• GFCI not required (240V hardwired)', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
