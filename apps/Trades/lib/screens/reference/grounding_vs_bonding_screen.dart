/// Grounding vs Bonding Reference - Design System v2.6
/// NEC Article 100/250 grounding and bonding concepts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class GroundingVsBondingScreen extends ConsumerWidget {
  const GroundingVsBondingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Grounding vs Bonding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NecEditionBadge(edition: necBadge, colors: colors),
            const SizedBox(height: 16),
            _buildKeyDifference(colors),
            const SizedBox(height: 16),
            _buildGroundingExplained(colors),
            const SizedBox(height: 16),
            _buildBondingExplained(colors),
            const SizedBox(height: 16),
            _buildDiagram(colors),
            const SizedBox(height: 16),
            _buildCommonConfusions(colors),
            const SizedBox(height: 16),
            _buildNECTerms(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyDifference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Key Difference', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.mountain, color: colors.accentSuccess, size: 28),
                      const SizedBox(height: 6),
                      Text('GROUNDING', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Connection to EARTH', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.link, color: colors.accentPrimary, size: 28),
                      const SizedBox(height: 6),
                      Text('BONDING', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Connection of METAL parts together', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingExplained(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mountain, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text('Grounding (Earthing)', style: TextStyle(color: colors.accentSuccess, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('PURPOSE:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Stabilize voltage to earth during normal operation', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Provide path for lightning/surge energy to earth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Limit voltage from line surges', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text('COMPONENTS:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _compRow('Grounding Electrode', 'Rod, Ufer, water pipe, building steel', colors),
          _compRow('GEC', 'Grounding Electrode Conductor', colors),
          _compRow('Grounded Conductor', 'Neutral (intentionally grounded)', colors),
        ],
      ),
    );
  }

  Widget _buildBondingExplained(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.link, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text('Bonding', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('PURPOSE:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Connect metal parts to ensure same potential', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Prevent shock from voltage differences', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Provide fault current path to trip breakers', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text('COMPONENTS:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _compRow('EGC', 'Equipment Grounding Conductor (green/bare)', colors),
          _compRow('MBJ', 'Main Bonding Jumper (N to G at service)', colors),
          _compRow('Bonding Jumper', 'Connects enclosures, raceways', colors),
          _compRow('Equipotential Bond', 'Pool/spa bonding grid', colors),
        ],
      ),
    );
  }

  Widget _compRow(String term, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How They Work Together', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('         MAIN PANEL', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        ┌─────────┐', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │  N BAR  │◄── Neutral from utility', style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │    │    │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │   MBJ   │◄── Main Bonding Jumper', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │    │    │    (ONLY connection N↔G)', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │    ▼    │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        │  G BAR  │◄── Equipment grounds', style: TextStyle(color: colors.accentSuccess, fontFamily: 'monospace', fontSize: 10)),
                Text('        │    │    │    (bonding)', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        └────┼────┘', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('             │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('            GEC ◄── Grounding Electrode', style: TextStyle(color: colors.accentSuccess, fontFamily: 'monospace', fontSize: 10)),
                Text('             │      Conductor', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('             ▼', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('        ═════════ ◄── Earth (grounding)', style: TextStyle(color: colors.accentSuccess, fontFamily: 'monospace', fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonConfusions(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('Common Misconceptions', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _mythRow('MYTH', 'Ground wire carries fault current to earth', colors),
          _mythRow('FACT', 'Fault current returns via bonding path to source (transformer), NOT through earth', colors),
          const SizedBox(height: 10),
          _mythRow('MYTH', 'Grounding makes system safe', colors),
          _mythRow('FACT', 'BONDING makes system safe by providing low-impedance fault path', colors),
          const SizedBox(height: 10),
          _mythRow('MYTH', 'More ground rods = more safety', colors),
          _mythRow('FACT', 'Ground rods are for surge/lightning, not fault clearing', colors),
        ],
      ),
    );
  }

  Widget _mythRow(String type, String text, ZaftoColors colors) {
    final isMyth = type == 'MYTH';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isMyth ? colors.accentError.withValues(alpha: 0.2) : colors.accentSuccess.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(type, style: TextStyle(color: isMyth ? colors.accentError : colors.accentSuccess, fontWeight: FontWeight.w700, fontSize: 9)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildNECTerms(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('NEC Article 100 Definitions', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _necRow('Grounded', 'Connected to earth', colors),
          _necRow('Grounding', 'Connecting to earth', colors),
          _necRow('Grounded Conductor', 'Neutral (white) - intentionally grounded', colors),
          _necRow('Grounding Conductor', 'NOT a term! Common error', colors, isError: true),
          _necRow('EGC', 'Equipment Grounding Conductor - Green/bare for bonding', colors),
          _necRow('GEC', 'Grounding Electrode Conductor - Wire to earth electrode', colors),
          _necRow('Bonded', 'Connected to establish electrical continuity', colors),
          _necRow('Bonding Jumper', 'Conductor ensuring bonding', colors),
          _necRow('Main Bonding Jumper', 'Link between neutral and equipment ground at service', colors),
        ],
      ),
    );
  }

  Widget _necRow(String term, String def, ZaftoColors colors, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(term, style: TextStyle(color: isError ? colors.accentError : colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(def, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
