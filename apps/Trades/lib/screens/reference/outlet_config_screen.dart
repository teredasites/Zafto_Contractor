/// Outlet Configurations Reference - Design System v2.6
/// NEMA receptacle configurations and identification
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class OutletConfigScreen extends ConsumerWidget {
  const OutletConfigScreen({super.key});

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
        title: Text(
          'Outlet Configurations',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NecEditionBadge(edition: necBadge, colors: colors),
          const SizedBox(height: 16),
          _ResidentialSection(colors: colors),
          const SizedBox(height: 16),
          _240VSection(colors: colors),
          const SizedBox(height: 16),
          _LockingSection(colors: colors),
          const SizedBox(height: 16),
          _NEMAChartSection(colors: colors),
          const SizedBox(height: 16),
          _IdentificationSection(colors: colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ResidentialSection extends StatelessWidget {
  final ZaftoColors colors;
  const _ResidentialSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Common Residential Outlets', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('120V Standard & 20A', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _OutletRow(colors: colors, nema: 'NEMA 5-15R', rating: '15A 125V', use: 'Standard household outlet'),
                _OutletRow(colors: colors, nema: 'NEMA 5-20R', rating: '20A 125V', use: 'Kitchen, bath, garage (T-slot)'),
                _OutletRow(colors: colors, nema: 'NEMA 1-15R', rating: '15A 125V', use: 'Older 2-prong (no ground)'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.info, size: 14, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The "R" means Receptacle (outlet). The "P" would be Plug.\nNEMA 5-20R has T-shaped neutral slot to accept both 15A and 20A plugs.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _240VSection extends StatelessWidget {
  final ZaftoColors colors;
  const _240VSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.zap, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('240V Outlets', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('Heavy appliances & equipment', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Without Neutral (2-pole):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                _OutletRow(colors: colors, nema: 'NEMA 6-15R', rating: '15A 250V', use: '240V small equipment'),
                _OutletRow(colors: colors, nema: 'NEMA 6-20R', rating: '20A 250V', use: '240V window A/C, tools'),
                _OutletRow(colors: colors, nema: 'NEMA 6-30R', rating: '30A 250V', use: '240V water heater, compressor'),
                _OutletRow(colors: colors, nema: 'NEMA 6-50R', rating: '50A 250V', use: '240V welder'),
                const SizedBox(height: 16),
                Text('With Neutral (4-wire Modern):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                _OutletRow(colors: colors, nema: 'NEMA 14-30R', rating: '30A 125/250V', use: 'Dryer (modern 4-prong)'),
                _OutletRow(colors: colors, nema: 'NEMA 14-50R', rating: '50A 125/250V', use: 'Range, EV charger'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                          const SizedBox(width: 6),
                          Text('Old 3-prong (obsolete for new install):', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _OutletRow(colors: colors, nema: 'NEMA 10-30R', rating: '30A 125/250V', use: 'Old dryer (no ground)'),
                      _OutletRow(colors: colors, nema: 'NEMA 10-50R', rating: '50A 125/250V', use: 'Old range (no ground)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockingSection extends StatelessWidget {
  final ZaftoColors colors;
  const _LockingSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lock, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Locking Outlets (Twist-Lock)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('Designated with "L" prefix', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Text('Plug twists to lock in place - curved slots', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                _OutletRow(colors: colors, nema: 'L5-20R', rating: '20A 125V', use: 'Locking 120V'),
                _OutletRow(colors: colors, nema: 'L5-30R', rating: '30A 125V', use: 'Generator 120V'),
                _OutletRow(colors: colors, nema: 'L6-20R', rating: '20A 250V', use: 'Locking 240V'),
                _OutletRow(colors: colors, nema: 'L6-30R', rating: '30A 250V', use: 'Industrial 240V'),
                _OutletRow(colors: colors, nema: 'L14-20R', rating: '20A 125/250V', use: '4-wire locking'),
                _OutletRow(colors: colors, nema: 'L14-30R', rating: '30A 125/250V', use: 'Generator 4-wire'),
                _OutletRow(colors: colors, nema: 'L21-30R', rating: '30A 3Φ 120/208V', use: 'Industrial 3-phase'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Common generator outlet: L14-30R\n(30A, 120/240V, 4-wire twist-lock)',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NEMAChartSection extends StatelessWidget {
  final ZaftoColors colors;
  const _NEMAChartSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.hash, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Text('NEMA Configuration Numbers', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('First number = Configuration type', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 10),
                _ConfigRow(colors: colors, num: '1', config: '2-pole, 2-wire', voltage: '125V, no ground'),
                _ConfigRow(colors: colors, num: '5', config: '2-pole, 3-wire', voltage: '125V, with ground'),
                _ConfigRow(colors: colors, num: '6', config: '2-pole, 3-wire', voltage: '250V, with ground'),
                _ConfigRow(colors: colors, num: '10', config: '3-pole, 3-wire', voltage: '125/250V, no ground'),
                _ConfigRow(colors: colors, num: '14', config: '3-pole, 4-wire', voltage: '125/250V, with ground'),
                _ConfigRow(colors: colors, num: '15', config: '3-pole, 4-wire', voltage: '3Φ 250V, with ground'),
                _ConfigRow(colors: colors, num: 'L', config: 'Prefix', voltage: 'Locking type'),
                const SizedBox(height: 16),
                Text('Second number = Amperage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                Text('15, 20, 30, 50, 60 are common ratings', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentificationSection extends StatelessWidget {
  final ZaftoColors colors;
  const _IdentificationSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 18),
                const SizedBox(width: 10),
                Text('Quick Identification Tips', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                _TipRow(colors: colors, tip: 'Count the slots', detail: '2 = 2-wire, 3 = grounded or 240V, 4 = 240V w/neutral'),
                _TipRow(colors: colors, tip: 'T-shaped slot', detail: '20A receptacle (accepts 15A & 20A plugs)'),
                _TipRow(colors: colors, tip: 'Horizontal slots', detail: '240V (no neutral needed)'),
                _TipRow(colors: colors, tip: 'L-shaped slot', detail: '240V with neutral (modern dryer/range)'),
                _TipRow(colors: colors, tip: 'Round ground hole', detail: 'vs. U-shaped = check NEMA chart'),
                _TipRow(colors: colors, tip: 'Curved slots', detail: 'Locking (twist-lock) configuration'),
                const SizedBox(height: 10),
                Text(
                  'When replacing: match EXACT NEMA type. Voltage and amperage must match circuit.',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutletRow extends StatelessWidget {
  final ZaftoColors colors;
  final String nema;
  final String rating;
  final String use;

  const _OutletRow({required this.colors, required this.nema, required this.rating, required this.use});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nema, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(rating, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final ZaftoColors colors;
  final String num;
  final String config;
  final String voltage;

  const _ConfigRow({required this.colors, required this.num, required this.config, required this.voltage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(num, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(config, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Expanded(child: Text(voltage, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final ZaftoColors colors;
  final String tip;
  final String detail;

  const _TipRow({required this.colors, required this.tip, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '$tip: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                TextSpan(text: detail, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
