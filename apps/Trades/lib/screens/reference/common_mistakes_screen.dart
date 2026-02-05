/// Common Electrical Mistakes - Design System v2.6
/// Code violations and inspection failures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class CommonMistakesScreen extends ConsumerWidget {
  const CommonMistakesScreen({super.key});

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
        title: Text('Common Electrical Mistakes', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NecEditionBadge(edition: necBadge, colors: colors),
          const SizedBox(height: 16),
          _MistakeCard(colors: colors, title: 'Overcrowded Box', problem: 'Too many wires in box, exceeds fill capacity', fix: 'Calculate box fill per NEC 314.16. Use larger box or split circuits.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Backstabbed Receptacles', problem: 'Using push-in connections instead of screw terminals', fix: 'Always use screw terminals or screw-to-clamp. Backstabs fail.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'No Box Support', problem: 'Box not secured, relies on device to hold it', fix: 'All boxes must be independently supported. Use proper brackets.', severity: 'warning'),
          _MistakeCard(colors: colors, title: 'Wrong Wire Gauge', problem: 'Using 14 AWG on 20A circuit or undersized wire', fix: '14 AWG = 15A max, 12 AWG = 20A max. Never undersize.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Missing Clamps', problem: 'NM cable enters box without cable clamp', fix: 'All cables entering metal boxes need clamps. Plastic boxes have built-in.', severity: 'warning'),
          _MistakeCard(colors: colors, title: 'Unprotected NM Cable', problem: 'Romex exposed in garage, basement, or outdoors', fix: 'Protect with conduit or use appropriate cable type for location.', severity: 'warning'),
          _MistakeCard(colors: colors, title: 'Reversed Polarity', problem: 'Hot and neutral swapped at receptacle', fix: 'Hot (black) to brass, neutral (white) to silver. Use tester.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Bootleg Ground', problem: 'Jumping ground to neutral at receptacle', fix: 'DANGEROUS. Install proper ground or use GFCI. Never fake ground.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'No GFCI Protection', problem: 'Missing GFCI in wet locations (bath, kitchen, outdoor)', fix: 'GFCI required per NEC 210.8. Protects against electrocution.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Overfused Circuit', problem: '20A breaker on 14 AWG wire', fix: 'Breaker protects wire. Match breaker to smallest wire in circuit.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Unmarked White as Hot', problem: 'Using white wire as hot without re-identifying', fix: 'Mark with black tape or marker when white is used as hot.', severity: 'warning'),
          _MistakeCard(colors: colors, title: 'No Connector on Flex', problem: 'Flexible conduit enters box without proper fitting', fix: 'Use appropriate connector for MC, AC, or flex conduit.', severity: 'warning'),
          _MistakeCard(colors: colors, title: 'Daisy-Chained GFCIs', problem: 'GFCI protecting another GFCI downstream', fix: 'Only first GFCI needed. Downstream outlets on LOAD terminals.', severity: 'info'),
          _MistakeCard(colors: colors, title: 'Sub-Panel N-G Bond', problem: 'Neutral and ground bonded at sub-panel', fix: 'Remove bonding screw. N and G bond at MAIN panel only.', severity: 'critical'),
          _MistakeCard(colors: colors, title: 'Exposed Splices', problem: 'Wire splices outside of junction box', fix: 'ALL splices must be in accessible box with cover.', severity: 'critical'),
          const SizedBox(height: 16),
          _InspectionTip(colors: colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final String problem;
  final String fix;
  final String severity;

  const _MistakeCard({
    required this.colors,
    required this.title,
    required this.problem,
    required this.fix,
    required this.severity,
  });

  Color get _severityColor {
    switch (severity) {
      case 'critical':
        return colors.accentError;
      case 'warning':
        return colors.accentWarning;
      default:
        return colors.accentInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _severityColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: _severityColor, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 10),
          Text('Problem: $problem', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text('Fix: $fix', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectionTip extends StatelessWidget {
  final ZaftoColors colors;
  const _InspectionTip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: colors.accentInfo, size: 18),
              const SizedBox(width: 10),
              Text('Before Inspection', style: TextStyle(color: colors.accentInfo, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _CheckItem(colors: colors, text: 'All boxes have covers'),
          _CheckItem(colors: colors, text: 'All conductors properly terminated'),
          _CheckItem(colors: colors, text: 'No exposed copper at splices'),
          _CheckItem(colors: colors, text: 'Cables secured within 12" of box'),
          _CheckItem(colors: colors, text: 'Panel directory complete'),
          _CheckItem(colors: colors, text: 'Working clearances maintained'),
          _CheckItem(colors: colors, text: 'AFCI/GFCI installed where required'),
          _CheckItem(colors: colors, text: 'Smoke detectors wired and working'),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final ZaftoColors colors;
  final String text;
  const _CheckItem({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(LucideIcons.checkSquare, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
