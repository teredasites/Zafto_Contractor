import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// 4-Way Switch Wiring Diagram - Design System v2.6
class FourWaySwitchScreen extends ConsumerWidget {
  const FourWaySwitchScreen({super.key});

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
        title: Text(
          '4-Way Switch Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildDiagramCard(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildTerminalGuide(colors),
            const SizedBox(height: 16),
            _buildMultipleLocations(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
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
          Row(
            children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text('When to Use 4-Way Switches', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A 4-way switch is used when you want to control a light from THREE OR MORE locations. Always used BETWEEN two 3-way switches.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          _locationRow('2 locations', '2 × 3-way switches', colors),
          _locationRow('3 locations', '2 × 3-way + 1 × 4-way', colors),
          _locationRow('4 locations', '2 × 3-way + 2 × 4-way', colors),
          _locationRow('5+ locations', '2 × 3-way + (n-2) × 4-way', colors),
        ],
      ),
    );
  }

  Widget _locationRow(String locations, String switches, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(locations, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(switches, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildDiagramCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4-WAY SWITCH CIRCUIT (3 Locations)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('     POWER SOURCE (120V)', colors.accentError),
                _diagramLine('           │', colors.accentError),
                _diagramLine('     ┌─────┴─────┐', colors.textTertiary),
                _diagramLine('     │  3-WAY    │ ◄── Switch 1 (end)', colors.accentPrimary),
                _diagramLine('     │  SWITCH   │     HOT to COMMON', colors.textTertiary),
                _diagramLine('     └──┬───┬────┘', colors.textTertiary),
                _diagramLine('        │   │ TRAVELERS', colors.accentInfo),
                _diagramLine('     ┌──┴───┴────┐', colors.textTertiary),
                _diagramLine('     │  4-WAY    │ ◄── Switch 2 (middle)', colors.accentWarning),
                _diagramLine('     │  SWITCH   │     Travelers IN → OUT', colors.textTertiary),
                _diagramLine('     └──┬───┬────┘', colors.textTertiary),
                _diagramLine('        │   │ TRAVELERS', colors.accentInfo),
                _diagramLine('     ┌──┴───┴────┐', colors.textTertiary),
                _diagramLine('     │  3-WAY    │ ◄── Switch 3 (end)', colors.accentPrimary),
                _diagramLine('     │  SWITCH   │     COMMON to LIGHT', colors.textTertiary),
                _diagramLine('     └─────┬─────┘', colors.textTertiary),
                _diagramLine('           │', colors.accentWarning),
                _diagramLine('      ┌────┴────┐', colors.textTertiary),
                _diagramLine('      │  LIGHT  │', colors.accentSuccess),
                _diagramLine('      └────┬────┘', colors.textTertiary),
                _diagramLine('           │', colors.textSecondary),
                _diagramLine('       NEUTRAL', colors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildWiringSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRING STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Turn OFF power and verify with tester', colors),
          _stepItem('2', 'Connect HOT from panel to COMMON of first 3-way switch', colors),
          _stepItem('3', 'Connect travelers from first 3-way to INPUT side of 4-way', colors),
          _stepItem('4', 'Connect OUTPUT side of 4-way to travelers going to second 3-way', colors),
          _stepItem('5', 'Connect COMMON of second 3-way to light fixture', colors),
          _stepItem('6', 'Connect all neutrals together', colors),
          _stepItem('7', 'Connect all grounds together and to each switch', colors),
          _stepItem('8', 'Test from all locations', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(number, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTerminalGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('4-WAY SWITCH TERMINALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('4-Way Switch has 4 terminals (+ ground):', colors.textPrimary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('  ┌─────────────────────┐', colors.textTertiary),
                _diagramLine('  │   IN         OUT    │', colors.accentPrimary),
                _diagramLine('  │   ○           ○     │ ← Traveler pair 1', colors.accentInfo),
                _diagramLine('  │                     │', colors.textTertiary),
                _diagramLine('  │   ○           ○     │ ← Traveler pair 2', colors.accentInfo),
                _diagramLine('  │   IN         OUT    │', colors.accentPrimary),
                _diagramLine('  └─────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _terminalRow('INPUT (2 screws)', 'Connect to travelers FROM previous switch', colors),
          _terminalRow('OUTPUT (2 screws)', 'Connect to travelers TO next switch', colors),
          _terminalRow('Ground (green)', 'Connect to equipment ground', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('The 4-way switch crosses travelers internally. Check manufacturer diagram - some have different terminal arrangements.', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalRow(String terminal, String purpose, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(terminal, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMultipleLocations(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADDING MORE LOCATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('For each additional control location beyond 3, add another 4-way switch in the middle:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('4 Locations:', colors.textPrimary),
                _diagramLine('3-way → 4-way → 4-way → 3-way', colors.accentPrimary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('5 Locations:', colors.textPrimary),
                _diagramLine('3-way → 4-way → 4-way → 4-way → 3-way', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Always start and end with 3-way switches. All middle switches are 4-way.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('TROUBLESHOOTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          _troubleRow("Light doesn't work at all", 'Check power at first 3-way common. Verify switch leg at light.', colors),
          _troubleRow('Works from some switches', '4-way may have input/output reversed. Check traveler continuity.', colors),
          _troubleRow('Light stuck on or off', 'Travelers may be crossed at 4-way switch', colors),
          _troubleRow('Works erratically', 'Loose connection at one of the switches', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: colors.accentError, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(problem, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w500, fontSize: 13))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(solution, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• NEC 404.2 - Switch Connections\n'
            '• NEC 404.2(C) - Neutral Required at Switch (for electronic switches)\n'
            '• NEC 404.9(B) - Grounding of Switches\n'
            '• NEC 210.70 - Lighting Outlet Requirements',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
