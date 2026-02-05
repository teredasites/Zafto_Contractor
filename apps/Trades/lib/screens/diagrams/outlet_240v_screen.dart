import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// 240V Outlet Wiring Diagram - Design System v2.6
class Outlet240VScreen extends ConsumerWidget {
  const Outlet240VScreen({super.key});

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
        title: Text('240V Outlet Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoltageExplainer(colors),
            const SizedBox(height: 16),
            _build30AmpDryer(colors),
            const SizedBox(height: 16),
            _build50AmpRange(colors),
            const SizedBox(height: 16),
            _build20Amp240V(colors),
            const SizedBox(height: 16),
            _buildWireSizing(colors),
            const SizedBox(height: 16),
            _buildBreakerRequirements(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildVoltageExplainer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('240V vs 120V', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('A 240V circuit uses TWO hot legs (L1 and L2) from the panel, each 120V to ground but 240V between them. Used for high-power appliances.', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          _voltRow('120V circuit', '1 hot + 1 neutral + ground', colors),
          _voltRow('240V circuit', '2 hots + ground (no neutral for pure 240V)', colors),
          _voltRow('120/240V circuit', '2 hots + neutral + ground (dryers, ranges)', colors),
        ],
      ),
    );
  }

  Widget _voltRow(String type, String config, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 110, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(config, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _build30AmpDryer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30A DRYER OUTLET (NEMA 14-30)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    NEMA 14-30 OUTLET', colors.accentPrimary),
                _diagramLine('    ┌─────────────┐', colors.textTertiary),
                _diagramLine('    │   L1   L2   │', colors.accentError),
                _diagramLine('    │   ○     ○   │ ← 240V between L1 & L2', colors.accentError),
                _diagramLine('    │             │', colors.textTertiary),
                _diagramLine('    │ G         N │', colors.textTertiary),
                _diagramLine('    │ ○         ○ │ ← Ground (L) Neutral (right)', colors.textTertiary),
                _diagramLine('    └─────────────┘', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('WIRING:', colors.textPrimary),
                _diagramLine('• L1 (black) ──► Hot terminal 1', colors.accentError),
                _diagramLine('• L2 (red) ────► Hot terminal 2', colors.accentError),
                _diagramLine('• N (white) ───► Neutral terminal', colors.textSecondary),
                _diagramLine('• G (green) ───► Ground terminal', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _specRow('Wire Size', '10 AWG copper (10/3 NM or THHN in conduit)', colors),
          _specRow('Breaker', '30A 2-pole', colors),
          _specRow('Usage', 'Electric dryers, EV chargers (Level 2)', colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11));
  }

  Widget _specRow(String spec, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text(spec, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _build50AmpRange(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('50A RANGE OUTLET (NEMA 14-50)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    NEMA 14-50 OUTLET', colors.accentPrimary),
                _diagramLine('    ┌─────────────┐', colors.textTertiary),
                _diagramLine('    │ L1       L2 │', colors.accentError),
                _diagramLine('    │  \\       /  │ ← Angled hot slots', colors.accentError),
                _diagramLine('    │   \\     /   │', colors.textTertiary),
                _diagramLine('    │    \\   /    │', colors.textTertiary),
                _diagramLine('    │ G   ─   N   │', colors.textTertiary),
                _diagramLine('    │ ○       ○   │ ← Round G, straight N', colors.textTertiary),
                _diagramLine('    └─────────────┘', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('WIRING:', colors.textPrimary),
                _diagramLine('• L1 (black) ──► Upper left (angled)', colors.accentError),
                _diagramLine('• L2 (red) ────► Upper right (angled)', colors.accentError),
                _diagramLine('• N (white) ───► Lower right (straight)', colors.textSecondary),
                _diagramLine('• G (green) ───► Lower left (round)', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _specRow('Wire Size', '6 AWG copper (6/3 NM or THHN in conduit)', colors),
          _specRow('Breaker', '50A 2-pole', colors),
          _specRow('Usage', 'Electric ranges/ovens, high-power EV chargers', colors),
        ],
      ),
    );
  }

  Widget _build20Amp240V(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('20A 240V OUTLET (NEMA 6-20)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    NEMA 6-20 OUTLET', colors.accentPrimary),
                _diagramLine('    ┌─────────────┐', colors.textTertiary),
                _diagramLine('    │  L1     L2  │', colors.accentError),
                _diagramLine('    │  ─      ─   │ ← Horizontal slots', colors.accentError),
                _diagramLine('    │             │', colors.textTertiary),
                _diagramLine('    │      G      │', colors.accentSuccess),
                _diagramLine('    │      ○      │ ← Round ground only', colors.accentSuccess),
                _diagramLine('    └─────────────┘', colors.textTertiary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('NO NEUTRAL - Pure 240V only!', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _specRow('Wire Size', '12 AWG copper (12/2 NM)', colors),
          _specRow('Breaker', '20A 2-pole', colors),
          _specRow('Usage', 'Window A/C, small welders, shop equipment', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('NEMA 6-series outlets have NO neutral - used for equipment that only needs 240V (no 120V internal circuits).', style: TextStyle(color: colors.accentInfo, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildWireSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRE SIZING CHART', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _tableHeader(['Circuit', 'Copper', 'Cable Type', 'Outlet'], colors),
              _tableRow(['20A 240V', '12 AWG', '12/2 NM', 'NEMA 6-20'], colors),
              _tableRow(['30A 240V', '10 AWG', '10/2 NM', 'NEMA 6-30'], colors),
              _tableRow(['30A 120/240V', '10 AWG', '10/3 NM', 'NEMA 14-30'], colors),
              _tableRow(['50A 120/240V', '6 AWG', '6/3 NM', 'NEMA 14-50'], colors, isLast: true),
            ]),
          ),
          const SizedBox(height: 12),
          Text('For aluminum wire, increase by 2 AWG sizes. Check NEC 310 tables for exact ampacity.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11))),
      child: Row(children: headers.map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10)))).toList()),
    );
  }

  Widget _tableRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: values.asMap().entries.map((e) => Expanded(child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400, fontSize: 11)))).toList()),
    );
  }

  Widget _buildBreakerRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('BREAKER REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          ]),
          const SizedBox(height: 12),
          _reqRow('2-Pole Breaker', 'Must use a 2-pole breaker that trips both legs together', colors),
          _reqRow('Tied Handles', 'If using two single-pole, handles MUST be tied together', colors),
          _reqRow('GFCI Protection', 'Required for 240V outdoor, garage, basement outlets (NEC 2023)', colors),
          _reqRow('Dedicated Circuit', 'Large appliances require dedicated circuits', colors),
        ],
      ),
    );
  }

  Widget _reqRow(String req, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.check, color: colors.accentWarning, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3))),
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
            '• NEC 210.8 - GFCI Requirements (expanded for 240V in 2023)\n'
            '• NEC 210.21 - Outlet Device Ratings\n'
            '• NEC 240.4 - Overcurrent Protection\n'
            '• NEC 250.140 - Frames of Ranges and Dryers\n'
            '• NEC 406.4 - Receptacle Requirements',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
