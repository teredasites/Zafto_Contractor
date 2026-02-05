import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class FoundationTypesScreen extends ConsumerWidget {
  const FoundationTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Foundation Types',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(colors),
            const SizedBox(height: 24),
            _buildSlabOnGrade(colors),
            const SizedBox(height: 24),
            _buildCrawlSpace(colors),
            const SizedBox(height: 24),
            _buildBasement(colors),
            const SizedBox(height: 24),
            _buildPierAndBeam(colors),
            const SizedBox(height: 24),
            _buildFootingRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ZaftoColors colors) {
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Foundation Types Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'The foundation transfers building loads to the soil and must be designed for soil conditions, climate, and building type. Frost depth and soil bearing capacity are critical factors.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFactorCard(colors, 'Frost Depth', 'Below frost line', LucideIcons.snowflake)),
              const SizedBox(width: 8),
              Expanded(child: _buildFactorCard(colors, 'Soil Bearing', '1500-4000 PSF', LucideIcons.mountain)),
              const SizedBox(width: 8),
              Expanded(child: _buildFactorCard(colors, 'Water Table', 'Above or below', LucideIcons.droplet)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(ZaftoColors colors, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          Text(value, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSlabOnGrade(ZaftoColors colors) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentSuccess,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Slab-on-Grade', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
MONOLITHIC SLAB (Thickened Edge)
═══════════════════════════════════════════════════════

              GRADE LEVEL
═════════════════════════════════════════════════════════
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░ 4" CONCRETE SLAB ░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
├──────────────────────────────────────────────────────┤
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 6 MIL VAPOR BARRIER ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
├──────────────────────────────────────────────────────┤
│░ ░ ░ ░ ░ ░ ░  4" GRAVEL BASE  ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░│
│                                                      │
│    ┌─────────────────────────────────────────┐      │
│    │                                         │      │
│    │        THICKENED EDGE                   │      │
│    │        (Footing integrated)             │      │
│    │        12" wide × 12" deep min          │      │
│    │                                         │      │
│    └─────────────────────────────────────────┘      │
│                                                      │
════════════════ UNDISTURBED SOIL ════════════════════


STEM WALL + SLAB
═══════════════════════════════════════════════════════

                    SILL PLATE
                        │
══════════════════════════════════════════════════════
│░░░░░░░░░░░░░ 4" SLAB ░░░░░░░░░░░░│    ║    │
│▓▓▓▓▓▓▓▓▓▓▓▓ VAPOR BARRIER ▓▓▓▓▓▓▓│    ║    │
│░ ░ ░ ░ ░  GRAVEL  ░ ░ ░ ░ ░ ░ ░ │    ║    │ STEM
│                                   │    ║    │ WALL
│                                   │════╩════│
│                                   │         │
│                                   │ FOOTING │
                                    └─────────┘''',
              style: TextStyle(
                color: colors.accentSuccess,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFoundationSpecs(colors, [
            'Best for: Warm climates, low water table',
            'Slab: 4" min thickness, 3000 PSI concrete',
            'Reinforcement: #4 rebar or 6×6 WWM',
            'Thickened edge: 12"×12" min for 1-story',
          ]),
        ],
      ),
    );
  }

  Widget _buildCrawlSpace(ZaftoColors colors) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentInfo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Crawl Space', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
CRAWL SPACE FOUNDATION
═══════════════════════════════════════════════════════

        FLOOR JOISTS         SUBFLOOR
            │                    │
    ════════╪════════════════════╪════════════════════
    ║       │                    │                   ║
    ║   ────┴────────────────────┴────               ║
    ║                                                ║
    ║          CRAWL SPACE                           ║
    ║          (18" min clearance)                   ║
    ║                                                ║
    ║   ▓▓▓▓▓▓▓▓ VAPOR BARRIER ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ║
    ║   (6 mil poly, lapped 12", up walls 6")       ║
════╩════════════════════════════════════════════════╩════
    │                                                │
    │  STEM WALL                          STEM WALL │
    │  8" min thick                                 │
    │                                                │
════╪════════════════════════════════════════════════╪════
    │         │                          │          │
    │ FOOTING │                          │ FOOTING  │
    └─────────┘                          └──────────┘
         12" × 6" min (verify local code)''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFoundationSpecs(colors, [
            'Best for: Sloped sites, access to MEP',
            'Clearance: 18" min (24" recommended)',
            'Ventilation: 1 sq ft per 150 sq ft (or sealed)',
            'Access: 18"×24" min opening',
          ]),
        ],
      ),
    );
  }

  Widget _buildBasement(ZaftoColors colors) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentWarning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Full Basement', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
FULL BASEMENT FOUNDATION
═══════════════════════════════════════════════════════

                     GRADE
    ════════════════════════════════════════════════
    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ BACKFILL
    ║                                              ║
    ║  WATERPROOFING                               ║
    ║  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                          ║
    ║  ▓                                          ▓║
    ║  ▓        BASEMENT                          ▓║
    ║  ▓        (8' ceiling typical)              ▓║
    ║  ▓                                          ▓║
    ║  ▓                                          ▓║
    ╠══╬══════════════════════════════════════════╬═╣
    ║  ▓░░░░░░░░ 4" SLAB ░░░░░░░░░░░░░░░░░░░░░░░░▓║
    ║  ▓▓▓▓▓▓ VAPOR BARRIER ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓║
    ║  ▓░ ░ ░  GRAVEL ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ▓║
════╬══╩══════════════════════════════════════════╩══╬════
    │              DRAIN TILE                        │
    │   FOOTING    ○○○○○○○○○○○○○○○○○      FOOTING   │
    └────────────────────────────────────────────────┘
         16-20" wide × 8-10" deep (2-story)''',
              style: TextStyle(
                color: colors.accentWarning,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFoundationSpecs(colors, [
            'Best for: Cold climates, extra living space',
            'Walls: 8-10" poured or 8" block',
            'Waterproofing: Required on exterior',
            'Drain tile: 4" perforated at footing level',
          ]),
        ],
      ),
    );
  }

  Widget _buildPierAndBeam(ZaftoColors colors) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Pier & Beam', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFoundationSpecs(colors, [
            'Isolated concrete piers support beams',
            'Good for expansive soils, flood zones',
            'Easy access to MEP below floor',
            'Pier spacing: 6-8\' typical',
            'Beam size per engineering (4×6 to 6×12)',
          ]),
        ],
      ),
    );
  }

  Widget _buildFootingRequirements(ZaftoColors colors) {
    final requirements = [
      {'type': '1-Story', 'width': '12"', 'depth': '6"', 'rebar': '2-#4'},
      {'type': '2-Story', 'width': '15"', 'depth': '7"', 'rebar': '2-#4'},
      {'type': '3-Story', 'width': '18"', 'depth': '8"', 'rebar': '2-#5'},
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
              Icon(LucideIcons.ruler, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Typical Footing Sizes (IRC)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Based on 1500 PSF soil bearing capacity', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.accentError.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('Width', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('Depth', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('Rebar', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ...requirements.map((r) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(r['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
                      Expanded(child: Text(r['width']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text(r['depth']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text(r['rebar']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundationSpecs(ZaftoColors colors, List<String> specs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specs.map((spec) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          ],
        ),
      )).toList(),
    );
  }
}
