import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Fixture Rough-In Dimensions Diagram - Design System v2.6
class FixtureRoughInScreen extends ConsumerWidget {
  const FixtureRoughInScreen({super.key});

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
        title: Text('Fixture Rough-In', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToilet(colors),
            const SizedBox(height: 16),
            _buildLavatory(colors),
            const SizedBox(height: 16),
            _buildKitchenSink(colors),
            const SizedBox(height: 16),
            _buildShower(colors),
            const SizedBox(height: 16),
            _buildBathtub(colors),
            const SizedBox(height: 16),
            _buildWashingMachine(colors),
            const SizedBox(height: 16),
            _buildNote(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildToilet(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('TOILET (WATER CLOSET)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    WALL', colors.textTertiary),
                _diagramLine('    ═════════════════════', colors.textTertiary),
                _diagramLine('    │     │', colors.textTertiary),
                _diagramLine('    │    12"  ← Rough-in', colors.accentPrimary),
                _diagramLine('    │     │    (to center)', colors.textTertiary),
                _diagramLine('    │     ●  ← Flange', colors.accentError),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    │  ○ ← Supply (6" left', colors.accentInfo),
                _diagramLine('    │        of center, 6" AFF)', colors.textTertiary),
                _diagramLine('   ─┴─────────────────────', colors.textTertiary),
                _diagramLine('   FLOOR', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _dimRow('Rough-in (from wall)', '12" standard (10", 14" also common)', colors),
          _dimRow('Supply height', '6" above finished floor (AFF)', colors),
          _dimRow('Supply location', '6" left of centerline', colors),
          _dimRow('Flange height', 'Flush with or 1/4" above floor', colors),
          _dimRow('Side clearance', '15" min from center to side wall/obstruction', colors),
          _dimRow('Front clearance', '21" min from front of toilet', colors),
          _dimRow('Drain size', '3" minimum', colors),
        ],
      ),
    );
  }

  Widget _buildLavatory(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bath, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('LAVATORY (BATHROOM SINK)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    WALL', colors.textTertiary),
                _diagramLine('    ═══════════════════════', colors.textTertiary),
                _diagramLine('    │        │         │', colors.textTertiary),
                _diagramLine('    │  HOT ○ │ ● DRAIN │ ○ COLD', colors.accentInfo),
                _diagramLine('    │   ↑    │    ↑    │   ↑', colors.textTertiary),
                _diagramLine('    │  4"    │   17"   │  4"', colors.accentPrimary),
                _diagramLine('    │  left  │   AFF   │ right', colors.textTertiary),
                _diagramLine('    │        │         │', colors.textTertiary),
                _diagramLine('    │     21" AFF supplies', colors.accentPrimary),
                _diagramLine('   ─┴─────────────────────────', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _dimRow('Drain height', '17-19" AFF (center of trap arm)', colors),
          _dimRow('Supply height', '21-24" AFF', colors),
          _dimRow('Supply spread', '4" each side of center (8" total)', colors),
          _dimRow('Drain size', '1-1/4" minimum', colors),
          _dimRow('Mounting height', '31-34" AFF (rim)', colors),
        ],
      ),
    );
  }

  Widget _buildKitchenSink(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.droplets, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('KITCHEN SINK', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _dimRow('Drain height', '15-18" AFF (center)', colors),
          _dimRow('Supply height', '20-24" AFF', colors),
          _dimRow('Supply spread', '4" each side (8" total)', colors),
          _dimRow('Drain size', '1-1/2" minimum', colors),
          _dimRow('Garbage disposal', 'Switched outlet inside cabinet', colors),
          _dimRow('Dishwasher', 'Hot supply + drain under sink', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Dishwasher drain requires air gap or high loop above disposal', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildShower(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.cloudRain, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('SHOWER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _dimRow('Valve height', '48" AFF (center)', colors),
          _dimRow('Shower head', '72-80" AFF', colors),
          _dimRow('Drain location', 'Center of base or offset', colors),
          _dimRow('Drain size', '2" minimum', colors),
          _dimRow('Supply rough-in', '1/2" hot and cold', colors),
          _dimRow('Min shower size', '30" x 30" (IPC 417.4)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pressure Balance or Thermostatic:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Code requires anti-scald protection (max 120°F). Use pressure-balance or thermostatic mixing valve.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBathtub(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bath, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('BATHTUB', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _dimRow('Valve height', '28" AFF (faucet end)', colors),
          _dimRow('Spout height', '4" above tub rim', colors),
          _dimRow('Spout location', '4" above overflow', colors),
          _dimRow('Drain/overflow', 'Match tub model specs', colors),
          _dimRow('Drain size', '1-1/2" minimum', colors),
          _dimRow('Access panel', 'Required for trap/valve access', colors),
          const SizedBox(height: 12),
          _dimRow('Tub/shower combo', 'Same as shower for valve and head', colors),
        ],
      ),
    );
  }

  Widget _buildWashingMachine(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.settings, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('WASHING MACHINE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _dimRow('Box location', '42-48" AFF (center of box)', colors),
          _dimRow('Supply valves', 'Hot left, cold right', colors),
          _dimRow('Standpipe height', '18-42" above trap weir', colors),
          _dimRow('Standpipe size', '2" min diameter', colors),
          _dimRow('Trap size', '2" P-trap', colors),
          _dimRow('Air gap', 'Standpipe provides air gap', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Use washing machine outlet box with integral shut-offs and drain. Install emergency pan with drain in upstairs locations.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text('IMPORTANT NOTES', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Always verify with actual fixture specifications\n'
            '• ADA fixtures have different requirements\n'
            '• Local codes may differ - always check\n'
            '• AFF = Above Finished Floor\n'
            '• Rough-in dimensions are to FINISHED wall\n'
            '• Account for wall thickness (drywall, tile)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _dimRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
