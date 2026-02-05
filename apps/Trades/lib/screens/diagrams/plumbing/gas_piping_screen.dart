import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Gas Piping Diagram - Design System v2.6
class GasPipingScreen extends ConsumerWidget {
  const GasPipingScreen({super.key});

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
        title: Text('Gas Piping', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyWarning(colors),
            const SizedBox(height: 16),
            _buildSystemDiagram(colors),
            const SizedBox(height: 16),
            _buildPipeMaterials(colors),
            const SizedBox(height: 16),
            _buildSedimentTrap(colors),
            const SizedBox(height: 16),
            _buildCSST(colors),
            const SizedBox(height: 16),
            _buildPressureTesting(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
            const SizedBox(width: 10),
            Text('GAS SAFETY WARNING', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Gas work requires licensed professional in most jurisdictions\n'
            '• Always check for leaks with soap solution or detector\n'
            '• Never use open flame to check for leaks\n'
            '• Know location of main shut-off valve\n'
            '• If you smell gas: evacuate, call from outside',
            style: TextStyle(color: colors.textPrimary, fontSize: 12, height: 1.5),
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
          Text('TYPICAL GAS PIPING SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('GAS MAIN (utility)', colors.textTertiary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('═══════════ GAS METER', colors.accentWarning),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('   [X] MAIN SHUT-OFF', colors.accentError),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    │ (black iron pipe)', colors.textTertiary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    ├────────┬────────┬────────┐', colors.accentWarning),
                _diagramLine('    │        │        │        │', colors.textTertiary),
                _diagramLine('   [X]      [X]      [X]      [X] ← Appliance', colors.accentError),
                _diagramLine('    │        │        │        │    shut-offs', colors.textTertiary),
                _diagramLine('    ║        ║        │        │', colors.textTertiary),
                _diagramLine('  DRIP     DRIP    [DRYER]  [RANGE]', colors.accentPrimary),
                _diagramLine('   LEG      LEG', colors.textTertiary),
                _diagramLine('    │        │', colors.textTertiary),
                _diagramLine('[W/H]    [FURNACE]', colors.accentPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeMaterials(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPROVED PIPE MATERIALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _materialRow('Black Iron (Steel)', 'Most common, threaded connections, interior only', true, colors),
          _materialRow('CSST (Yellow)', 'Corrugated Stainless Steel Tubing, flexible', true, colors),
          _materialRow('Copper (Type L/K)', 'Where approved, brazed joints', true, colors),
          _materialRow('PE (Polyethylene)', 'Underground only, yellow', true, colors),
          const SizedBox(height: 10),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 10),
          Text('NOT ALLOWED:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _materialRow('Galvanized pipe', 'Internal flaking clogs orifices', false, colors),
          _materialRow('PVC/CPVC', 'Not rated for gas', false, colors),
          _materialRow('Cast iron', 'Brittle, not approved', false, colors),
        ],
      ),
    );
  }

  Widget _materialRow(String material, String note, bool allowed, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(allowed ? LucideIcons.check : LucideIcons.x, color: allowed ? colors.accentSuccess : colors.accentError, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedimentTrap(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.filter, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('SEDIMENT TRAP (DRIP LEG)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Required at each appliance to catch debris and moisture', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('  GAS SUPPLY', colors.accentWarning),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('  ────┼──── TO APPLIANCE', colors.accentWarning),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('     [X] SHUT-OFF VALVE', colors.accentError),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('      │ ← Sediment Trap', colors.accentPrimary),
                _diagramLine('      │    (Drip Leg)', colors.textTertiary),
                _diagramLine('      │    Min 3" length', colors.textTertiary),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('     [■] CAPPED END', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Minimum 3" long, same size as supply pipe', colors),
          _infoItem('Installed as close to appliance as practical', colors),
          _infoItem('Union or cap for cleaning access', colors),
          _infoItem('Required by IFGC 408.4', colors),
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

  Widget _buildCSST(ZaftoColors colors) {
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
            Icon(LucideIcons.zap, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('CSST BONDING REQUIREMENT', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('CSST (Corrugated Stainless Steel Tubing) requires electrical bonding to prevent lightning damage:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _csstRow('Bonding conductor', '6 AWG copper minimum', colors),
          _csstRow('Connection point', 'Fitting at manifold or before first tee', colors),
          _csstRow('Bond to', 'Grounding electrode system', colors),
          _csstRow('Clamp type', 'Listed for gas pipe bonding', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Some jurisdictions require bonding even for black iron - check local code. Lightning can arc through ungrounded gas pipe causing fire.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _csstRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildPressureTesting(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('PRESSURE TESTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('New gas piping must be pressure tested before use:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _testRow('Test medium', 'Air or nitrogen (NOT gas)', colors),
          _testRow('Test pressure', '3 PSI minimum (10 PSI typical)', colors),
          _testRow('Duration', '10 minutes minimum', colors),
          _testRow('Acceptance', 'No pressure drop', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leak Detection:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Apply soap solution to joints\n• Look for bubbles forming\n• Electronic leak detectors for verification\n• NEVER use flame to test', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _testRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
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
            Text('CODE REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IFGC (International Fuel Gas Code)\n'
            '• NFPA 54 (National Fuel Gas Code)\n'
            '• IFGC 403 - Pipe sizing tables\n'
            '• IFGC 406 - Installation requirements\n'
            '• IFGC 406.4 - Sediment trap\n'
            '• IFGC 406.6.1 - CSST bonding\n'
            '• IFGC 406.4.2 - Shut-off valves\n'
            '• IFGC 406.1 - Testing requirements',
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
