import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Condensate Drainage Diagram - Design System v2.6
class CondensateDrainageScreen extends ConsumerWidget {
  const CondensateDrainageScreen({super.key});

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
        title: Text('Condensate Drainage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildDrainPan(colors),
            const SizedBox(height: 16),
            _buildDrainLine(colors),
            const SizedBox(height: 16),
            _buildPTrap(colors),
            const SizedBox(height: 16),
            _buildSafetyDevices(colors),
            const SizedBox(height: 16),
            _buildCondensatePump(colors),
            const SizedBox(height: 16),
            _buildHighEfficiency(colors),
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
            Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('WHY CONDENSATE FORMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Air conditioning removes moisture from the air as it cools. This water must be safely drained away.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _sourceRow('Evaporator coil', 'Primary source - air cooled below dew point', colors),
          _sourceRow('90%+ furnace', 'Flue gas condensation in secondary heat exchanger', colors),
          _sourceRow('HRV/ERV', 'Core condensation in cold weather', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('A typical A/C system can produce 5-20 gallons of condensate per day in humid climates!', style: TextStyle(color: colors.accentInfo, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sourceRow(String source, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.droplet, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainPan(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DRAIN PAN TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _panRow('Primary pan', 'Built into air handler, directly under coil', 'Standard', colors),
          _panRow('Secondary pan', 'Beneath entire unit, catches overflow', 'Code required in attics', colors),
          _panRow('Auxiliary pan', 'External pan for added protection', 'Recommended', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    ┌────────────────────────────┐', colors.textTertiary),
                _diagramLine('    │      EVAPORATOR COIL       │', colors.accentInfo),
                _diagramLine('    │    ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼ ▼      │', colors.accentInfo),
                _diagramLine('    │ ╔════════════════════════╗ │', colors.accentWarning),
                _diagramLine('    │ ║    PRIMARY DRAIN PAN   ║─┼─→ PRIMARY DRAIN', colors.accentWarning),
                _diagramLine('    │ ╚════════════════════════╝ │', colors.accentWarning),
                _diagramLine('    └────────────────────────────┘', colors.textTertiary),
                _diagramLine('    ╔══════════════════════════════╗', colors.accentError),
                _diagramLine('    ║     SECONDARY DRAIN PAN      ║─→ SECONDARY DRAIN', colors.accentError),
                _diagramLine('    ╚══════════════════════════════╝   (visible location)', colors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panRow(String type, String desc, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainLine(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DRAIN LINE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _drainRow('Pipe size', '3/4" minimum (1" preferred)', colors),
          _drainRow('Material', 'PVC, CPVC, ABS, or copper', colors),
          _drainRow('Slope', '1/8" per foot minimum (1/4" ideal)', colors),
          _drainRow('Cleanout', 'At trap and direction changes', colors),
          _drainRow('Support', 'Every 4 feet horizontal', colors),
          const SizedBox(height: 12),
          Text('Termination Options:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _termRow('Floor drain', 'Indirect (air gap required)', colors),
          _termRow('Lavatory tailpiece', 'Above trap weir', colors),
          _termRow('Outside', 'Visible location, not on walkway', colors),
          _termRow('Condensate pump', 'When gravity drain not possible', colors),
        ],
      ),
    );
  }

  Widget _drainRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _termRow(String location, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(location, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildPTrap(ZaftoColors colors) {
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
            Icon(LucideIcons.arrowDownUp, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('P-TRAP REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Traps prevent air handler pressure from affecting drainage:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('  NEGATIVE PRESSURE (draw-through)', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('    FROM COIL', colors.accentInfo),
                _diagramLine('       │', colors.textTertiary),
                _diagramLine('       │', colors.textTertiary),
                _diagramLine('    ╔══╧══╗', colors.accentWarning),
                _diagramLine('    ║     ║ ← Trap depth > static pressure', colors.accentWarning),
                _diagramLine('    ║     ║   (typically 1-2")', colors.textTertiary),
                _diagramLine('    ╚══╤══╝', colors.accentWarning),
                _diagramLine('       │', colors.textTertiary),
                _diagramLine('       ▼', colors.textTertiary),
                _diagramLine('    TO DRAIN', colors.accentInfo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _trapRow('Negative pressure', 'Trap on OUTLET side of coil', colors),
          _trapRow('Positive pressure', 'Trap on INLET side of coil', colors),
          _trapRow('Trap depth', 'Must exceed unit static pressure', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Wrong trap location or depth can cause water to back up, overflow, or be sucked into the unit!', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _trapRow(String condition, String location, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(condition, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(location, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSafetyDevices(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.shieldAlert, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('SAFETY DEVICES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _safetyRow('Float switch (pan)', 'In secondary pan - shuts off unit if water accumulates', colors),
          _safetyRow('Float switch (line)', 'In drain line - detects clogs', colors),
          _safetyRow('Water sensor', 'Electronic sensor in pan or under unit', colors),
          _safetyRow('Overflow alarm', 'Alerts homeowner without shutdown', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code Required:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Secondary drain OR safety shutoff device required when unit is above ceiling or where leakage can cause damage.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyRow(String device, String function, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(device, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCondensatePump(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONDENSATE PUMPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Required when gravity drainage is not possible:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _pumpRow('Mini-split pump', 'Built into wall unit', colors),
          _pumpRow('External pump', 'Located near air handler', colors),
          _pumpRow('Lift capacity', 'Typically 15-20 feet', colors),
          _pumpRow('Reservoir size', 'Match to condensate production', colors),
          const SizedBox(height: 12),
          Text('Pump Requirements:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _pumpReq('Safety switch', 'Shuts off unit if pump fails', colors),
          _pumpReq('Check valve', 'Prevents backflow', colors),
          _pumpReq('Accessible', 'For cleaning and service', colors),
          _pumpReq('Discharge', 'Same as gravity drain', colors),
        ],
      ),
    );
  }

  Widget _pumpRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _pumpReq(String req, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(req, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildHighEfficiency(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.flame, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('HIGH-EFFICIENCY FURNACE CONDENSATE', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('90%+ AFUE furnaces produce acidic condensate from flue gas:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _heRow('pH level', '3.0-4.0 (acidic)', colors),
          _heRow('Production', '0.5-1 gallon per hour of operation', colors),
          _heRow('Drain material', 'PVC, CPVC, or ABS (not copper!)', colors),
          _heRow('Neutralizer', 'Required by some codes', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Acidic condensate can damage copper pipes, concrete, and septic systems. A neutralizer kit with calcium carbite chips raises pH before discharge.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _heRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.accentSuccess, fontSize: 11))),
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
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IMC Section 307 - Condensate Disposal\n'
            '• 3/4" minimum drain pipe size\n'
            '• Indirect connection to plumbing (air gap)\n'
            '• Trap required (proper depth for pressure)\n'
            '• Secondary drain OR safety device in attics\n'
            '• Cleanout access required\n'
            '• Drain pan required under all coils\n'
            '• Secondary pan separate drain to visible location\n'
            '• Neutralizer may be required (local code)',
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
