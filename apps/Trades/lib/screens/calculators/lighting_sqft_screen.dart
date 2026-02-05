import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Lighting by Square Foot Calculator - Design System v2.6
class _OccupancyData { final String name; final num vaPerSqft; final IconData icon; const _OccupancyData({required this.name, required this.vaPerSqft, required this.icon}); }

class LightingSqftScreen extends ConsumerStatefulWidget {
  const LightingSqftScreen({super.key});
  @override
  ConsumerState<LightingSqftScreen> createState() => _LightingSqftScreenState();
}

class _LightingSqftScreenState extends ConsumerState<LightingSqftScreen> {
  final _sqftController = TextEditingController(text: '2000');
  String _occupancyType = 'dwelling';
  int _voltage = 120;
  int _circuitAmps = 20;

  static const Map<String, _OccupancyData> _occupancyTypes = {
    'dwelling': _OccupancyData(name: 'Dwelling Unit', vaPerSqft: 3, icon: LucideIcons.home),
    'hospital': _OccupancyData(name: 'Hospital', vaPerSqft: 2, icon: LucideIcons.stethoscope),
    'hotel': _OccupancyData(name: 'Hotel / Motel', vaPerSqft: 2, icon: LucideIcons.bed),
    'warehouse': _OccupancyData(name: 'Warehouse', vaPerSqft: 0.25, icon: LucideIcons.warehouse),
    'office': _OccupancyData(name: 'Office Building', vaPerSqft: 3.5, icon: LucideIcons.building2),
    'restaurant': _OccupancyData(name: 'Restaurant', vaPerSqft: 2, icon: LucideIcons.utensils),
    'retail': _OccupancyData(name: 'Retail Store', vaPerSqft: 3, icon: LucideIcons.store),
    'school': _OccupancyData(name: 'School', vaPerSqft: 3, icon: LucideIcons.graduationCap),
    'church': _OccupancyData(name: 'Church', vaPerSqft: 1, icon: LucideIcons.church),
    'industrial': _OccupancyData(name: 'Industrial', vaPerSqft: 2, icon: LucideIcons.factory),
    'bank': _OccupancyData(name: 'Bank', vaPerSqft: 3.5, icon: LucideIcons.landmark),
    'garage': _OccupancyData(name: 'Parking Garage', vaPerSqft: 0.5, icon: LucideIcons.car),
  };

  double get _sqft => double.tryParse(_sqftController.text) ?? 0;
  _OccupancyData get _selectedOccupancy => _occupancyTypes[_occupancyType]!;
  double get _totalVa => _sqft * _selectedOccupancy.vaPerSqft;
  double get _totalAmps => _totalVa / _voltage;
  int get _circuitsNeeded { final usableAmps = _circuitAmps * 0.8; return (_totalAmps / usableAmps).ceil(); }

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lighting by Sq Ft', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSqftInput(colors),
        const SizedBox(height: 16),
        _buildOccupancySelector(colors),
        const SizedBox(height: 16),
        _buildCircuitConfig(colors),
        const SizedBox(height: 20),
        _buildResultsCard(colors),
        const SizedBox(height: 16),
        _buildTableCard(colors),
        const SizedBox(height: 16),
        _buildCodeReference(colors),
      ]),
    );
  }

  Widget _buildSqftInput(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLOOR AREA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: _sqftController, keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: '0', hintStyle: TextStyle(color: colors.textTertiary), suffixText: 'sq ft', suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 14), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
        ),
      ]),
    );
  }

  Widget _buildOccupancySelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OCCUPANCY TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _occupancyTypes.entries.map((e) {
          final isSelected = _occupancyType == e.key;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _occupancyType = e.key); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.icon, size: 16, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary),
                const SizedBox(width: 6),
                Text(e.value.name, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildCircuitConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CIRCUIT CONFIGURATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voltage', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [120, 277].map((v) {
              final isSelected = _voltage == v;
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _voltage = v); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13))),
              ));
            }).toList()),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Circuit Size', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: [15, 20].map((a) {
              final isSelected = _circuitAmps == a;
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _circuitAmps = a); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text('${a}A', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13))),
              ));
            }).toList()),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text((_totalVa / 1000).toStringAsFixed(1), style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('kVA Lighting Load', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildRow(colors, 'VA per sq ft', '${_selectedOccupancy.vaPerSqft}', false),
            const SizedBox(height: 10),
            _buildRow(colors, 'Total VA', _totalVa.toStringAsFixed(0), false),
            const SizedBox(height: 10),
            _buildRow(colors, 'Total Amps', '${_totalAmps.toStringAsFixed(1)}A', false),
            Divider(color: colors.borderSubtle, height: 20),
            _buildRow(colors, 'Circuits Needed', '$_circuitsNeeded', true),
            const SizedBox(height: 4),
            Text('(at 80% capacity)', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC TABLE 220.12 REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...['dwelling', 'office', 'retail', 'warehouse', 'restaurant'].map((key) {
          final data = _occupancyTypes[key]!;
          final isSelected = _occupancyType == key;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5)))),
            child: Row(children: [
              Expanded(child: Text(data.name, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 12))),
              Text('${data.vaPerSqft} VA/sqft', style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textTertiary, fontSize: 12)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 220.12', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Table 220.12 - General lighting loads\n• Minimum load per occupancy type\n• Use floor area from building plans\n• Does not include receptacle loads', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
