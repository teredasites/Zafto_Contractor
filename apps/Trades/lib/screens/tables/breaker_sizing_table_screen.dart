import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Breaker Sizing Quick Reference Table - Design System v2.6
class BreakerSizingTableScreen extends ConsumerWidget {
  const BreakerSizingTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Breaker Sizing Reference', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommonCircuits(colors),
            const SizedBox(height: 16),
            _buildWireSizeTable(colors),
            const SizedBox(height: 16),
            _buildApplianceTable(colors),
            const SizedBox(height: 16),
            _buildRules(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonCircuits(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.home, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('COMMON RESIDENTIAL CIRCUITS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _circuitRow('General lighting/outlets', '15A', '14 AWG', '120V', colors),
          _circuitRow('Kitchen countertop', '20A', '12 AWG', '120V', colors),
          _circuitRow('Bathroom', '20A', '12 AWG', '120V', colors),
          _circuitRow('Laundry', '20A', '12 AWG', '120V', colors),
          _circuitRow('Refrigerator', '20A', '12 AWG', '120V', colors),
          _circuitRow('Dishwasher', '20A', '12 AWG', '120V', colors),
          _circuitRow('Disposal', '20A', '12 AWG', '120V', colors),
          _circuitRow('Microwave (built-in)', '20A', '12 AWG', '120V', colors),
          _circuitRow('Garage', '20A', '12 AWG', '120V', colors),
          _circuitRow('Outdoor/shed', '20A', '12 AWG', '120V', colors),
          Divider(color: colors.borderSubtle, height: 20),
          _circuitRow('Electric dryer', '30A', '10 AWG', '240V', colors),
          _circuitRow('Electric range', '50A', '6 AWG', '240V', colors),
          _circuitRow('EV charger (Level 2)', '50A', '6 AWG', '240V', colors),
          _circuitRow('Water heater (4500W)', '30A', '10 AWG', '240V', colors),
          _circuitRow('A/C (3 ton)', '30-40A', '10-8 AWG', '240V', colors),
          _circuitRow('Hot tub/spa', '50-60A', '6-4 AWG', '240V', colors),
          _circuitRow('Welder outlet', '50A', '6 AWG', '240V', colors),
        ],
      ),
    );
  }

  Widget _circuitRow(String circuit, String breaker, String wire, String voltage, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(circuit, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          SizedBox(width: 50, child: Text(breaker, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(width: 60, child: Text(wire, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          SizedBox(width: 45, child: Text(voltage, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildWireSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.plug, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('WIRE SIZE → MAX BREAKER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Wire (Cu)', 'Max Breaker', '60°C', '75°C'], colors),
                _dataRow(['14 AWG', '15A', '15A', '15A'], colors),
                _dataRow(['12 AWG', '20A', '20A', '20A'], colors),
                _dataRow(['10 AWG', '30A', '30A', '30A'], colors),
                _dataRow(['8 AWG', '40A', '40A', '45A'], colors),
                _dataRow(['6 AWG', '55A', '55A', '65A'], colors),
                _dataRow(['4 AWG', '70A', '70A', '85A'], colors),
                _dataRow(['3 AWG', '85A', '85A', '100A'], colors),
                _dataRow(['2 AWG', '95A', '95A', '115A'], colors),
                _dataRow(['1 AWG', '110A', '110A', '130A'], colors),
                _dataRow(['1/0 AWG', '125A', '125A', '150A'], colors),
                _dataRow(['2/0 AWG', '145A', '145A', '175A'], colors),
                _dataRow(['3/0 AWG', '165A', '165A', '200A'], colors),
                _dataRow(['4/0 AWG', '195A', '195A', '230A'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Based on NEC Table 310.16 (copper conductors)', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _buildApplianceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('APPLIANCE WATTAGE REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _appRow('LED bulb', '10W', colors),
          _appRow('Ceiling fan', '75W', colors),
          _appRow('Refrigerator', '150-400W', colors),
          _appRow('Microwave', '1000-1500W', colors),
          _appRow('Toaster', '800-1500W', colors),
          _appRow('Coffee maker', '600-1200W', colors),
          _appRow('Hair dryer', '1000-1800W', colors),
          _appRow('Space heater', '1500W', colors),
          _appRow('Window A/C', '500-1500W', colors),
          _appRow('Vacuum', '500-1200W', colors),
          _appRow('Washing machine', '500W', colors),
          _appRow('Electric dryer', '3000-5000W', colors),
          _appRow('Electric range', '8000-12000W', colors),
          _appRow('Water heater', '4500W', colors),
          _appRow('EV charger L2', '7200-11500W', colors),
        ],
      ),
    );
  }

  Widget _appRow(String appliance, String watts, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(appliance, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(watts, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('QUICK RULES', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Breaker protects WIRE, not appliance\n'
            '• Continuous load: size at 125% (or 80% of breaker)\n'
            '• Amps = Watts ÷ Volts\n'
            '• 120V circuit: 1800W max on 15A, 2400W max on 20A\n'
            '• 240V circuit: watts = volts × amps\n'
            '• When in doubt, go larger on wire size',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
