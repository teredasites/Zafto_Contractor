import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Recessed Lighting Wiring Diagram - Design System v2.6
class RecessedLightingScreen extends ConsumerWidget {
  const RecessedLightingScreen({super.key});

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
        title: Text('Recessed Lighting Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicWiring(colors),
            const SizedBox(height: 16),
            _buildDaisyChain(colors),
            const SizedBox(height: 16),
            _buildICRatings(colors),
            const SizedBox(height: 16),
            _buildSpacing(colors),
            const SizedBox(height: 16),
            _buildDimmerCompatibility(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('BASIC RECESSED LIGHT WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('SWITCH BOX                    JUNCTION BOX', colors.textTertiary),
                _diagramLine('┌─────────┐                  ┌─────────┐', colors.textTertiary),
                _diagramLine('│         │    14/2 NM      │  ┌───┐  │', colors.textTertiary),
                _diagramLine('│ SWITCH  │─────────────────│  │CAN│  │', colors.accentPrimary),
                _diagramLine('│         │  Black (swt)    │  │   │  │', colors.accentError),
                _diagramLine('│         │  White (neu)    │  └───┘  │', colors.textSecondary),
                _diagramLine('│         │  Bare (gnd)     │         │', colors.accentSuccess),
                _diagramLine('└─────────┘                  └─────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Most LED cans have integrated J-box', colors),
          _infoItem('Old-work cans: cut hole, fish wire, clip in', colors),
          _infoItem('New-work cans: nail to joist before drywall', colors),
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
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildDaisyChain(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAISY CHAIN MULTIPLE LIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('SWITCH ──► CAN 1 ──► CAN 2 ──► CAN 3 ──► CAN 4', colors.accentPrimary),
                _diagramLine('              │        │        │        │', colors.textTertiary),
                _diagramLine('           ┌──┴──┐  ┌──┴──┐  ┌──┴──┐  ┌──┴──┐', colors.textTertiary),
                _diagramLine('           │J-BOX│  │J-BOX│  │J-BOX│  │J-BOX│', colors.textTertiary),
                _diagramLine('           │IN OUT│  │IN OUT│  │IN OUT│  │IN   │', colors.textSecondary),
                _diagramLine('           └─────┘  └─────┘  └─────┘  └─────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Connect black to black, white to white, ground to ground', colors),
          _infoItem('Each can has IN and OUT knockouts', colors),
          _infoItem('Max lights per circuit: 12 on 15A, 16 on 20A (at 100W each)', colors),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.leaf, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('With LEDs: many more lights possible (check total wattage)', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildICRatings(ZaftoColors colors) {
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
            Icon(LucideIcons.flame, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('IC RATING - CRITICAL', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _ratingRow('IC', 'Insulation Contact', 'CAN touch insulation', colors),
          _ratingRow('Non-IC', 'No Insulation Contact', 'Keep 3" clearance from insulation', colors),
          _ratingRow('AT', 'Airtight', 'Sealed housing, energy code', colors),
          _ratingRow('IC-AT', 'Both ratings', 'Best choice for insulated ceilings', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Non-IC can in insulation = FIRE HAZARD\nAlways verify rating before covering with insulation', style: TextStyle(color: colors.accentError, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _ratingRow(String code, String name, String meaning, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 55, child: Text(code, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(child: Text('$name - $meaning', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSpacing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('SPACING GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('General rule: Ceiling height / 2 = spacing between lights', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          _spaceRow('8 ft ceiling', '4 ft between lights', colors),
          _spaceRow('9 ft ceiling', '4.5 ft between lights', colors),
          _spaceRow('10 ft ceiling', '5 ft between lights', colors),
          _spaceRow('From wall', 'Half the spacing (2-2.5 ft)', colors),
          const SizedBox(height: 12),
          _infoItem('Task lighting (kitchen): tighter spacing', colors),
          _infoItem('Ambient lighting: wider spacing OK', colors),
          _infoItem('4" cans: smaller rooms, 6" cans: larger rooms', colors),
        ],
      ),
    );
  }

  Widget _spaceRow(String height, String spacing, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 100, child: Text(height, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        Text(spacing, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
      ]),
    );
  }

  Widget _buildDimmerCompatibility(ZaftoColors colors) {
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
            Icon(LucideIcons.sunDim, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('LED DIMMER COMPATIBILITY', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Use LED/CFL rated dimmers ONLY\n'
            '• Check dimmer min/max wattage rating\n'
            '• Some LEDs not dimmable - verify before buying\n'
            '• Flickering = incompatible dimmer or too few LEDs\n'
            '• Lutron, Leviton make quality LED dimmers\n'
            '• ELV dimmers for some LED drivers',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
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
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC 410.116 - Clearance and Installation\n'
            '• NEC 410.115 - Temperature Requirements\n'
            '• NEC 410.8 - Clothes Closets\n'
            '• NEC 314.29 - Accessible Junction Boxes\n'
            '• UL 1598 - Luminaires Standard',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
