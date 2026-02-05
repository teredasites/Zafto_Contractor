import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// EV Charging Time Calculator - Time to charge estimation
class ChargingTimeScreen extends ConsumerStatefulWidget {
  const ChargingTimeScreen({super.key});
  @override
  ConsumerState<ChargingTimeScreen> createState() => _ChargingTimeScreenState();
}

class _ChargingTimeScreenState extends ConsumerState<ChargingTimeScreen> {
  final _batteryCapacityController = TextEditingController();
  final _currentSocController = TextEditingController(text: '20');
  final _targetSocController = TextEditingController(text: '80');
  final _chargerPowerController = TextEditingController();

  double? _chargingTime;
  double? _energyNeeded;

  void _calculate() {
    final batteryCapacity = double.tryParse(_batteryCapacityController.text);
    final currentSoc = double.tryParse(_currentSocController.text) ?? 20;
    final targetSoc = double.tryParse(_targetSocController.text) ?? 80;
    final chargerPower = double.tryParse(_chargerPowerController.text);

    if (batteryCapacity == null || chargerPower == null || chargerPower <= 0) {
      setState(() { _chargingTime = null; });
      return;
    }

    final energyNeeded = batteryCapacity * (targetSoc - currentSoc) / 100;
    // Account for ~90% charging efficiency
    final actualEnergy = energyNeeded / 0.9;
    final chargingTime = actualEnergy / chargerPower;

    setState(() {
      _chargingTime = chargingTime;
      _energyNeeded = energyNeeded;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryCapacityController.clear();
    _currentSocController.text = '20';
    _targetSocController.text = '80';
    _chargerPowerController.clear();
    setState(() { _chargingTime = null; });
  }

  @override
  void dispose() {
    _batteryCapacityController.dispose();
    _currentSocController.dispose();
    _targetSocController.dispose();
    _chargerPowerController.dispose();
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
        title: Text('Charging Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Battery Capacity', unit: 'kWh', hint: 'Total capacity', controller: _batteryCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Current SOC', unit: '%', hint: 'Starting', controller: _currentSocController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target SOC', unit: '%', hint: 'Ending', controller: _targetSocController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Charger Power', unit: 'kW', hint: 'Charging rate', controller: _chargerPowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_chargingTime != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildChargerReference(colors),
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
        Text('Time = Energy Needed / Charger Power', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate EV charging duration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final hours = _chargingTime!.floor();
    final minutes = ((_chargingTime! - hours) * 60).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CHARGING TIME', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${hours}h ${minutes}m', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Energy to Add', '${_energyNeeded!.toStringAsFixed(1)} kWh'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Actual time may vary based on battery temp, charger taper, and vehicle limits.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildChargerReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CHARGER TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildChargerRow(colors, 'Level 1 (120V)', '1.4-1.9 kW'),
        _buildChargerRow(colors, 'Level 2 (240V)', '3.3-19.2 kW'),
        _buildChargerRow(colors, 'DC Fast (50kW)', '50 kW'),
        _buildChargerRow(colors, 'DC Fast (150kW)', '150 kW'),
        _buildChargerRow(colors, 'DC Fast (350kW)', '350 kW'),
      ]),
    );
  }

  Widget _buildChargerRow(ZaftoColors colors, String type, String power) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(power, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
