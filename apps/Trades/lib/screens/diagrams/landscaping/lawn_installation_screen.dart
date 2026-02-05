import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class LawnInstallationScreen extends ConsumerWidget {
  const LawnInstallationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Lawn Installation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSodVsSeed(colors),
            const SizedBox(height: 24),
            _buildSoilPreparation(colors),
            const SizedBox(height: 24),
            _buildSodInstallation(colors),
            const SizedBox(height: 24),
            _buildSeedInstallation(colors),
            const SizedBox(height: 24),
            _buildMaintenanceSchedule(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSodVsSeed(ZaftoColors colors) {
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
              Icon(LucideIcons.sprout, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Sod vs Seed',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SOD', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildCompareItem(colors, 'Cost', '\$0.30-0.80/sf', colors.accentWarning),
                      _buildCompareItem(colors, 'Time', 'Instant lawn', colors.accentSuccess),
                      _buildCompareItem(colors, 'Season', 'Most of year', colors.accentSuccess),
                      _buildCompareItem(colors, 'Erosion', 'Immediate control', colors.accentSuccess),
                      _buildCompareItem(colors, 'Variety', 'Limited choices', colors.accentWarning),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SEED', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildCompareItem(colors, 'Cost', '\$0.05-0.15/sf', colors.accentSuccess),
                      _buildCompareItem(colors, 'Time', '4-8 weeks', colors.accentWarning),
                      _buildCompareItem(colors, 'Season', 'Spring/Fall best', colors.accentWarning),
                      _buildCompareItem(colors, 'Erosion', 'Risk until established', colors.accentError),
                      _buildCompareItem(colors, 'Variety', 'Many options', colors.accentSuccess),
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

  Widget _buildCompareItem(ZaftoColors colors, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSoilPreparation(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Remove debris and old turf', 'tool': 'Sod cutter, rake'},
      {'step': '2', 'task': 'Soil test', 'tool': 'Test kit, lab'},
      {'step': '3', 'task': 'Rough grade to slope', 'tool': 'Skid steer, rake'},
      {'step': '4', 'task': 'Add amendments', 'tool': 'Spreader, tiller'},
      {'step': '5', 'task': 'Till to 4-6" depth', 'tool': 'Rototiller'},
      {'step': '6', 'task': 'Fine grade and rake', 'tool': 'Landscape rake'},
      {'step': '7', 'task': 'Roll lightly', 'tool': 'Lawn roller (1/3 full)'},
      {'step': '8', 'task': 'Final grade check', 'tool': 'String line, level'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shovel, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Soil Preparation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.accentWarning,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(s['step']!, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s['task']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                Text(s['tool']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.beaker, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target soil pH: 6.0-7.0. Add lime to raise pH, sulfur to lower pH.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSodInstallation(ZaftoColors colors) {
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
              Icon(LucideIcons.layers, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sod Installation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''SOD LAYING PATTERN

Start at straight edge (driveway, sidewalk)

    ════════════════════════════
    │ SOD ROLL 1 │ SOD ROLL 2 │
    ════════════════════════════
       │ ROLL 3 │ ROLL 4 │
    ════════════════════════════
    │ ROLL 5 │ ROLL 6 │
    ════════════════════════════

STAGGER JOINTS like brickwork
Push edges tight - no gaps, no overlap

SLOPES: Lay perpendicular to slope
        Stake if >15% grade

CURVES: Roll out straight, then cut
        with sharp knife''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSodTip(colors, 'Install same day', 'Sod dies quickly, especially in heat'),
          _buildSodTip(colors, 'Moisten soil first', 'Not soggy, just damp'),
          _buildSodTip(colors, 'Roll after laying', 'Ensures root-to-soil contact'),
          _buildSodTip(colors, 'Water immediately', '1" within 30 minutes of install'),
          _buildSodTip(colors, 'No traffic', '2 weeks minimum'),
        ],
      ),
    );
  }

  Widget _buildSodTip(ZaftoColors colors, String tip, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$tip: ',
                    style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: detail,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedInstallation(ZaftoColors colors) {
    final rates = [
      {'type': 'Kentucky Bluegrass', 'rate': '2-3 lbs', 'germ': '14-21 days'},
      {'type': 'Perennial Ryegrass', 'rate': '8-10 lbs', 'germ': '5-10 days'},
      {'type': 'Tall Fescue', 'rate': '8-10 lbs', 'germ': '7-14 days'},
      {'type': 'Fine Fescue', 'rate': '4-5 lbs', 'germ': '10-14 days'},
      {'type': 'Bermuda', 'rate': '1-2 lbs', 'germ': '10-30 days'},
      {'type': 'Zoysia', 'rate': '1-2 lbs', 'germ': '14-21 days'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.leaf, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seed Installation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Seeding Rates (per 1,000 sq ft)',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...rates.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(r['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                SizedBox(
                  width: 60,
                  child: Text(r['rate']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                Text(r['germ']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seeding Steps:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '1. Apply starter fertilizer\n2. Spread seed with broadcast spreader (2 passes, perpendicular)\n3. Rake lightly to cover seed 1/8-1/4"\n4. Roll lightly\n5. Apply straw mulch (1 bale per 1,000 sf)\n6. Water lightly 2-3x daily until germination',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSchedule(ZaftoColors colors) {
    final schedule = [
      {'timing': 'Week 1-2', 'water': '2-3x daily, light', 'mow': 'None', 'note': 'Keep moist'},
      {'timing': 'Week 3-4', 'water': '1x daily', 'mow': 'None', 'note': 'Roots establishing'},
      {'timing': 'Week 5-6', 'water': 'Every other day', 'mow': 'First mow at 3"', 'note': '1/3 rule'},
      {'timing': 'Ongoing', 'water': '1" per week', 'mow': '3-4" height', 'note': 'Deep, infrequent'},
    ];

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
              Icon(LucideIcons.calendar, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'New Lawn Care Schedule',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...schedule.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s['timing']!, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Text(s['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.droplets, color: colors.accentInfo, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['water']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                    Icon(LucideIcons.scissors, color: colors.accentSuccess, size: 12),
                    const SizedBox(width: 4),
                    Text(s['mow']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
