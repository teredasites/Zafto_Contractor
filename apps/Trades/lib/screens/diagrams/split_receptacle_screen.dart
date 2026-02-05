import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Split Receptacle Wiring Diagram - Design System v2.6
class SplitReceptacleScreen extends ConsumerWidget {
  const SplitReceptacleScreen({super.key});

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
        title: Text('Split Receptacle Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildBreakTab(colors),
            const SizedBox(height: 16),
            _buildSwitchedSplit(colors),
            const SizedBox(height: 16),
            _buildMWBCSplit(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
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
            Icon(LucideIcons.plug, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('What is a Split Receptacle?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('A split receptacle has each outlet (top and bottom) wired separately. Common uses:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          _bulletItem('Half-hot: One outlet always on, one switch-controlled', colors),
          _bulletItem('MWBC: Each outlet on different circuit leg (shares neutral)', colors),
          _bulletItem('Dedicated: Each outlet on completely separate circuit', colors),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBreakTab(ZaftoColors colors) {
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
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('CRITICAL: Break the Tab!', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('      HOT SIDE          NEUTRAL SIDE', colors.textTertiary),
                _diagramLine('    ┌─────────┐        ┌─────────┐', colors.textTertiary),
                _diagramLine('    │  BRASS  │        │ SILVER  │', colors.accentWarning),
                _diagramLine('    │  SCREW  │        │  SCREW  │', colors.textTertiary),
                _diagramLine('    ├────┬────┤        ├────┬────┤', colors.textTertiary),
                _diagramLine('    │    │    │        │    │    │', colors.textTertiary),
                _diagramLine('    │  ──┴──  │ ← BREAK│  ──┴──  │ ← KEEP', colors.accentError),
                _diagramLine('    │   TAB   │   THIS │   TAB   │  INTACT', colors.accentError),
                _diagramLine('    │    │    │        │    │    │', colors.textTertiary),
                _diagramLine('    ├────┴────┤        ├────┴────┤', colors.textTertiary),
                _diagramLine('    │  BRASS  │        │ SILVER  │', colors.accentWarning),
                _diagramLine('    │  SCREW  │        │  SCREW  │', colors.textTertiary),
                _diagramLine('    └─────────┘        └─────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Break HOT side tab (brass screws) with pliers', colors),
          _infoItem('KEEP neutral tab intact (silver screws)', colors),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Breaking neutral tab can cause dangerous conditions', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _infoItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.textSecondary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildSwitchedSplit(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HALF-HOT (SWITCH CONTROLLED)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Top outlet always on, bottom controlled by switch (for lamp)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('Panel    Switch Box              Outlet Box', colors.textTertiary),
                _diagramLine('  │      ┌───────┐              ┌─────────┐', colors.textTertiary),
                _diagramLine('  │      │       │   Red        │ ○ TOP   │ ← Always Hot', colors.accentSuccess),
                _diagramLine('  │ Blk  │   S   │──────────────│(constant)│', colors.textTertiary),
                _diagramLine('  ├──────┤       │              ├─────────┤', colors.accentError),
                _diagramLine('  │      │       │   Black      │ ○ BOT   │ ← Switched', colors.accentWarning),
                _diagramLine('  │      └───┬───┘──────────────│(switched)│', colors.textTertiary),
                _diagramLine('  │          │                  └─────────┘', colors.textTertiary),
                _diagramLine('  │ Wht     Wht ─────────────────── Wht', colors.textSecondary),
                _diagramLine('  │ Gnd     Gnd ─────────────────── Gnd', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Requires 14/3 or 12/3 cable from switch to outlet', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMWBCSplit(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MWBC SPLIT RECEPTACLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Each outlet on different leg - shares neutral (kitchen countertop)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL                         OUTLET', colors.textTertiary),
                _diagramLine('┌──────┐                    ┌─────────┐', colors.textTertiary),
                _diagramLine('│ 20A  │─── L1 (Black) ────►│ ○ TOP   │ Circuit A', colors.accentError),
                _diagramLine('│(tied)│                    │  120V   │', colors.textTertiary),
                _diagramLine('│ 20A  │─── L2 (Red) ──────►│ ○ BOT   │ Circuit B', colors.accentError),
                _diagramLine('└──┬───┘                    │  120V   │', colors.textTertiary),
                _diagramLine('   │                        └────┬────┘', colors.textTertiary),
                _diagramLine('   │ Neutral (shared) ──────────┘', colors.textSecondary),
                const SizedBox(height: 8),
                _diagramLine('L1 to L2 = 240V (opposite legs)', colors.accentWarning),
                _diagramLine('Neutral carries DIFFERENCE, not sum', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('MWBC requires handle-tied or 2-pole breaker per NEC 210.4(B). Both legs must disconnect together.', style: TextStyle(color: colors.accentError, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildWiringSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRING STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Turn OFF power at breaker', colors),
          _stepItem('2', 'Break hot-side tab with needle-nose pliers', colors),
          _stepItem('3', 'Verify neutral tab is INTACT', colors),
          _stepItem('4', 'Connect first hot wire to top brass screw', colors),
          _stepItem('5', 'Connect second hot wire to bottom brass screw', colors),
          _stepItem('6', 'Connect neutral to one silver screw (tab connects both)', colors),
          _stepItem('7', 'Connect ground to green screw', colors),
          _stepItem('8', 'Install outlet and test both halves', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(num, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• 210.4(B) - MWBC requires simultaneous disconnect\n'
            '• 210.4(D) - MWBC neutrals grouped at panel\n'
            '• 210.7 - Split receptacle must have tab broken\n'
            '• 210.52 - Kitchen countertop: 2 circuits required\n'
            '• Split receptacles count as 2 outlets for counting',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
