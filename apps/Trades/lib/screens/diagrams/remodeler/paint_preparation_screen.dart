import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PaintPreparationScreen extends ConsumerWidget {
  const PaintPreparationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Paint Preparation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaintTypes(colors),
            const SizedBox(height: 24),
            _buildSurfacePrep(colors),
            const SizedBox(height: 24),
            _buildPrimerGuide(colors),
            const SizedBox(height: 24),
            _buildCoverageEstimates(colors),
            const SizedBox(height: 24),
            _buildApplicationTips(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPaintTypes(ZaftoColors colors) {
    final types = [
      {'type': 'Flat/Matte', 'sheen': '0-10%', 'use': 'Ceilings, low-traffic walls', 'hide': 'Best'},
      {'type': 'Eggshell', 'sheen': '10-25%', 'use': 'Living rooms, bedrooms', 'hide': 'Good'},
      {'type': 'Satin', 'sheen': '25-35%', 'use': 'Kitchens, bathrooms, hallways', 'hide': 'Fair'},
      {'type': 'Semi-Gloss', 'sheen': '35-70%', 'use': 'Trim, doors, cabinets', 'hide': 'Low'},
      {'type': 'Gloss', 'sheen': '70-90%', 'use': 'High-traffic trim, cabinets', 'hide': 'Lowest'},
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
              Icon(LucideIcons.paintbrush, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Paint Sheens',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 75,
                  child: Text(
                    t['type']!,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['sheen']!, style: TextStyle(color: colors.accentInfo, fontSize: 9), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['hide']!, style: TextStyle(color: colors.accentWarning, fontSize: 9)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Text(
            'Higher sheen = more durable, easier to clean, but shows imperfections',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfacePrep(ZaftoColors colors) {
    final steps = [
      {'task': 'Clean surface', 'detail': 'TSP or degreaser, rinse, dry', 'icon': LucideIcons.droplets},
      {'task': 'Remove loose paint', 'detail': 'Scrape, sand to feather edges', 'icon': LucideIcons.eraser},
      {'task': 'Fill holes/cracks', 'detail': 'Spackle small, joint compound large', 'icon': LucideIcons.pipette},
      {'task': 'Sand filled areas', 'detail': '120-150 grit, feather smooth', 'icon': LucideIcons.square},
      {'task': 'Sand glossy surfaces', 'detail': '150-180 grit for adhesion', 'icon': LucideIcons.alignVerticalJustifyCenter},
      {'task': 'Dust/tack', 'detail': 'Vacuum then tack cloth', 'icon': LucideIcons.wind},
      {'task': 'Mask/protect', 'detail': 'Tape edges, cover floors', 'icon': LucideIcons.shield},
      {'task': 'Prime as needed', 'detail': 'See primer guide below', 'icon': LucideIcons.layers},
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
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Surface Preparation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${entry.key + 1}', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(entry.value['icon'] as IconData, color: colors.textTertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.value['task'] as String, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(entry.value['detail'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPrimerGuide(ZaftoColors colors) {
    final primers = [
      {'situation': 'New drywall', 'primer': 'PVA drywall primer', 'coats': '1'},
      {'situation': 'Stains (water, smoke)', 'primer': 'Shellac-based', 'coats': '1-2'},
      {'situation': 'Bare wood', 'primer': 'Oil or shellac', 'coats': '1'},
      {'situation': 'Glossy surface', 'primer': 'Bonding primer', 'coats': '1'},
      {'situation': 'Dark to light color', 'primer': 'Tinted primer', 'coats': '1-2'},
      {'situation': 'Exterior wood', 'primer': 'Exterior oil primer', 'coats': '1'},
      {'situation': 'Metal', 'primer': 'Rust-inhibiting', 'coats': '1'},
      {'situation': 'Previously painted', 'primer': 'Usually not needed', 'coats': '0'},
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
              Icon(LucideIcons.layers, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Primer Selection Guide',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...primers.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(p['situation']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(p['primer']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    p['coats'] == '0' ? 'N/A' : '${p['coats']} coat',
                    style: TextStyle(color: colors.textTertiary, fontSize: 9),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCoverageEstimates(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coverage Estimates',
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
              '''PAINT COVERAGE CALCULATOR

1 Gallon covers approximately:
┌─────────────────────────────────┐
│ Surface Type     │   Coverage   │
├─────────────────────────────────┤
│ Smooth drywall   │  350-400 sf  │
│ Textured wall    │  250-300 sf  │
│ Rough/porous     │  200-250 sf  │
│ Trim (per coat)  │  150-200 lf  │
└─────────────────────────────────┘

WALL CALCULATION:
┌──────────────────┐
│   (L×H) + (W×H)  │
│      × 2         │ = Total wall sf
│   - doors/windows│
└──────────────────┘

Room: 12' × 14' × 8' ceiling
Walls: (12+14) × 2 × 8 = 416 sf
Less: 2 doors (40sf) + 2 windows (30sf)
Net: 416 - 70 = 346 sf
Paint: ~1 gallon per coat''',
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
                    'Always buy 10-15% extra. Same batch ensures consistent color.',
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

  Widget _buildApplicationTips(ZaftoColors colors) {
    final tips = [
      {'category': 'Cutting in', 'tip': 'Paint edges and corners first with brush'},
      {'category': 'Rolling', 'tip': 'W pattern, then fill in without lifting roller'},
      {'category': 'Wet edge', 'tip': 'Work quickly, overlap wet edges to avoid lap marks'},
      {'category': 'Load roller', 'tip': 'Full but not dripping, roll off excess on tray'},
      {'category': 'Pressure', 'tip': 'Light to medium, let paint do the work'},
      {'category': 'Coats', 'tip': '2 coats minimum, 4 hours between latex coats'},
      {'category': 'Temperature', 'tip': '50-85°F, avoid direct sunlight on surface'},
      {'category': 'Humidity', 'tip': 'Below 85% RH for proper drying'},
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
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Application Tips',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.chevronRight, color: colors.accentSuccess, size: 14),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    t['category']!,
                    style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(t['tip']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Roller Nap Guide:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '• 3/16"-1/4": Smooth surfaces, cabinets\n• 3/8"-1/2": Drywall, plaster (most common)\n• 3/4"-1": Textured surfaces, stucco',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
