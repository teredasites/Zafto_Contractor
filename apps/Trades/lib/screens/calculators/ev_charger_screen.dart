import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// EV Charger Load Calculator - Design System v2.6
class EvChargerScreen extends ConsumerStatefulWidget {
  const EvChargerScreen({super.key});
  @override
  ConsumerState<EvChargerScreen> createState() => _EvChargerScreenState();
}

class _EvChargerScreenState extends ConsumerState<EvChargerScreen> {
  int _selectedLevel = 1;
  int _selectedAmperage = 32;
  int _selectedVoltage = 240;
  int _numberOfChargers = 1;
  bool _isContinuousLoad = true;
  int _dcPowerKw = 50;

  static const List<int> _level2Amperages = [16, 20, 24, 30, 32, 40, 48, 50, 60, 80];
  static const List<int> _voltages = [208, 240];
  static const List<int> _dcPowerOptions = [25, 50, 100, 150, 250, 350];
  static const int _level1Voltage = 120;
  static const int _level1Amps = 12;

  double get _chargerKw {
    switch (_selectedLevel) {
      case 0: return (_level1Voltage * _level1Amps) / 1000;
      case 1: return (_selectedVoltage * _selectedAmperage) / 1000;
      case 2: return _dcPowerKw.toDouble();
      default: return 0;
    }
  }

  double get _totalKw => _chargerKw * _numberOfChargers;
  int get _circuitAmps { if (_selectedLevel == 0) return _level1Amps; if (_selectedLevel == 1) return _selectedAmperage; return ((_dcPowerKw * 1000) / (480 * 1.732)).round(); }
  int get _requiredBreakerSize { final amps = _isContinuousLoad ? (_circuitAmps * 1.25).ceil() : _circuitAmps; return _getStandardBreakerSize(amps); }
  int _getStandardBreakerSize(int amps) { const standardSizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200]; for (final size in standardSizes) { if (size >= amps) return size; } return ((amps / 50).ceil() * 50); }
  String get _wireSize { final breaker = _requiredBreakerSize; if (breaker <= 15) return '14 AWG'; if (breaker <= 20) return '12 AWG'; if (breaker <= 30) return '10 AWG'; if (breaker <= 40) return '8 AWG'; if (breaker <= 55) return '6 AWG'; if (breaker <= 70) return '4 AWG'; if (breaker <= 85) return '3 AWG'; if (breaker <= 95) return '2 AWG'; if (breaker <= 115) return '1 AWG'; if (breaker <= 130) return '1/0 AWG'; if (breaker <= 150) return '2/0 AWG'; if (breaker <= 175) return '3/0 AWG'; if (breaker <= 200) return '4/0 AWG'; return '250+ kcmil'; }
  String get _conduitSize { final breaker = _requiredBreakerSize; if (breaker <= 20) return '1/2"'; if (breaker <= 40) return '3/4"'; if (breaker <= 60) return '1"'; if (breaker <= 100) return '1-1/4"'; if (breaker <= 150) return '1-1/2"'; return '2"+'; }
  String get _circuitType { if (_selectedLevel == 0) return '120V Single Phase'; if (_selectedLevel == 1) return '${_selectedVoltage}V Single Phase'; return '480V 3-Phase'; }
  String get _milesPerHour => '${(_chargerKw * 3.5).round()} mi/hr';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('EV Charger Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLevelSelector(colors),
          const SizedBox(height: 20),
          if (_selectedLevel == 1) _buildLevel2Config(colors),
          if (_selectedLevel == 2) _buildDcFastConfig(colors),
          const SizedBox(height: 12),
          _buildNumberOfChargers(colors),
          const SizedBox(height: 12),
          _buildContinuousLoadToggle(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildLevelSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CHARGER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      Row(children: [
        _buildLevelOption(colors, 0, 'Level 1', '120V / 12A', '1.4 kW'),
        const SizedBox(width: 8),
        _buildLevelOption(colors, 1, 'Level 2', '240V / 32A+', '7.7+ kW'),
        const SizedBox(width: 8),
        _buildLevelOption(colors, 2, 'DC Fast', '480V 3Ø', '50+ kW'),
      ]),
    ]);
  }

  Widget _buildLevelOption(ZaftoColors colors, int level, String title, String subtitle, String power) {
    final isSelected = _selectedLevel == level;
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedLevel = level); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: isSelected ? colors.accentSuccess.withValues(alpha: 0.15) : colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? colors.accentSuccess : colors.borderSubtle, width: isSelected ? 1.5 : 1)),
        child: Column(children: [
          Text(title, style: TextStyle(color: isSelected ? colors.accentSuccess : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(power, style: TextStyle(color: isSelected ? colors.accentSuccess : colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    ));
  }

  Widget _buildLevel2Config(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CHARGER AMPERAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _level2Amperages.map((amp) => _buildChip(colors, '${amp}A', _selectedAmperage == amp, () => setState(() => _selectedAmperage = amp))).toList()),
        const SizedBox(height: 16),
        Text('SUPPLY VOLTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(children: _voltages.map((v) => Padding(padding: const EdgeInsets.only(right: 8), child: _buildChip(colors, '${v}V', _selectedVoltage == v, () => setState(() => _selectedVoltage = v)))).toList()),
      ]),
    );
  }

  Widget _buildDcFastConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CHARGER POWER (kW)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _dcPowerOptions.map((kw) => _buildChip(colors, '$kw kW', _dcPowerKw == kw, () => setState(() => _dcPowerKw = kw))).toList()),
      ]),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentSuccess : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildNumberOfChargers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Number of Chargers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        Row(children: [
          IconButton(onPressed: _numberOfChargers > 1 ? () { HapticFeedback.selectionClick(); setState(() => _numberOfChargers--); } : null, icon: Icon(LucideIcons.minusCircle, color: _numberOfChargers > 1 ? colors.accentSuccess : colors.textTertiary)),
          Container(width: 40, alignment: Alignment.center, child: Text('$_numberOfChargers', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
          IconButton(onPressed: _numberOfChargers < 20 ? () { HapticFeedback.selectionClick(); setState(() => _numberOfChargers++); } : null, icon: Icon(LucideIcons.plusCircle, color: _numberOfChargers < 20 ? colors.accentSuccess : colors.textTertiary)),
        ]),
      ]),
    );
  }

  Widget _buildContinuousLoadToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Continuous Load (125%)', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('NEC 625.41 - EV charging is continuous', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        Switch(value: _isContinuousLoad, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _isContinuousLoad = v); }, activeColor: colors.accentSuccess),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.2))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_totalKw.toStringAsFixed(1)}', style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -2)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('kW', style: TextStyle(color: colors.accentSuccess, fontSize: 20, fontWeight: FontWeight.w500))),
        ]),
        Text('Total Connected Load', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        const SizedBox(height: 6),
        Text(_milesPerHour, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Circuit Type', _circuitType),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Charger Current', '${_circuitAmps}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Required Breaker', '${_requiredBreakerSize}A', highlight: true),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Wire Size (Cu 75°C)', _wireSize),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Conduit (EMT)', _conduitSize),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentSuccess : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC Article 625', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 625.41 - Branch circuits shall be sized for continuous load (125%)\n• 625.42 - Overcurrent protection per branch circuit ampacity\n• 625.44 - Equipment grounding conductor required', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
