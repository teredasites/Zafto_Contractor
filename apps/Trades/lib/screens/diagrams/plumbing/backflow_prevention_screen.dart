import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Backflow Prevention Diagram - Design System v2.6
class BackflowPreventionScreen extends ConsumerWidget {
  const BackflowPreventionScreen({super.key});

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
        title: Text('Backflow Prevention', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildAirGap(colors),
            const SizedBox(height: 16),
            _buildAtmosphericVacuum(colors),
            const SizedBox(height: 16),
            _buildDoubleCheck(colors),
            const SizedBox(height: 16),
            _buildRPZ(colors),
            const SizedBox(height: 16),
            _buildApplicationGuide(colors),
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
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.shieldAlert, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('What is Backflow?', style: TextStyle(color: colors.accentError, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('Backflow is the undesirable reversal of water flow from a potentially contaminated source into the potable water supply.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Text('Two Causes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          _causeRow('Back-siphonage', 'Negative pressure in supply pulls contamination back', colors),
          _causeRow('Back-pressure', 'Higher pressure downstream pushes contamination back', colors),
        ],
      ),
    );
  }

  Widget _causeRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirGap(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentSuccess, borderRadius: BorderRadius.circular(4)),
              child: Text('HIGH', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
            ),
            const SizedBox(width: 10),
            Text('AIR GAP (AG)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Physical separation - most reliable protection', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    FAUCET', colors.accentInfo),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('      ▼', colors.accentInfo),
                _diagramLine('   ~~~~~~~~ AIR GAP', colors.accentSuccess),
                _diagramLine('   (2× diameter min)', colors.textTertiary),
                _diagramLine('   ~~~~~~~~', colors.accentSuccess),
                _diagramLine('      │', colors.textTertiary),
                _diagramLine('  ═══════════', colors.accentWarning),
                _diagramLine('    SINK', colors.accentWarning),
                _diagramLine('  FLOOD RIM', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Min 2× pipe diameter or 1" (whichever greater)', colors),
          _infoItem('No mechanical parts to fail', colors),
          _infoItem('Protects against back-siphonage and back-pressure', colors),
        ],
      ),
    );
  }

  Widget _buildAtmosphericVacuum(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(4)),
              child: Text('MED', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
            ),
            const SizedBox(width: 10),
            Text('ATMOSPHERIC VACUUM BREAKER (AVB)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Opens to atmosphere when pressure drops', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('       ┌───┐', colors.accentInfo),
                _diagramLine('       │AIR│ ← Opens when', colors.accentInfo),
                _diagramLine('       └─┬─┘   no pressure', colors.textTertiary),
                _diagramLine('  IN ───┴─── OUT', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Must be 6" above highest outlet', colors),
          _infoItem('Cannot have shut-off valve downstream', colors),
          _infoItem('Back-siphonage only (NOT back-pressure)', colors),
          _infoItem('Common: hose bibs, utility sinks', colors),
        ],
      ),
    );
  }

  Widget _buildDoubleCheck(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(4)),
              child: Text('MED', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
            ),
            const SizedBox(width: 10),
            Text('DOUBLE CHECK VALVE (DCV)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Two independent check valves in series', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    ┌─────┐     ┌─────┐', colors.accentWarning),
                _diagramLine('IN ─┤ CV1 ├─────┤ CV2 ├─ OUT', colors.accentWarning),
                _diagramLine('    └─────┘     └─────┘', colors.accentWarning),
                _diagramLine('     Check       Check', colors.textTertiary),
                _diagramLine('     Valve       Valve', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Protects against both back-siphonage and back-pressure', colors),
          _infoItem('Low hazard applications only', colors),
          _infoItem('Requires annual testing (testable type)', colors),
          _infoItem('Common: fire sprinklers, irrigation', colors),
        ],
      ),
    );
  }

  Widget _buildRPZ(ZaftoColors colors) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentError, borderRadius: BorderRadius.circular(4)),
              child: Text('HIGH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
            ),
            const SizedBox(width: 10),
            Text('RPZ (REDUCED PRESSURE ZONE)', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Highest mechanical protection - for high hazard', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    ┌─────┐ ┌─────┐ ┌─────┐', colors.accentPrimary),
                _diagramLine('IN ─┤ CV1 ├─┤RELIEF├─┤ CV2 ├─ OUT', colors.accentPrimary),
                _diagramLine('    └─────┘ └──┬──┘ └─────┘', colors.accentPrimary),
                _diagramLine('               │', colors.textTertiary),
                _diagramLine('               ▼', colors.accentError),
                _diagramLine('            DRAIN', colors.accentError),
                _diagramLine('        (relief valve)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Two check valves + pressure relief', colors),
          _infoItem('Relief opens if check fails (visible indication)', colors),
          _infoItem('Must install with air gap at relief', colors),
          _infoItem('Annual testing required', colors),
          _infoItem('High hazard: chemical injection, mortuaries, labs', colors),
        ],
      ),
    );
  }

  Widget _buildApplicationGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPLICATION GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _appRow('Hose bib', 'AVB or VB built-in', 'Low', colors),
          _appRow('Irrigation system', 'DCV or PVB', 'Low-Med', colors),
          _appRow('Fire sprinklers', 'DCV', 'Low', colors),
          _appRow('Boiler makeup', 'RPZ', 'High', colors),
          _appRow('Chemical injection', 'RPZ or AG', 'High', colors),
          _appRow('Medical equipment', 'RPZ', 'High', colors),
          _appRow('Dishwasher', 'Air gap at drain', 'Low', colors),
          _appRow('Water softener', 'Air gap or DCV', 'Low', colors),
        ],
      ),
    );
  }

  Widget _appRow(String application, String device, String hazard, ZaftoColors colors) {
    Color hazardColor = hazard == 'High' ? colors.accentError : hazard == 'Med' || hazard == 'Low-Med' ? colors.accentWarning : colors.accentSuccess;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(application, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(flex: 3, child: Text(device, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: hazardColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(hazard, style: TextStyle(color: hazardColor, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
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
            '• IPC Section 608 - Backflow Protection\n'
            '• UPC Section 603 - Cross-Connection Control\n'
            '• Must match protection level to hazard\n'
            '• Testable devices require annual testing\n'
            '• Install per manufacturer instructions\n'
            '• Water purveyor may require meter protection\n'
            '• ASSE standards for device certification',
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
