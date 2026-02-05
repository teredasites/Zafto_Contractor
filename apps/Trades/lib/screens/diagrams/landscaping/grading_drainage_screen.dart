import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class GradingDrainageScreen extends ConsumerWidget {
  const GradingDrainageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Grading & Drainage',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradingPrinciples(colors),
            const SizedBox(height: 24),
            _buildDrainageSolutions(colors),
            const SizedBox(height: 24),
            _buildFrenchDrain(colors),
            const SizedBox(height: 24),
            _buildSwaleDesign(colors),
            const SizedBox(height: 24),
            _buildSlopeCalculations(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingPrinciples(ZaftoColors colors) {
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
              Icon(LucideIcons.trendingDown, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Grading Principles',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''POSITIVE DRAINAGE FROM FOUNDATION

              HOUSE
         ╔════════════════╗
         ║                ║
    ─────╨────────────────╨─────
     ╲                         ╱
      ╲  6" drop in 10 feet   ╱
       ╲                     ╱
        ╲___________________╱
               ↓
         TO DRAINAGE

MINIMUM GRADES:
• Foundation: 6" drop in first 10'
  (or 5% slope minimum)
• Lawn: 2% slope (1/4" per foot)
• Swales: 1-2% slope

FINISH GRADE vs SUBGRADE:
Finish grade = Subgrade + (sod 2" / mulch 3")''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water toward foundation = wet basements, foundation damage, mold. Always grade away.',
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

  Widget _buildDrainageSolutions(ZaftoColors colors) {
    final solutions = [
      {'type': 'Surface grading', 'best': 'Simple drainage issues', 'cost': '\$'},
      {'type': 'Swale', 'best': 'Redirect large volumes', 'cost': '\$'},
      {'type': 'French drain', 'best': 'Subsurface water', 'cost': '\$\$'},
      {'type': 'Channel drain', 'best': 'Hardscape/driveway', 'cost': '\$\$'},
      {'type': 'Catch basin', 'best': 'Collect and redirect', 'cost': '\$\$'},
      {'type': 'Dry well', 'best': 'On-site infiltration', 'cost': '\$\$'},
      {'type': 'Sump pump', 'best': 'Below-grade water', 'cost': '\$\$\$'},
      {'type': 'Rain garden', 'best': 'Natural infiltration', 'cost': '\$\$'},
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
              Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Drainage Solutions',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...solutions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(s['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(s['best']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s['cost']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFrenchDrain(ZaftoColors colors) {
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
              Icon(LucideIcons.pipette, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'French Drain Installation',
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
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''FRENCH DRAIN CROSS-SECTION

     Water infiltration
          ↓  ↓  ↓
    ┌────────────────────┐
    │ GRASS/GROUND LEVEL │
    ├────────────────────┤
    │░░░░░░░░░░░░░░░░░░░░│ ← 2" topsoil/sod
    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Filter fabric
    │○○○○○○○○○○○○○○○○○○○○│   (wraps gravel)
    │○○○○○○○○○○○○○○○○○○○○│ ← 3/4" clean gravel
    │○○○○┌──────────┐○○○○│
    │○○○○│ PERF PIPE│○○○○│ ← 4" perforated pipe
    │○○○○│ holes ↓  │○○○○│   (holes DOWN)
    │○○○○└──────────┘○○○○│
    │○○○○○○○○○○○○○○○○○○○○│ ← 2" gravel below pipe
    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← Filter fabric bottom
    └────────────────────┘

DIMENSIONS:
• Trench: 12-18" wide × 18-24" deep
• Pipe: 4" perforated, Schedule 40
• Slope: 1% minimum (1" per 8 feet)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrainNote(colors, 'Pipe holes', 'Face DOWN to collect rising water'),
          _buildDrainNote(colors, 'Filter fabric', 'Prevents soil from clogging gravel'),
          _buildDrainNote(colors, 'Outlet', 'Daylight to lower grade or dry well'),
          _buildDrainNote(colors, 'Cleanout', 'Install at changes in direction'),
        ],
      ),
    );
  }

  Widget _buildDrainNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwaleDesign(ZaftoColors colors) {
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
              Icon(LucideIcons.waves, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Swale Design',
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
              '''GRASS SWALE PROFILE

    ←───── 4-8 feet wide ─────→

    ╲                           ╱
     ╲   3:1 or flatter slope  ╱
      ╲                       ╱
       ╲                     ╱
        ╲___________________╱
              ↓ 6-12" deep
         Water flow →→→

SWALE SLOPE (along length):
• Minimum: 1% (prevents standing water)
• Maximum: 5% (prevents erosion)
• Ideal: 1-2%

DRY CREEK BED (decorative swale):
    ╲  ○ ○ ○ ○ ○ ○ ○ ○ ○  ╱
     ╲○ ◎ ○ ◎ ○ ◎ ○ ◎ ○╱
      ╲ ○ ◎ ● ◎ ● ◎ ○ ╱
       ╲○ ● ○ ○ ○ ● ○╱

○ = River rock    ◎ = Cobble
● = Boulders (focal points)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swales can be mowed as part of lawn or planted with native grasses for natural look.',
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

  Widget _buildSlopeCalculations(ZaftoColors colors) {
    final slopes = [
      {'percent': '1%', 'ratio': '1:100', 'drop': '1" per 8\'', 'use': 'Swales, French drains'},
      {'percent': '2%', 'ratio': '1:50', 'drop': '1/4" per ft', 'use': 'Lawns, general grading'},
      {'percent': '5%', 'ratio': '1:20', 'drop': '5/8" per ft', 'use': 'Foundation, driveways'},
      {'percent': '10%', 'ratio': '1:10', 'drop': '1.25" per ft', 'use': 'Max for mowing'},
      {'percent': '33%', 'ratio': '3:1', 'drop': '4" per ft', 'use': 'Retaining wall trigger'},
      {'percent': '50%', 'ratio': '2:1', 'drop': '6" per ft', 'use': 'Requires stabilization'},
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
              Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Slope Reference',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...slopes.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s['percent']!, style: TextStyle(color: colors.accentPrimary, fontSize: 10), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(s['ratio']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
                SizedBox(
                  width: 70,
                  child: Text(s['drop']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                Expanded(
                  child: Text(s['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Formula:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  'Slope % = (Rise ÷ Run) × 100\nDrop = Distance × (Slope % ÷ 100)',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
