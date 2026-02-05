import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cleanout Locations Diagram - Design System v2.6
class CleanoutLocationsScreen extends ConsumerWidget {
  const CleanoutLocationsScreen({super.key});

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
        title: Text('Cleanout Locations', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildBuildingDrain(colors),
            const SizedBox(height: 16),
            _buildHorizontalRuns(colors),
            const SizedBox(height: 16),
            _buildStackBase(colors),
            const SizedBox(height: 16),
            _buildDirectionChange(colors),
            const SizedBox(height: 16),
            _buildCleanoutTypes(colors),
            const SizedBox(height: 16),
            _buildAccessibility(colors),
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
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('Why Cleanouts?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('Cleanouts provide access points for clearing blockages and inspecting drain lines. Proper placement is code-required and essential for maintenance.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          _purposeRow('Clear blockages', 'Snake or jet drain lines', colors),
          _purposeRow('Camera inspection', 'Locate damage or roots', colors),
          _purposeRow('Maintenance', 'Preventive cleaning access', colors),
        ],
      ),
    );
  }

  Widget _purposeRow(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(' - $desc', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingDrain(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUILDING DRAIN CLEANOUT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Required at upper end of building drain', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                    BUILDING', colors.textTertiary),
                _diagramLine('    ┌─────────────────────────────────────┐', colors.textTertiary),
                _diagramLine('    │                                     │', colors.textTertiary),
                _diagramLine('    │  [CO] ← Building drain cleanout     │', colors.accentPrimary),
                _diagramLine('    │   │     (upper terminal)            │', colors.textTertiary),
                _diagramLine('    │   │                                 │', colors.textTertiary),
                _diagramLine('    │ ══╧══════════════════════════ →     │', colors.accentWarning),
                _diagramLine('    │          Building Drain    ↓        │', colors.textTertiary),
                _diagramLine('    └────────────────────────────┼────────┘', colors.textTertiary),
                _diagramLine('                                 │', colors.textTertiary),
                _diagramLine('                            TO SEWER', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Located inside building at start of drain', colors),
          _infoItem('Must be same size as drain (3" or 4" typical)', colors),
          _infoItem('Two-way cleanout allows both directions', colors),
        ],
      ),
    );
  }

  Widget _buildHorizontalRuns(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HORIZONTAL RUN SPACING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Cleanouts required every 100 feet on horizontal runs', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('[CO]════════════════════[CO]════════════════════[CO]', colors.accentPrimary),
                _diagramLine(' │                       │                       │', colors.textTertiary),
                _diagramLine(' │←─── 100\' max ────────→│←─── 100\' max ────────→│', colors.accentWarning),
                _diagramLine(' │                       │                       │', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _spacingRow('Pipes 4" and smaller', '100 ft maximum spacing', colors),
          _spacingRow('Pipes larger than 4"', '100 ft maximum spacing', colors),
          _spacingRow('Sewer lateral', 'Every 100 ft to property line', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Some jurisdictions allow 75 ft for residential. Always verify local code.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _spacingRow(String pipe, String spacing, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(pipe, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(spacing, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStackBase(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STACK BASE CLEANOUT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Required at base of each soil/waste stack', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         ROOF', colors.textTertiary),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('          │ ← Vent through roof', colors.textTertiary),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('     ─────┼───── Fixture branch', colors.accentInfo),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('     ─────┼───── Fixture branch', colors.accentInfo),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('          │ ← STACK', colors.accentWarning),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('    ══════╧══════ Building drain', colors.accentWarning),
                _diagramLine('          │', colors.textTertiary),
                _diagramLine('         [CO] ← Stack base cleanout', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Within 10 ft of stack connection to drain', colors),
          _infoItem('Must be accessible (not buried)', colors),
          _infoItem('Opens in direction of flow', colors),
        ],
      ),
    );
  }

  Widget _buildDirectionChange(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIRECTION CHANGE CLEANOUT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Required at each aggregate change of direction exceeding 135 degrees', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     ══════════╗', colors.accentWarning),
                _diagramLine('               ║', colors.accentWarning),
                _diagramLine('              [CO] ← Cleanout at 90° bend', colors.accentPrimary),
                _diagramLine('               ║', colors.accentWarning),
                _diagramLine('               ╚══════════════', colors.accentWarning),
                _diagramLine('', colors.textTertiary),
                _diagramLine('  Two 45° = 90° total (OK)', colors.accentSuccess),
                _diagramLine('  Three 45° = 135° (OK)', colors.accentSuccess),
                _diagramLine('  Four 45° = 180° (NEEDS C/O)', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Aggregate means total of all bends', colors),
          _infoItem('Count all bends between cleanouts', colors),
          _infoItem('Cleanout opens toward upstream', colors),
        ],
      ),
    );
  }

  Widget _buildCleanoutTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLEANOUT TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _typeRow('Test tee', 'Y-fitting with removable plug, most common', colors),
          _typeRow('Two-way', 'Allows access in both directions', colors),
          _typeRow('Floor cleanout', 'Flush mount with cover plate', colors),
          _typeRow('Wall cleanout', 'Access plate in wall', colors),
          _typeRow('Outside cleanout', 'Ground-level access, frost-protected', colors),
          _typeRow('Stack cleanout', 'In vertical stack with access panel', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cleanout Sizing:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                _sizeRow('Drain 3" or smaller', 'Same size as drain', colors),
                _sizeRow('Drain 4" or larger', 'Minimum 4" cleanout', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _sizeRow(String drain, String cleanout, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(drain, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(cleanout, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAccessibility(ZaftoColors colors) {
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
            Icon(LucideIcons.doorOpen, color: colors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text('ACCESSIBILITY REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _accessRow('Clearance in front', '18" minimum for rodding', colors),
          _accessRow('Clearance above', '12" minimum', colors),
          _accessRow('Concealed cleanouts', 'Access panel required', colors),
          _accessRow('Underground', 'Extended to grade level', colors),
          _accessRow('Countersunk', 'Flush covers must be removable', colors),
          const SizedBox(height: 12),
          Text('Cleanouts must be accessible without removing permanent construction. A cleanout behind drywall requires an access panel.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _accessRow(String req, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(req, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            '• IPC Section 708 - Cleanouts\n'
            '• UPC Section 707 - Cleanouts\n'
            '• Required at upper terminal of building drain\n'
            '• Required at base of each stack\n'
            '• Every 100 ft on horizontal drains\n'
            '• At each aggregate 135° direction change\n'
            '• Must be same size as drain (4" max)\n'
            '• 18" clearance for access\n'
            '• Gastight/watertight plugs required',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
