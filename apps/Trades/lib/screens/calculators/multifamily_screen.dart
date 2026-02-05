import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Multifamily Calculator - Design System v2.6
/// NEC 220.84 - Apartment building load calculations
class MultifamilyScreen extends ConsumerStatefulWidget {
  const MultifamilyScreen({super.key});
  @override
  ConsumerState<MultifamilyScreen> createState() => _MultifamilyScreenState();
}

class _MultifamilyScreenState extends ConsumerState<MultifamilyScreen> {
  int _units = 10;
  final _sqFtPerUnitController = TextEditingController(text: '900');
  final _appliancesPerUnitController = TextEditingController(text: '9000');
  bool _hasElectricHeat = true;
  bool _hasElectricCooking = true;
  bool _hasElectricWaterHeater = true;

  double? _unitLoad;
  double? _totalConnected;
  double? _demandFactor;
  double? _demandLoad;
  double? _serviceAmps;
  int? _recommendedService;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _sqFtPerUnitController.dispose();
    _appliancesPerUnitController.dispose();
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
        title: Text('Multifamily', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Units', value: _units, min: 3, max: 100, unit: '', onChanged: (v) { setState(() => _units = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Sq Ft per Unit', _sqFtPerUnitController, 'sq ft'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Appliances per Unit', _appliancesPerUnitController, 'VA'),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ELECTRIC EQUIPMENT'),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Electric Heat', value: _hasElectricHeat, onChanged: (v) { setState(() => _hasElectricHeat = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Electric Cooking', value: _hasElectricCooking, onChanged: (v) { setState(() => _hasElectricCooking = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Electric Water Heater', value: _hasElectricWaterHeater, onChanged: (v) { setState(() => _hasElectricWaterHeater = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SERVICE CALCULATION'),
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
        Expanded(child: Text('NEC 220.84 - Optional calculation for multifamily', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

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

  Widget _buildInputRow(ZaftoColors colors, String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(isDense: true, border: InputBorder.none, suffixText: unit, suffixStyle: TextStyle(color: colors.textTertiary)),
            onChanged: (_) => _calculate(),
          ),
        ),
      ]),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        Switch(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_serviceAmps?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps calculated', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_recommendedService ?? 400}A Service', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Load per unit', '${_unitLoad?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Total connected ($_units units)', '${_totalConnected?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Demand factor', '${((_demandFactor ?? 1) * 100).toStringAsFixed(0)}%'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Demand load', '${_demandLoad?.toStringAsFixed(0) ?? '0'} VA', highlight: true),
        _buildCalcRow(colors, 'Service @ 208V 3Ø', '${_serviceAmps?.toStringAsFixed(0) ?? '0'} A', highlight: true),
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
    final sqFt = double.tryParse(_sqFtPerUnitController.text) ?? 0;
    final appliances = double.tryParse(_appliancesPerUnitController.text) ?? 0;

    // Per unit calculation
    // Lighting: 3 VA/sq ft
    final lighting = sqFt * 3;
    // Small appliance: 3000 VA (2 circuits @ 1500)
    const smallAppliance = 3000.0;
    // Laundry: 1500 VA
    const laundry = 1500.0;

    double unitTotal = lighting + smallAppliance + laundry + appliances;

    // Add for electric equipment
    if (_hasElectricHeat) unitTotal += 5000; // Typical heat
    if (_hasElectricCooking) unitTotal += 8000; // Range
    if (_hasElectricWaterHeater) unitTotal += 4500; // Water heater

    // Total connected
    final total = unitTotal * _units;

    // NEC 220.84 demand factors for multifamily
    double factor;
    if (_units <= 3) factor = 0.45;
    else if (_units <= 5) factor = 0.44;
    else if (_units <= 7) factor = 0.43;
    else if (_units <= 10) factor = 0.42;
    else if (_units <= 15) factor = 0.41;
    else if (_units <= 20) factor = 0.40;
    else if (_units <= 25) factor = 0.39;
    else if (_units <= 30) factor = 0.38;
    else if (_units <= 40) factor = 0.37;
    else if (_units <= 50) factor = 0.36;
    else if (_units <= 60) factor = 0.35;
    else factor = 0.34;

    final demand = total * factor;

    // Calculate amps at 208V 3-phase (typical for apartments)
    final amps = demand / (208 * 1.732);

    // Recommend service size
    int service;
    if (amps <= 200) service = 200;
    else if (amps <= 400) service = 400;
    else if (amps <= 600) service = 600;
    else if (amps <= 800) service = 800;
    else if (amps <= 1000) service = 1000;
    else if (amps <= 1200) service = 1200;
    else if (amps <= 1600) service = 1600;
    else if (amps <= 2000) service = 2000;
    else service = 2500;

    setState(() {
      _unitLoad = unitTotal;
      _totalConnected = total;
      _demandFactor = factor;
      _demandLoad = demand;
      _serviceAmps = amps;
      _recommendedService = service;
    });
  }

  void _reset() {
    _sqFtPerUnitController.text = '900';
    _appliancesPerUnitController.text = '9000';
    setState(() {
      _units = 10;
      _hasElectricHeat = true;
      _hasElectricCooking = true;
      _hasElectricWaterHeater = true;
    });
    _calculate();
  }
}
