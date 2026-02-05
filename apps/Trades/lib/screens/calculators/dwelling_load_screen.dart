import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Dwelling Unit Load Calculator - Design System v2.6
class DwellingLoadScreen extends ConsumerStatefulWidget {
  const DwellingLoadScreen({super.key});
  @override
  ConsumerState<DwellingLoadScreen> createState() => _DwellingLoadScreenState();
}

class _DwellingLoadScreenState extends ConsumerState<DwellingLoadScreen> {
  final _sqFtController = TextEditingController();
  int _smallApplianceCircuits = 2;
  bool _hasLaundry = true;
  final _dryerController = TextEditingController(text: '5000');
  final _rangeController = TextEditingController(text: '12000');
  final _dishwasherController = TextEditingController(text: '1200');
  final _disposalController = TextEditingController(text: '900');
  final _waterHeaterController = TextEditingController(text: '4500');
  final _acController = TextEditingController();
  final _heatController = TextEditingController();
  Map<String, dynamic>? _results;

  @override
  void dispose() { _sqFtController.dispose(); _dryerController.dispose(); _rangeController.dispose(); _dishwasherController.dispose(); _disposalController.dispose(); _waterHeaterController.dispose(); _acController.dispose(); _heatController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dwelling Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildNecRefCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'GENERAL LIGHTING & RECEPTACLES'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Square Footage', unit: 'sq ft', hint: 'Living area', controller: _sqFtController),
            const SizedBox(height: 8),
            _buildInfoText(colors, '3 VA per sq ft (NEC 220.12)'),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'REQUIRED CIRCUITS'),
            const SizedBox(height: 12),
            _buildStepperRow(colors, label: 'Small Appliance Circuits', value: _smallApplianceCircuits, min: 2, max: 6, onChanged: (v) => setState(() => _smallApplianceCircuits = v)),
            const SizedBox(height: 8),
            _buildInfoText(colors, '1500 VA each (NEC 220.52)'),
            const SizedBox(height: 12),
            _buildSwitchRow(colors, label: 'Laundry Circuit', value: _hasLaundry, onChanged: (v) => setState(() => _hasLaundry = v)),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'APPLIANCES'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Range/Oven', unit: 'W', hint: 'Nameplate', controller: _rangeController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Dryer', unit: 'W', hint: '5000W min', controller: _dryerController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Water Heater', unit: 'W', hint: 'Nameplate', controller: _waterHeaterController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Dishwasher', unit: 'W', hint: 'Nameplate', controller: _dishwasherController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Disposal', unit: 'W', hint: 'Nameplate', controller: _disposalController),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'HVAC (Largest Load Only)'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'A/C', unit: 'W', hint: 'Compressor + fan', controller: _acController),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Heat', unit: 'W', hint: 'Electric heat', controller: _heatController),
            const SizedBox(height: 8),
            _buildInfoText(colors, 'NEC 220.60 - Use larger of A/C or Heat'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('CALCULATE SERVICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNecRefCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 20), const SizedBox(width: 8), Text('NEC Article 220', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('Standard calculation method for single-family dwellings', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  Widget _buildInfoText(ZaftoColors colors, String text) => Padding(padding: const EdgeInsets.only(left: 4), child: Text(text, style: TextStyle(color: colors.textTertiary, fontSize: 11)));

  Widget _buildStepperRow(ZaftoColors colors, {required String label, required int value, required int min, required int max, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary))),
        IconButton(icon: Icon(LucideIcons.minusCircle, color: value > min ? colors.accentPrimary : colors.textTertiary), onPressed: value > min ? () { HapticFeedback.selectionClick(); onChanged(value - 1); } : null),
        Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        IconButton(icon: Icon(LucideIcons.plusCircle, color: value < max ? colors.accentPrimary : colors.textTertiary), onPressed: value < max ? () { HapticFeedback.selectionClick(); onChanged(value + 1); } : null),
      ]),
    );
  }

  Widget _buildSwitchRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary))), Switch(value: value, onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); }, activeColor: colors.accentPrimary)]),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    final totalLoad = _results!['totalLoad'] as double;
    final amps240 = _results!['amps240'] as double;
    final serviceSize = _results!['serviceSize'] as int;
    final breakdown = _results!['breakdown'] as Map<String, double>;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            Text('$serviceSize', style: TextStyle(color: colors.accentSuccess, fontSize: 64, fontWeight: FontWeight.w700)),
            Text('AMP SERVICE', style: TextStyle(color: colors.textTertiary, fontSize: 14, letterSpacing: 1)),
          ]),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Load', style: TextStyle(color: colors.textSecondary)), Text('${amps240.toStringAsFixed(1)} A @ 240V', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total VA', style: TextStyle(color: colors.textSecondary)), Text('${totalLoad.toStringAsFixed(0)} VA', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Text('LOAD BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...breakdown.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text('${e.value.toStringAsFixed(0)} VA', style: TextStyle(color: colors.textPrimary))]))),
      ]),
    );
  }

  void _calculate() {
    final sqFt = double.tryParse(_sqFtController.text) ?? 0;
    if (sqFt <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter square footage'), backgroundColor: ref.read(zaftoColorsProvider).accentError)); return; }
    final generalLighting = sqFt * 3;
    final smallAppliance = _smallApplianceCircuits * 1500.0;
    final laundry = _hasLaundry ? 1500.0 : 0.0;
    final subtotal1 = generalLighting + smallAppliance + laundry;
    double demandedLighting = subtotal1 <= 3000 ? subtotal1 : 3000 + (subtotal1 - 3000) * 0.35;
    final range = double.tryParse(_rangeController.text) ?? 0;
    final dryer = double.tryParse(_dryerController.text) ?? 0;
    final waterHeater = double.tryParse(_waterHeaterController.text) ?? 0;
    final dishwasher = double.tryParse(_dishwasherController.text) ?? 0;
    final disposal = double.tryParse(_disposalController.text) ?? 0;
    double rangeDemand = range <= 12000 ? 8000 : 8000 + ((range - 12000) / 1000).ceil() * 400;
    final dryerDemand = math.max(dryer, 5000.0);
    final fixedAppliances = waterHeater + dishwasher + disposal;
    final ac = double.tryParse(_acController.text) ?? 0;
    final heat = double.tryParse(_heatController.text) ?? 0;
    final hvac = math.max(ac, heat);
    final totalLoad = demandedLighting + rangeDemand + dryerDemand + fixedAppliances + hvac;
    final amps240 = totalLoad / 240;
    int serviceSize;
    if (amps240 <= 100) { serviceSize = 100; } else if (amps240 <= 125) { serviceSize = 125; } else if (amps240 <= 150) { serviceSize = 150; } else if (amps240 <= 175) { serviceSize = 175; } else if (amps240 <= 200) { serviceSize = 200; } else if (amps240 <= 225) { serviceSize = 225; } else if (amps240 <= 250) { serviceSize = 250; } else if (amps240 <= 300) { serviceSize = 300; } else if (amps240 <= 400) { serviceSize = 400; } else { serviceSize = 600; }
    setState(() { _results = {'totalLoad': totalLoad, 'amps240': amps240, 'serviceSize': serviceSize, 'breakdown': {'General Lighting (demanded)': demandedLighting, 'Range (Table 220.55)': rangeDemand, 'Dryer': dryerDemand, 'Water Heater': waterHeater, 'Dishwasher': dishwasher, 'Disposal': disposal, 'HVAC': hvac}}; });
  }

  void _reset() { _sqFtController.clear(); _dryerController.text = '5000'; _rangeController.text = '12000'; _dishwasherController.text = '1200'; _disposalController.text = '900'; _waterHeaterController.text = '4500'; _acController.clear(); _heatController.clear(); setState(() { _smallApplianceCircuits = 2; _hasLaundry = true; _results = null; }); }
}
