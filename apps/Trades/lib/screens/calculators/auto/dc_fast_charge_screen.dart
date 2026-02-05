import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// DC Fast Charge Calculator - Calculate DC fast charging time and cost
class DcFastChargeScreen extends ConsumerStatefulWidget {
  const DcFastChargeScreen({super.key});
  @override
  ConsumerState<DcFastChargeScreen> createState() => _DcFastChargeScreenState();
}

class _DcFastChargeScreenState extends ConsumerState<DcFastChargeScreen> {
  final _batteryCapacityController = TextEditingController();
  final _currentSocController = TextEditingController();
  final _targetSocController = TextEditingController();
  final _chargerPowerController = TextEditingController();
  final _priceController = TextEditingController();

  double? _chargeTime;
  double? _energyAdded;
  double? _cost;

  void _calculate() {
    final batteryCapacity = double.tryParse(_batteryCapacityController.text);
    final currentSoc = double.tryParse(_currentSocController.text);
    final targetSoc = double.tryParse(_targetSocController.text) ?? 80;
    final chargerPower = double.tryParse(_chargerPowerController.text);
    final price = double.tryParse(_priceController.text);

    if (batteryCapacity == null || currentSoc == null || chargerPower == null) {
      setState(() { _chargeTime = null; });
      return;
    }

    // Energy to add
    final energyNeeded = batteryCapacity * ((targetSoc - currentSoc) / 100);

    // Charging time (accounting for taper above 80%)
    double chargeTime;
    if (targetSoc <= 80) {
      chargeTime = (energyNeeded / chargerPower) * 60; // minutes
    } else {
      // Linear charging to 80%, then slower
      final energyTo80 = batteryCapacity * ((80 - currentSoc).clamp(0, 80) / 100);
      final energyAbove80 = batteryCapacity * ((targetSoc - 80).clamp(0, 20) / 100);
      final timeTo80 = energyTo80 / chargerPower;
      final timeAbove80 = energyAbove80 / (chargerPower * 0.3); // Assumes 30% power above 80%
      chargeTime = (timeTo80 + timeAbove80) * 60;
    }

    // Cost calculation
    double? cost;
    if (price != null) {
      cost = energyNeeded * price;
    }

    setState(() {
      _chargeTime = chargeTime;
      _energyAdded = energyNeeded;
      _cost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryCapacityController.clear();
    _currentSocController.clear();
    _targetSocController.clear();
    _chargerPowerController.clear();
    _priceController.clear();
    setState(() { _chargeTime = null; });
  }

  @override
  void dispose() {
    _batteryCapacityController.dispose();
    _currentSocController.dispose();
    _targetSocController.dispose();
    _chargerPowerController.dispose();
    _priceController.dispose();
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
        title: Text('DC Fast Charge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Battery Capacity', unit: 'kWh', hint: 'e.g., 75', controller: _batteryCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Current SOC', unit: '%', hint: 'e.g., 20', controller: _currentSocController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target SOC', unit: '%', hint: '80 optimal', controller: _targetSocController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Charger Power', unit: 'kW', hint: 'e.g., 150', controller: _chargerPowerController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Price (opt)', unit: '\$/kWh', hint: '0.40', controller: _priceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_chargeTime != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildChargerTypes(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Icon(LucideIcons.zapOff, color: colors.accentPrimary, size: 32),
        const SizedBox(height: 8),
        Text('DC Fast Charging Calculator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate charging time at DC fast chargers (DCFC)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CHARGE SESSION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${_chargeTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('Estimated Time', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildStatBox(colors, 'Energy Added', '${_energyAdded!.toStringAsFixed(1)} kWh')),
          if (_cost != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox(colors, 'Est. Cost', '\$${_cost!.toStringAsFixed(2)}')),
          ],
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Charging above 80% is significantly slower. Stop at 80% for fastest trips.', style: TextStyle(color: colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildChargerTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DC CHARGER TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildChargerRow(colors, 'CHAdeMO', '50-100 kW', 'Nissan, older EVs'),
        _buildChargerRow(colors, 'CCS', '50-350 kW', 'Most new EVs'),
        _buildChargerRow(colors, 'Tesla Supercharger', '72-250 kW', 'Tesla (NACS)'),
        _buildChargerRow(colors, 'NACS/Tesla', 'Up to 250 kW', 'New standard 2024+'),
        const SizedBox(height: 8),
        Text('Actual charge rate depends on battery temp, SOC, and vehicle limits', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildChargerRow(ZaftoColors colors, String type, String power, String vehicles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(flex: 2, child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(power, style: TextStyle(color: colors.accentPrimary, fontSize: 12))),
        Expanded(flex: 2, child: Text(vehicles, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }
}
