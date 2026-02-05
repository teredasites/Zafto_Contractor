import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Commercial Load Calculator - Design System v2.6
class CommercialLoadScreen extends ConsumerStatefulWidget {
  const CommercialLoadScreen({super.key});
  @override
  ConsumerState<CommercialLoadScreen> createState() => _CommercialLoadScreenState();
}

class _CommercialLoadScreenState extends ConsumerState<CommercialLoadScreen> {
  String _buildingType = 'Office';
  final _sqFtController = TextEditingController();
  final _receptaclesController = TextEditingController();
  final _signController = TextEditingController(text: '1200');
  final _hvacController = TextEditingController();
  final _kitchenController = TextEditingController();
  Map<String, dynamic>? _results;

  static const Map<String, double> _lightingLoads = {'Office': 3.5, 'Bank': 3.5, 'Retail': 3.0, 'Restaurant': 2.0, 'Warehouse': 0.25, 'Hotel/Motel': 2.0, 'Hospital': 2.0, 'School': 3.0, 'Church': 1.0, 'Industrial': 2.0, 'Parking Garage': 0.25};

  @override
  void dispose() { _sqFtController.dispose(); _receptaclesController.dispose(); _signController.dispose(); _hvacController.dispose(); _kitchenController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Commercial Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildNecCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'BUILDING TYPE'),
            const SizedBox(height: 12),
            _buildBuildingTypeSelector(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'GENERAL LIGHTING'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Square Footage', unit: 'sq ft', controller: _sqFtController),
            const SizedBox(height: 8),
            Text('${_lightingLoads[_buildingType]} VA/sq ft per NEC 220.12', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'RECEPTACLES'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Receptacle VA', unit: 'VA', hint: '180 VA typical', controller: _receptaclesController),
            const SizedBox(height: 8),
            Text('Banks, offices: 1 VA/sq ft minimum', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'ADDITIONAL LOADS'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Sign Lighting', unit: 'VA', hint: '1200 VA min', controller: _signController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'HVAC', unit: 'VA', controller: _hvacController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Kitchen Equipment', unit: 'VA', controller: _kitchenController),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNecCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Icon(LucideIcons.building2, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NEC Article 220', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          Text('Commercial/Industrial Load Calculations', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildBuildingTypeSelector(ZaftoColors colors) {
    final types = ['Office', 'Retail', 'Restaurant', 'Warehouse', 'Hotel/Motel', 'Hospital', 'School', 'Industrial'];
    final vaPerSqFt = _lightingLoads[_buildingType] ?? 3.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        DropdownButton<String>(value: _buildingType, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _buildingType = v!)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text('$vaPerSqFt VA/sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildResults(ZaftoColors colors) {
    final totalVa = _results!['totalVa'] as double;
    final amps = _results!['amps'] as double;
    final serviceSize = _results!['serviceSize'] as int;
    final breakdown = _results!['breakdown'] as Map<String, double>;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('$serviceSize', style: TextStyle(color: colors.accentSuccess, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('AMP SERVICE @ 208V 3Φ', style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
        const SizedBox(height: 20),
        _buildResultRow(colors, 'Calculated Load', '${amps.toStringAsFixed(1)} A'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Total VA', '${totalVa.toStringAsFixed(0)} VA'),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Text('LOAD BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...breakdown.entries.where((e) => e.value > 0).map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            Text('${e.value.toStringAsFixed(0)} VA', style: TextStyle(color: colors.textPrimary)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _calculate() {
    final colors = ref.read(zaftoColorsProvider);
    final sqFt = double.tryParse(_sqFtController.text) ?? 0;
    if (sqFt <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter square footage'), backgroundColor: colors.accentError)); return; }
    final vaPerSqFt = _lightingLoads[_buildingType] ?? 3.0;
    final generalLighting = sqFt * vaPerSqFt;
    final receptacles = double.tryParse(_receptaclesController.text) ?? 0;
    final combinedLR = generalLighting + receptacles;
    final demandedLR = combinedLR <= 10000 ? combinedLR : 10000 + (combinedLR - 10000) * 0.5;
    final sign = math.max(double.tryParse(_signController.text) ?? 0, 1200);
    final hvac = double.tryParse(_hvacController.text) ?? 0;
    final kitchen = double.tryParse(_kitchenController.text) ?? 0;
    final totalVa = demandedLR + sign + hvac + kitchen;
    final amps = totalVa / (208 * math.sqrt(3));
    int serviceSize;
    if (amps <= 100) serviceSize = 100; else if (amps <= 200) serviceSize = 200; else if (amps <= 400) serviceSize = 400; else if (amps <= 600) serviceSize = 600; else if (amps <= 800) serviceSize = 800; else if (amps <= 1000) serviceSize = 1000; else if (amps <= 1200) serviceSize = 1200; else if (amps <= 1600) serviceSize = 1600; else if (amps <= 2000) serviceSize = 2000; else serviceSize = 2500;
    setState(() { _results = {'totalVa': totalVa, 'amps': amps, 'serviceSize': serviceSize, 'breakdown': {'General Lighting (demanded)': demandedLR, 'Sign Lighting': sign, 'HVAC': hvac, 'Kitchen Equipment': kitchen}}; });
  }

  void _reset() { _sqFtController.clear(); _receptaclesController.clear(); _signController.text = '1200'; _hvacController.clear(); _kitchenController.clear(); setState(() { _buildingType = 'Office'; _results = null; }); }
}
