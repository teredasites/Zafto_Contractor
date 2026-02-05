import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Solar / PV System Calculator - Design System v2.6
class SolarPvScreen extends ConsumerStatefulWidget {
  const SolarPvScreen({super.key});
  @override
  ConsumerState<SolarPvScreen> createState() => _SolarPvScreenState();
}

class _SolarPvScreenState extends ConsumerState<SolarPvScreen> {
  final _monthlyKwhController = TextEditingController(text: '1000');
  double _sunHours = 4.2;
  double _systemLosses = 0.14;
  int _panelWatts = 400;
  int _systemVoltage = 240;
  String _selectedRegion = 'Northeast';

  static const List<int> _voltageOptions = [120, 208, 240, 480];
  static const List<int> _panelWattOptions = [300, 350, 400, 450, 500, 550];
  static const Map<String, double> _regionSunHours = {'Southwest': 6.5, 'California': 5.8, 'Texas/Florida': 5.5, 'Midwest': 4.5, 'Northeast': 4.2, 'Pacific NW': 3.8, 'Alaska': 3.0};

  double get _monthlyKwh => double.tryParse(_monthlyKwhController.text) ?? 0;
  double get _dailyKwh => _monthlyKwh / 30;
  double get _systemSizeKw => _sunHours <= 0 ? 0 : _dailyKwh / (_sunHours * (1 - _systemLosses));
  int get _panelCount => _panelWatts <= 0 ? 0 : (_systemSizeKw * 1000 / _panelWatts).ceil();
  double get _actualSystemKw => (_panelCount * _panelWatts) / 1000;
  double get _inverterSizeKw => _actualSystemKw * 1.1;
  double get _systemAmps => _systemVoltage <= 0 ? 0 : (_inverterSizeKw * 1000) / _systemVoltage;
  int get _breakerSize => _getStandardBreakerSize((_systemAmps * 1.25).ceil());
  double get _annualProduction => _actualSystemKw * _sunHours * 365 * (1 - _systemLosses);
  double get _offsetPercent => _monthlyKwh > 0 ? ((_annualProduction / 12) / _monthlyKwh * 100).clamp(0, 150) : 0;

  int _getStandardBreakerSize(int amps) { const sizes = [15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100, 125, 150, 175, 200]; for (final size in sizes) { if (size >= amps) return size; } return ((amps / 50).ceil() * 50); }
  String get _wireSize { final breaker = _breakerSize; if (breaker <= 15) return '14 AWG'; if (breaker <= 20) return '12 AWG'; if (breaker <= 30) return '10 AWG'; if (breaker <= 40) return '8 AWG'; if (breaker <= 55) return '6 AWG'; if (breaker <= 70) return '4 AWG'; if (breaker <= 85) return '3 AWG'; if (breaker <= 100) return '2 AWG'; if (breaker <= 115) return '1 AWG'; if (breaker <= 130) return '1/0 AWG'; if (breaker <= 150) return '2/0 AWG'; return '3/0+ AWG'; }

  @override
  void dispose() { _monthlyKwhController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Solar / PV System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
          const SizedBox(height: 16),
          _buildConfigCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildElectricalCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MONTHLY ENERGY USAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: _monthlyKwhController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: '0', hintStyle: TextStyle(color: colors.textTertiary), suffixText: 'kWh/month', suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 14), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        ),
        const SizedBox(height: 8),
        Text('Find this on your electric bill', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildLocationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOCATION (PEAK SUN HOURS)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _regionSunHours.entries.map((entry) {
          final isSelected = _selectedRegion == entry.key;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedRegion = entry.key; _sunHours = entry.value; }); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? colors.accentWarning : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text(entry.key, style: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('${entry.value}h', style: TextStyle(color: isSelected ? Colors.black54 : colors.textTertiary, fontSize: 10)),
              ]),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildConfigCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PANEL WATTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _panelWattOptions.map((w) {
          final isSelected = _panelWatts == w;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _panelWatts = w); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentWarning : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${w}W', style: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          );
        }).toList()),
        const SizedBox(height: 16),
        Text('AC SYSTEM VOLTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(children: _voltageOptions.map((v) {
          final isSelected = _systemVoltage == v;
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _systemVoltage = v); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentWarning : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${v}V', style: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          ));
        }).toList()),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.2))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$_panelCount', style: TextStyle(color: colors.accentWarning, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(' panels', style: TextStyle(color: colors.accentWarning, fontSize: 18, fontWeight: FontWeight.w500))),
        ]),
        Text('${_actualSystemKw.toStringAsFixed(1)} kW system', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Inverter Size', '${_inverterSizeKw.toStringAsFixed(1)} kW'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Annual Production', '${(_annualProduction / 1000).toStringAsFixed(1)} MWh'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Usage Offset', '${_offsetPercent.toStringAsFixed(0)}%', highlight: _offsetPercent >= 100),
          ]),
        ),
      ]),
    );
  }

  Widget _buildElectricalCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ELECTRICAL REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'AC Output Current', '${_systemAmps.toStringAsFixed(1)}A'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Required Breaker', '${_breakerSize}A', highlight: true),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Wire Size (Cu 75°C)', _wireSize),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'System Voltage', '${_systemVoltage}V'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentWarning : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC Article 690', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 690.8 - Circuit sizing based on max current\n• 690.9 - OCPD requirements for PV circuits\n• 690.12 - Rapid shutdown requirements\n• 690.41 - System grounding requirements', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
