import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Garage / Detached Sub-Panel Wiring Diagram - Design System v2.6
class GarageSubPanelScreen extends ConsumerWidget {
  const GarageSubPanelScreen({super.key});

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
        title: Text('Garage / Detached Sub-Panel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCriticalRule(colors),
            const SizedBox(height: 16),
            _buildWiringDiagram(colors),
            const SizedBox(height: 16),
            _buildFeederSizing(colors),
            const SizedBox(height: 16),
            _buildGroundingRequirements(colors),
            const SizedBox(height: 16),
            _buildUndergroundInstall(colors),
            const SizedBox(height: 16),
            _buildTypicalLoads(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalRule(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text('DETACHED BUILDING = SEPARATE GROUNDING', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Ground and neutral MUST be separated at sub-panel\n'
            '• Sub-panel needs its OWN grounding electrode\n'
            '• Remove bonding screw/strap in sub-panel\n'
            '• 4-wire feeder required (2 hots + neutral + ground)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWiringDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEEDER WIRING DIAGRAM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('MAIN PANEL (House)          GARAGE SUB-PANEL', colors.textTertiary),
                _diagramLine('┌─────────────┐             ┌─────────────┐', colors.textTertiary),
                _diagramLine('│ Main Breaker│             │   Lugs or   │', colors.textTertiary),
                _diagramLine('│             │             │ Main Breaker│', colors.textTertiary),
                _diagramLine('│ ┌─────────┐ │   4-WIRE    │ ┌─────────┐ │', colors.textTertiary),
                _diagramLine('│ │ 60A 2P  │─┼─────────────┼─│  L1 L2  │ │', colors.accentPrimary),
                _diagramLine('│ │ Feeder  │ │ L1 (Black)  │ │  N  G   │ │', colors.accentError),
                _diagramLine('│ │ Breaker │ │ L2 (Red)    │ │         │ │', colors.accentError),
                _diagramLine('│ └─────────┘ │ N  (White)  │ │ SEPARATE│ │', colors.textSecondary),
                _diagramLine('│             │ G  (Green)  │ │ N AND G │ │', colors.accentSuccess),
                _diagramLine('│ N+G BONDED  │             │ │ BARS!   │ │', colors.accentWarning),
                _diagramLine('│ HERE ONLY   │             │ └─────────┘ │', colors.textTertiary),
                _diagramLine('└──────┬──────┘             └──────┬──────┘', colors.textTertiary),
                _diagramLine('       │                          │', colors.textTertiary),
                _diagramLine('    ═══╧═══                    ═══╧═══', colors.accentSuccess),
                _diagramLine('   GND ELECT                  GND ELECT', colors.accentSuccess),
                _diagramLine('   (existing)                 (NEW rod)', colors.accentSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }

  Widget _buildFeederSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEEDER SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _headerRow(['Sub-Panel', 'Breaker', 'Wire (Cu)', 'Wire (Al)'], colors),
              _dataRow(['60A', '60A 2-pole', '6 AWG', '4 AWG'], colors),
              _dataRow(['100A', '100A 2-pole', '3 AWG', '1 AWG'], colors),
              _dataRow(['125A', '125A 2-pole', '2 AWG', '1/0 AWG'], colors),
              _dataRow(['150A', '150A 2-pole', '1 AWG', '2/0 AWG'], colors),
              _dataRow(['200A', '200A 2-pole', '2/0 AWG', '4/0 AWG'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Add separate ground wire same size or per 250.122', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
      ),
      child: Row(children: headers.map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)))).toList()),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: values.asMap().entries.map((e) => Expanded(child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400, fontSize: 11)))).toList()),
    );
  }

  Widget _buildGroundingRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.anchor, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('GROUNDING ELECTRODE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Detached building requires its own grounding electrode:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          _groundItem('Ground rod(s)', '8 ft min, 5/8" copper-clad', colors),
          _groundItem('If >25 ohms', 'Add second rod 6ft apart', colors),
          _groundItem('Concrete-encased', 'Ufer ground (if available)', colors),
          _groundItem('GEC size', 'Per Table 250.66', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Connect GEC to equipment ground bar in sub-panel (NOT neutral bar)', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _groundItem(String item, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.zap, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildUndergroundInstall(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowDownToLine, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('UNDERGROUND INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _buryRow('PVC conduit', '18" minimum depth', colors),
          _buryRow('Rigid metal', '6" minimum depth', colors),
          _buryRow('Direct burial (UF)', '24" under normal, 18" under concrete', colors),
          _buryRow('Under driveway', '24" for all methods', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Installation Tips:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                Text('• Use PVC conduit sweeps at each end\n• LB fitting at building entry\n• Expansion fitting for long runs\n• Warning tape 12" above conduit', style: TextStyle(color: colors.textTertiary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buryRow(String method, String depth, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(method, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        Text(depth, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  Widget _buildTypicalLoads(ZaftoColors colors) {
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
            Icon(LucideIcons.warehouse, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('TYPICAL GARAGE LOADS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Lights: 15A circuit\n'
            '• Receptacles: 20A circuit (GFCI)\n'
            '• Garage door opener: 15-20A\n'
            '• Welder: 50A 240V\n'
            '• Air compressor: 20-30A 240V\n'
            '• EV charger: 50A 240V\n'
            '• Mini-split A/C: 20-30A 240V\n'
            '• Space heater: 20A 240V',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('60A sub-panel handles basic garage. 100A for shop with welder/EV.', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
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
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC 225 - Outside Branch Circuits and Feeders\n'
            '• NEC 250.32 - Buildings/Structures Supplied by Feeder\n'
            '• NEC 300.5 - Underground Installations\n'
            '• NEC Table 300.5 - Burial Depth Requirements\n'
            '• NEC 250.122 - Equipment Grounding Conductor Size',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
