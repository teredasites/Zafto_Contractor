import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Trap Requirements Diagram - Design System v2.6
class TrapRequirementsScreen extends ConsumerWidget {
  const TrapRequirementsScreen({super.key});

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
        title: Text('Trap Requirements', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPurpose(colors),
            const SizedBox(height: 16),
            _buildPTrap(colors),
            const SizedBox(height: 16),
            _buildTrapSeal(colors),
            const SizedBox(height: 16),
            _buildTrapArm(colors),
            const SizedBox(height: 16),
            _buildProhibitedTraps(colors),
            const SizedBox(height: 16),
            _buildSpecialTraps(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPurpose(ZaftoColors colors) {
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
            Text('Purpose of Traps', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('Traps create a WATER SEAL that prevents sewer gases from entering the building while allowing wastewater to flow through.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    FIXTURE', colors.accentInfo),
                _diagramLine('       │', colors.textTertiary),
                _diagramLine('       ▼', colors.textTertiary),
                _diagramLine('    ┌─────┐', colors.accentWarning),
                _diagramLine('    │~~~~~│ ← WATER SEAL', colors.accentInfo),
                _diagramLine('    │~~~~~│   (blocks gases)', colors.textTertiary),
                _diagramLine('    └──┬──┘', colors.accentWarning),
                _diagramLine('       │', colors.textTertiary),
                _diagramLine('    TO DRAIN', colors.accentError),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPTrap(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('P-TRAP (MOST COMMON)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('      FROM FIXTURE', colors.accentInfo),
                _diagramLine('           │', colors.textTertiary),
                _diagramLine('           │ INLET', colors.textTertiary),
                _diagramLine('       ────┘', colors.accentWarning),
                _diagramLine('      │', colors.accentWarning),
                _diagramLine('      │~~~~│ ← TRAP SEAL', colors.accentInfo),
                _diagramLine('      │~~~~│   (2-4" depth)', colors.textTertiary),
                _diagramLine('      └────┼────────', colors.accentWarning),
                _diagramLine('           │ OUTLET', colors.textTertiary),
                _diagramLine('           │', colors.textTertiary),
                _diagramLine('      TO TRAP ARM', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _featureRow('Inlet', 'Vertical drop from fixture', colors),
          _featureRow('Crown weir', 'Highest point of trap interior', colors),
          _featureRow('Trap seal', 'Water depth (2-4" required)', colors),
          _featureRow('Outlet', 'Horizontal to trap arm/vent', colors),
        ],
      ),
    );
  }

  Widget _featureRow(String label, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTrapSeal(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('TRAP SEAL REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _sealRow('Minimum seal depth', '2 inches', colors),
          _sealRow('Maximum seal depth', '4 inches', colors),
          _sealRow('Floor drains', '2" (3" in high-evap areas)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                  const SizedBox(width: 8),
                  Text('TRAP SEAL FAILURE', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 11)),
                ]),
                const SizedBox(height: 8),
                Text('• Siphonage - negative pressure pulls water out\n• Evaporation - unused fixtures dry out\n• Back pressure - positive pressure pushes seal out\n• Capillary action - hair/debris wicks water', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sealRow(String label, String value, ZaftoColors colors) {
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

  Widget _buildTrapArm(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRAP ARM (FIXTURE DRAIN)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Distance from trap weir to vent connection', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                                    VENT', colors.accentSuccess),
                _diagramLine('                                      │', colors.accentSuccess),
                _diagramLine('  [TRAP]────────────────────────────┬─┘', colors.accentWarning),
                _diagramLine('         │←───── TRAP ARM ─────────→│', colors.accentPrimary),
                _diagramLine('                                    │', colors.textTertiary),
                _diagramLine('                               TO DRAIN', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Maximum Trap Arm Length (IPC):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          _armRow('1-1/4"', '30 inches (2.5 ft)', colors),
          _armRow('1-1/2"', '42 inches (3.5 ft)', colors),
          _armRow('2"', '60 inches (5 ft)', colors),
          _armRow('3"', '72 inches (6 ft)', colors),
          _armRow('4"', '120 inches (10 ft)', colors),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('UPC uses different values - always check local code', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _armRow(String size, String length, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(size, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(length, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildProhibitedTraps(ZaftoColors colors) {
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
            Icon(LucideIcons.ban, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('PROHIBITED TRAPS', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _prohibitedRow('S-Trap', 'Self-siphoning - no vent path', colors),
          _prohibitedRow('Bell Trap', 'Easily loses seal', colors),
          _prohibitedRow('Crown Vent', 'Vent at crown weir causes siphoning', colors),
          _prohibitedRow('Drum Trap', 'Difficult to clean (grandfathered only)', colors),
          _prohibitedRow('Mechanical Trap', 'Moving parts fail', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('S-TRAP (why it fails):', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 6),
                _diagramLine('    FROM FIXTURE', colors.accentInfo),
                _diagramLine('        │', colors.textTertiary),
                _diagramLine('     ───┘', colors.accentWarning),
                _diagramLine('    │', colors.accentWarning),
                _diagramLine('    │~~~~│', colors.accentInfo),
                _diagramLine('    └────┘', colors.accentWarning),
                _diagramLine('         │', colors.textTertiary),
                _diagramLine('         │ ← Vertical drop', colors.accentError),
                _diagramLine('         │    siphons trap!', colors.accentError),
                _diagramLine('    TO DRAIN', colors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prohibitedRow(String trap, String reason, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trap, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(reason, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTraps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPECIAL TRAP TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _specialRow('Floor Drain Trap', 'P-trap with cleanout, often needs trap primer', colors),
          _specialRow('Running Trap', 'Horizontal trap, used for building trap (where required)', colors),
          _specialRow('Deep Seal Trap', '4" seal for floor drains in high evaporation areas', colors),
          _specialRow('Grease Trap', 'Intercepts grease before drain (commercial kitchens)', colors),
          _specialRow('Interceptor', 'Catches solids (sand, oil, hair) - requires maintenance', colors),
        ],
      ),
    );
  }

  Widget _specialRow(String name, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            '• Every fixture must have a trap (IPC 1002.1)\n'
            '• Trap must be same size as fixture drain\n'
            '• Trap seal: 2" minimum, 4" maximum\n'
            '• Each fixture requires individual trap (exceptions: 3-compartment sink)\n'
            '• Trap must be accessible for cleaning\n'
            '• Water closets have integral traps\n'
            '• Trap arm slope: 1/4" per foot max\n'
            '• No double trapping allowed',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
            child: Text('IPC Chapter 10, UPC Chapter 10', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
