import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Supply System Diagram - Design System v2.6
class WaterSupplyScreen extends ConsumerWidget {
  const WaterSupplyScreen({super.key});

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
        title: Text('Water Supply System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildSystemDiagram(colors),
            const SizedBox(height: 16),
            _buildPipeMaterials(colors),
            const SizedBox(height: 16),
            _buildPipeSizing(colors),
            const SizedBox(height: 16),
            _buildPressureRequirements(colors),
            const SizedBox(height: 16),
            _buildColorCodes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
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
            Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('Water Supply Basics', style: TextStyle(color: colors.accentInfo, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          _bulletItem('Pressurized system', 'Operates under pressure (40-80 PSI)', colors),
          _bulletItem('Two temperatures', 'Cold water and hot water distribution', colors),
          _bulletItem('Branch to fixtures', 'Main lines branch to individual fixtures', colors),
          _bulletItem('Shut-off valves', 'Individual valves at each fixture', colors),
        ],
      ),
    );
  }

  Widget _bulletItem(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TYPICAL RESIDENTIAL SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('CITY MAIN', colors.textTertiary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('════╧════ WATER METER', colors.accentInfo),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('   [X] MAIN SHUT-OFF', colors.accentError),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('   PRV (if needed)', colors.accentWarning),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    ├────────────────────┐', colors.accentInfo),
                _diagramLine('    │                    │', colors.textTertiary),
                _diagramLine('   COLD              WATER HEATER', colors.accentInfo),
                _diagramLine('    │                    │', colors.textTertiary),
                _diagramLine('    │                   HOT', colors.accentError),
                _diagramLine('    │                    │', colors.textTertiary),
                _diagramLine('    ├───────┬───────────┬┘', colors.textTertiary),
                _diagramLine('    │       │           │', colors.textTertiary),
                _diagramLine('  [LAV]   [WC]       [TUB]', colors.accentPrimary),
                _diagramLine('  H + C   Cold       H + C', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _legendItem('Blue', 'Cold', colors.accentInfo, colors),
            const SizedBox(width: 20),
            _legendItem('Red', 'Hot', colors.accentError, colors),
          ]),
        ],
      ),
    );
  }

  Widget _legendItem(String color, String label, Color dotColor, ZaftoColors colors) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text('$color = $label', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildPipeMaterials(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PIPE MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _materialRow('Copper (Type L)', 'Traditional, durable, solderable', 'Hot/Cold', colors),
          _materialRow('Copper (Type M)', 'Thinner wall, residential only', 'Hot/Cold', colors),
          _materialRow('PEX', 'Flexible, easy install, freeze resistant', 'Hot/Cold', colors),
          _materialRow('CPVC', 'Rigid plastic, glued connections', 'Hot/Cold', colors),
          _materialRow('PVC', 'Cold water ONLY, not for hot', 'Cold only', colors),
          _materialRow('Galvanized', 'Old/legacy, not recommended new', 'Hot/Cold', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.leaf, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('PEX is most common for new residential - flexible, fewer connections, no solder', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _materialRow(String material, String desc, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(material, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(use, style: TextStyle(color: colors.accentPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TYPICAL PIPE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _sizeRow('Water meter to house', '3/4" - 1"', colors),
          _sizeRow('Main distribution', '3/4"', colors),
          _sizeRow('Branch to bathroom group', '1/2"', colors),
          _sizeRow('Individual fixture', '1/2" (3/8" to faucet)', colors),
          _sizeRow('Toilet supply', '3/8"', colors),
          _sizeRow('Refrigerator ice maker', '1/4"', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Never reduce main line size before branching - causes pressure issues', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sizeRow(String location, String size, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(location, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(size, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPressureRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('PRESSURE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _pressureRow('Minimum at fixture', '8 PSI (20 PSI for some)', colors),
          _pressureRow('Normal operating', '40-60 PSI', colors),
          _pressureRow('Maximum allowed', '80 PSI', colors),
          _pressureRow('Requires PRV above', '80 PSI', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRV (Pressure Reducing Valve)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Required when street pressure exceeds 80 PSI\n• Set output to 50-60 PSI\n• Install expansion tank when PRV present', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pressureRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildColorCodes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.palette, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('PEX COLOR CODING', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _colorRow('Red PEX', 'Hot water lines', Colors.red, colors),
          _colorRow('Blue PEX', 'Cold water lines', Colors.blue, colors),
          _colorRow('White PEX', 'Hot or cold (either)', Colors.white, colors),
          _colorRow('Orange PEX', 'Radiant heating', Colors.orange, colors),
          const SizedBox(height: 12),
          Text(
            'Note: Color is for identification only - all colors rated same temperature/pressure. Using correct colors helps future service.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(String color, String use, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2), border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(color, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
