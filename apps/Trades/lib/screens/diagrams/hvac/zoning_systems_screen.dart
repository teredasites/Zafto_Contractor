import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// HVAC Zoning Systems Diagram - Design System v2.6
class ZoningSystemsScreen extends ConsumerWidget {
  const ZoningSystemsScreen({super.key});

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
        title: Text('Zoning Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildSystemComponents(colors),
            const SizedBox(height: 16),
            _buildZoneDampers(colors),
            const SizedBox(height: 16),
            _buildBypassDamper(colors),
            const SizedBox(height: 16),
            _buildZoneControls(colors),
            const SizedBox(height: 16),
            _buildDesignConsiderations(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('WHAT IS HVAC ZONING?', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    ┌──────────────────────────────────────┐', colors.textTertiary),
                _diagramLine('    │              HOME                    │', colors.textTertiary),
                _diagramLine('    │  ┌──────────┐    ┌──────────┐       │', colors.textTertiary),
                _diagramLine('    │  │  ZONE 1  │    │  ZONE 2  │       │', colors.accentInfo),
                _diagramLine('    │  │  72°F    │    │  68°F    │       │', colors.accentInfo),
                _diagramLine('    │  │[T-STAT 1]│    │[T-STAT 2]│       │', colors.accentWarning),
                _diagramLine('    │  └────┬─────┘    └────┬─────┘       │', colors.textTertiary),
                _diagramLine('    │       │              │              │', colors.textTertiary),
                _diagramLine('    │    [DAMPER]      [DAMPER]           │', colors.accentPrimary),
                _diagramLine('    │       │              │              │', colors.textTertiary),
                _diagramLine('    │       └──────┬───────┘              │', colors.textTertiary),
                _diagramLine('    │              │                      │', colors.textTertiary),
                _diagramLine('    │       [ZONE PANEL]                  │', colors.accentError),
                _diagramLine('    │              │                      │', colors.textTertiary),
                _diagramLine('    │         [HVAC UNIT]                 │', colors.accentWarning),
                _diagramLine('    └──────────────────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Zoning divides a home into separate areas, each with its own thermostat and motorized dampers to control airflow independently.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSystemComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _compRow('Zone panel', 'Brain of system - coordinates dampers, stats, equipment', colors),
          _compRow('Zone thermostats', 'One per zone - calls for heating/cooling', colors),
          _compRow('Zone dampers', 'Motorized dampers in ductwork', colors),
          _compRow('Bypass damper', 'Relieves excess pressure when zones close', colors),
          _compRow('Supply sensor', 'Monitors supply air temperature', colors),
          _compRow('Static pressure sensor', 'Monitors duct pressure', colors),
        ],
      ),
    );
  }

  Widget _compRow(String component, String function, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildZoneDampers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONE DAMPERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _damperRow('Round damper', 'For round flex or rigid duct', 'Common residential', colors),
          _damperRow('Rectangular damper', 'For rectangular duct', 'Trunk lines', colors),
          _damperRow('Spring return', 'Opens on power loss', 'Safety default', colors),
          _damperRow('Power open/close', 'Motor drives both directions', 'More control', colors),
          const SizedBox(height: 12),
          Text('Damper Positions:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _posRow('Fully open', 'Zone calling, full airflow', colors),
          _posRow('Fully closed', 'Zone satisfied, no airflow', colors),
          _posRow('Modulating', 'Partial open for balancing (some systems)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Dampers must be accessible for service. Install with direction arrow matching airflow.', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _damperRow(String type, String use, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 95, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posRow(String position, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 85, child: Text(position, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildBypassDamper(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowLeftRight, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('BYPASS DAMPER (CRITICAL)', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('When zones close, air has nowhere to go. Bypass damper relieves excess pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    SUPPLY PLENUM', colors.accentWarning),
                _diagramLine('    ═══════╤══════════════════', colors.accentWarning),
                _diagramLine('           │', colors.textTertiary),
                _diagramLine('        [BYPASS]  ← Opens when pressure rises', colors.accentError),
                _diagramLine('           │', colors.textTertiary),
                _diagramLine('    ═══════╧══════════════════', colors.accentInfo),
                _diagramLine('    RETURN PLENUM', colors.accentInfo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _bypassRow('Barometric', 'Weighted - opens from pressure', 'Simple, passive', colors),
          _bypassRow('Motorized', 'Opens based on zone panel signal', 'More precise', colors),
          _bypassRow('Modulating', 'Variable opening for pressure control', 'Best control', colors),
          const SizedBox(height: 12),
          Text('Without proper bypass, high static pressure can damage equipment and cause noise.', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _bypassRow(String type, String how, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(how, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneControls(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONE CONTROL LOGIC', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _logicRow('Single zone calls', 'That zone damper opens, equipment runs', colors),
          _logicRow('Multiple zones call', 'All calling zones open, equipment runs', colors),
          _logicRow('Mixed calls', 'System prioritizes (varies by panel)', colors),
          _logicRow('No zones call', 'All dampers close, equipment off', colors),
          const SizedBox(height: 12),
          Text('Priority Logic Options:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _prioRow('First call', 'First zone to call sets mode', colors),
          _prioRow('Majority', 'Most zones calling sets mode', colors),
          _prioRow('Priority zone', 'Designated zone always wins', colors),
          _prioRow('Equipment capacity', 'Switches to meet largest demand', colors),
        ],
      ),
    );
  }

  Widget _logicRow(String condition, String action, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(condition, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(action, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _prioRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDesignConsiderations(ZaftoColors colors) {
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
            Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('DESIGN CONSIDERATIONS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _designRow('Zone count', '2-4 zones typical residential', colors),
          _designRow('Minimum zone', '30% of total system capacity', colors),
          _designRow('Duct sizing', 'Size for worst-case (most zones closed)', colors),
          _designRow('Bypass sizing', 'Match smallest zone duct size', colors),
          _designRow('Equipment', 'Variable speed ideal for zoning', colors),
          const SizedBox(height: 12),
          Text('Best Practices:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Group similar exposures together\n• Separate floors as different zones\n• Keep bedrooms together if possible\n• High-load rooms may need own zone\n• Consider sun exposure for zone grouping', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _designRow(String item, String guideline, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(guideline, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('TROUBLESHOOTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _troubleRow('Zone won\'t heat/cool', 'Check damper operation, wiring, actuator', colors),
          _troubleRow('Equipment short cycles', 'Check bypass damper, static pressure', colors),
          _troubleRow('Noisy operation', 'High static pressure, damper flutter', colors),
          _troubleRow('Zone always calling', 'Thermostat issue, calibration', colors),
          _troubleRow('Damper stuck', 'Actuator failure, power, linkage', colors),
          _troubleRow('Panel no communication', 'Wiring, transformer, board failure', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String check, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(problem, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(check, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
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
            Text('CODE & REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Equipment must be rated for zoning\n'
            '• Bypass or relief required\n'
            '• Static pressure limits observed\n'
            '• Dampers accessible for service\n'
            '• Low-voltage wiring per NEC Article 725\n'
            '• No damper in sole return air path\n'
            '• Manufacturer installation guidelines\n'
            '• Each zone minimum 30% of capacity',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
