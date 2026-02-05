import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Sump Pump Systems Diagram - Design System v2.6
class SumpPumpScreen extends ConsumerWidget {
  const SumpPumpScreen({super.key});

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
        title: Text('Sump Pump Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 16),
            _buildPumpTypes(colors),
            const SizedBox(height: 16),
            _buildSumpPit(colors),
            const SizedBox(height: 16),
            _buildDischargeRequirements(colors),
            const SizedBox(height: 16),
            _buildCheckValve(colors),
            const SizedBox(height: 16),
            _buildBackupSystems(colors),
            const SizedBox(height: 16),
            _buildInstallation(colors),
            const SizedBox(height: 16),
            _buildMaintenance(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUMP PUMP SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('          DISCHARGE TO EXTERIOR', colors.accentInfo),
                _diagramLine('                   ↑', colors.textTertiary),
                _diagramLine('               ════╧════ ← Discharge pipe', colors.accentWarning),
                _diagramLine('                   │', colors.textTertiary),
                _diagramLine('              ┌────┴────┐', colors.textTertiary),
                _diagramLine('  ═══════════ │         │ ════════════ FLOOR', colors.textTertiary),
                _diagramLine('              │   [X]   │ ← Check valve', colors.accentError),
                _diagramLine('              │    │    │', colors.textTertiary),
                _diagramLine('              │    │    │ ← Discharge', colors.textTertiary),
                _diagramLine('              │  ┌───┐  │', colors.accentPrimary),
                _diagramLine('              │  │ P │  │ ← Float switch', colors.accentWarning),
                _diagramLine('  ──→ water   │  │ U │○ │', colors.accentInfo),
                _diagramLine('              │  │ M │  │', colors.accentPrimary),
                _diagramLine('              │  │ P │  │', colors.accentPrimary),
                _diagramLine('              │  └───┘  │', colors.accentPrimary),
                _diagramLine('              └─────────┘ SUMP PIT', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Purpose: Removes groundwater from basement or crawl space to prevent flooding and water damage.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPumpTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PUMP TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _pumpRow('Submersible', 'In pit, sealed motor, quieter, efficient', 'Most common', colors),
          _pumpRow('Pedestal', 'Motor above pit, pump below, easier service', 'Budget option', colors),
          _pumpRow('Battery backup', 'DC powered, activates if primary fails', 'Insurance', colors),
          _pumpRow('Water-powered', 'Uses city water pressure, no electricity', 'Emergency backup', colors),
          _pumpRow('Combination', 'Primary + backup in one system', 'Best protection', colors),
          const SizedBox(height: 12),
          Text('Sizing Guide:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _sizeRow('Light use', '1/4 HP', colors),
                _sizeRow('Average home', '1/3 HP', colors),
                _sizeRow('High water table', '1/2 HP', colors),
                _sizeRow('Heavy use/deep pit', '3/4 - 1 HP', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pumpRow(String type, String desc, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

  Widget _sizeRow(String use, String hp, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(use, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(hp, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSumpPit(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.circle, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('SUMP PIT (BASIN)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _pitRow('Minimum size', '18" diameter x 24" deep', colors),
          _pitRow('Typical size', '18-24" diameter x 22-36" deep', colors),
          _pitRow('Material', 'Polyethylene, fiberglass, or concrete', colors),
          _pitRow('Cover', 'Required - prevents debris, radon, odors', colors),
          _pitRow('Drainage inlet', 'Perimeter drain tile connection', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Pit must be large enough to prevent rapid on/off cycling. Larger pit = fewer pump cycles = longer pump life.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _pitRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDischargeRequirements(ZaftoColors colors) {
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
            Icon(LucideIcons.arrowUpRight, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('DISCHARGE REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _dischargeRow('Pipe size', '1-1/2" minimum (1-1/4" from pump)', colors),
          _dischargeRow('Material', 'PVC, ABS, or approved', colors),
          _dischargeRow('Termination', '10 ft minimum from foundation', colors),
          _dischargeRow('Grade away', 'Must slope away from building', colors),
          _dischargeRow('Freeze protection', 'Below frost line or insulated', colors),
          const SizedBox(height: 12),
          Text('NEVER discharge to:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            '• Sanitary sewer (code violation)\n'
            '• Septic system (overloads treatment)\n'
            '• Neighbor\'s property\n'
            '• Street or sidewalk',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _dischargeRow(String item, String req, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(req, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCheckValve(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.arrowUpCircle, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('CHECK VALVE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Prevents water from flowing back into pit when pump stops:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _checkRow('Location', 'Above pump, accessible for service', colors),
          _checkRow('Type', 'Spring check or swing check', colors),
          _checkRow('Orientation', 'Arrow points UP (direction of flow)', colors),
          _checkRow('Air relief', 'Small hole above valve prevents airlock', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Without check valve, water flows back after each cycle, causing rapid on/off cycling and premature pump failure', style: TextStyle(color: colors.accentError, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String item, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(item, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildBackupSystems(ZaftoColors colors) {
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
            Icon(LucideIcons.shield, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('BACKUP SYSTEMS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Essential for homes with finished basements or high water tables:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _backupRow('Battery backup', 'DC pump with battery, 5-12 hours runtime', colors),
          _backupRow('Water-powered', 'Uses municipal pressure, unlimited runtime', colors),
          _backupRow('Generator', 'Powers primary pump during outage', colors),
          _backupRow('Combination', 'Primary + battery backup integrated', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Battery Backup Considerations:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 4),
                Text('• Typical battery lasts 3-5 years\n• Should be tested monthly\n• Consider deep-cycle marine battery\n• Charger should maintain battery', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupRow(String type, String details, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(details, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildInstallation(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wrench, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _tipRow('Pit base', 'Level surface, gravel base for stability', colors),
          _tipRow('Float switch', 'Test operation, clear travel path', colors),
          _tipRow('Discharge', 'Rigid pipe preferred over flex', colors),
          _tipRow('Electrical', 'Dedicated circuit, GFCI protected', colors),
          _tipRow('Air gap', '1/8" hole above check valve', colors),
          _tipRow('Cover', 'Airtight lid with discharge pipe seal', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Never plug sump pump into extension cord or power strip - use dedicated outlet', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String item, String tip, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(item, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildMaintenance(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MAINTENANCE SCHEDULE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _maintRow('Monthly', 'Pour water in pit, verify pump activates', colors),
          _maintRow('Quarterly', 'Clean pit of debris, check float', colors),
          _maintRow('Annually', 'Remove pump, clean intake screen', colors),
          _maintRow('Annually', 'Check/test backup battery', colors),
          _maintRow('Every 2-3 yrs', 'Test check valve for leaks', colors),
          _maintRow('Every 5-10 yrs', 'Consider pump replacement', colors),
          const SizedBox(height: 12),
          Text('Warning Signs:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Strange noises, vibration\n• Running constantly or not at all\n• Visible rust or corrosion\n• Burning smell', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _maintRow(String freq, String task, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(freq, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(task, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            '• IPC Section 712 - Sumps and Ejectors\n'
            '• Discharge cannot connect to sanitary sewer\n'
            '• Pit minimum 18" diameter x 24" deep\n'
            '• Tight-fitting cover required\n'
            '• Vent connection may be required\n'
            '• Check valve required on discharge\n'
            '• Electrical per NEC (GFCI, dedicated circuit)\n'
            '• Discharge 10 ft minimum from foundation',
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
