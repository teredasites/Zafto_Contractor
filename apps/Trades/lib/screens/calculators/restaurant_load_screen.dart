import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Restaurant Load Calculator - Design System v2.6
/// NEC 220.56 - Commercial kitchen equipment loads
class RestaurantLoadScreen extends ConsumerStatefulWidget {
  const RestaurantLoadScreen({super.key});
  @override
  ConsumerState<RestaurantLoadScreen> createState() => _RestaurantLoadScreenState();
}

class _RestaurantLoadScreenState extends ConsumerState<RestaurantLoadScreen> {
  final _sqFtController = TextEditingController(text: '2500');
  final List<_EquipmentEntry> _equipment = [
    _EquipmentEntry(name: 'Commercial Range', kw: 15.0),
    _EquipmentEntry(name: 'Fryer', kw: 14.0),
    _EquipmentEntry(name: 'Dishwasher', kw: 10.0),
    _EquipmentEntry(name: 'Walk-in Cooler', kw: 3.0),
    _EquipmentEntry(name: 'Walk-in Freezer', kw: 5.0),
  ];
  final _hvacController = TextEditingController(text: '30');
  final _lightingController = TextEditingController(text: '');

  double? _lightingLoad;
  double? _equipmentTotal;
  double? _equipmentDemand;
  double? _hvacLoad;
  double? _totalDemand;
  double? _serviceAmps;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _sqFtController.dispose();
    _hvacController.dispose();
    _lightingController.dispose();
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
        title: Text('Restaurant Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildInputRow(colors, 'Square Footage', _sqFtController, 'sq ft'),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'KITCHEN EQUIPMENT'),
              const SizedBox(height: 12),
              ..._equipment.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEquipmentRow(colors, e.key),
              )),
              _buildAddEquipmentButton(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HVAC'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'A/C Tonnage', _hvacController, 'tons'),
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
        Expanded(child: Text('NEC 220.56 - Kitchen equipment demand factors', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(isDense: true, border: InputBorder.none, suffixText: unit, suffixStyle: TextStyle(color: colors.textTertiary)),
            onChanged: (_) => _calculate(),
          ),
        ),
      ]),
    );
  }

  Widget _buildEquipmentRow(ZaftoColors colors, int index) {
    final entry = _equipment[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: TextField(
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(isDense: true, hintText: 'Equipment', hintStyle: TextStyle(color: colors.textTertiary), border: InputBorder.none),
            controller: TextEditingController(text: entry.name),
            onChanged: (v) => entry.name = v,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(isDense: true, suffixText: 'kW', suffixStyle: TextStyle(color: colors.textTertiary), border: InputBorder.none),
            controller: TextEditingController(text: entry.kw.toString()),
            onChanged: (v) { entry.kw = double.tryParse(v) ?? 0; _calculate(); },
          ),
        ),
        if (_equipment.length > 1) IconButton(
          icon: Icon(LucideIcons.trash2, color: colors.error, size: 20),
          onPressed: () { setState(() => _equipment.removeAt(index)); _calculate(); },
        ),
      ]),
    );
  }

  Widget _buildAddEquipmentButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { setState(() => _equipment.add(_EquipmentEntry(name: 'New Equipment', kw: 5.0))); _calculate(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.plus, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text('Add Equipment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_serviceAmps?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps @ 208V 3Ø', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Lighting (2 VA/sq ft)', '${_lightingLoad?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Kitchen equipment total', '${_equipmentTotal?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Equipment demand (${_getDemandFactor()}%)', '${_equipmentDemand?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'HVAC', '${_hvacLoad?.toStringAsFixed(0) ?? '0'} VA'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Total demand', '${_totalDemand?.toStringAsFixed(0) ?? '0'} VA', highlight: true),
        const SizedBox(height: 16),
        _buildDemandFactorTable(colors),
      ]),
    );
  }

  Widget _buildDemandFactorTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text('NEC Table 220.56', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text('Equipment Count: ${_equipment.length} → ${_getDemandFactor()}% demand', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      ]),
    );
  }

  String _getDemandFactor() {
    final count = _equipment.length;
    if (count <= 2) return '100';
    if (count == 3) return '90';
    if (count == 4) return '80';
    if (count == 5) return '70';
    if (count >= 6) return '65';
    return '100';
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13))),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final sqFt = double.tryParse(_sqFtController.text) ?? 0;
    final hvacTons = double.tryParse(_hvacController.text) ?? 0;

    // Lighting: 2 VA/sq ft for restaurants (Table 220.12)
    final lighting = sqFt * 2;

    // Kitchen equipment total
    double equipTotal = 0;
    for (final e in _equipment) {
      equipTotal += e.kw * 1000; // Convert kW to VA
    }

    // NEC 220.56 demand factors
    double demandFactor;
    final count = _equipment.length;
    if (count <= 2) demandFactor = 1.0;
    else if (count == 3) demandFactor = 0.90;
    else if (count == 4) demandFactor = 0.80;
    else if (count == 5) demandFactor = 0.70;
    else demandFactor = 0.65;

    final equipDemand = equipTotal * demandFactor;

    // HVAC: ~12,000 BTU per ton, roughly 3.5 kW per ton
    final hvac = hvacTons * 3500;

    // Total demand
    final total = lighting + equipDemand + hvac;

    // Service amps at 208V 3-phase
    final amps = total / (208 * 1.732);

    setState(() {
      _lightingLoad = lighting;
      _equipmentTotal = equipTotal;
      _equipmentDemand = equipDemand;
      _hvacLoad = hvac;
      _totalDemand = total;
      _serviceAmps = amps;
    });
  }

  void _reset() {
    _sqFtController.text = '2500';
    _hvacController.text = '30';
    setState(() {
      _equipment.clear();
      _equipment.addAll([
        _EquipmentEntry(name: 'Commercial Range', kw: 15.0),
        _EquipmentEntry(name: 'Fryer', kw: 14.0),
        _EquipmentEntry(name: 'Dishwasher', kw: 10.0),
        _EquipmentEntry(name: 'Walk-in Cooler', kw: 3.0),
        _EquipmentEntry(name: 'Walk-in Freezer', kw: 5.0),
      ]);
    });
    _calculate();
  }
}

class _EquipmentEntry {
  String name;
  double kw;
  _EquipmentEntry({required this.name, required this.kw});
}
