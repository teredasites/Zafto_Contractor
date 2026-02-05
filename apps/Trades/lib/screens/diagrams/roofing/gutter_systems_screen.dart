import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class GutterSystemsScreen extends ConsumerWidget {
  const GutterSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Gutter Systems',
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
            _buildGutterTypes(colors),
            const SizedBox(height: 24),
            _buildSizingGuide(colors),
            const SizedBox(height: 24),
            _buildInstallationDiagram(colors),
            const SizedBox(height: 24),
            _buildCommonIssues(colors),
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
              Icon(LucideIcons.alignLeft, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Gutter Systems Overview',
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
            'Gutters collect rainwater from the roof and direct it away from the foundation. Proper sizing, slope, and downspout placement are critical for effective drainage.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '1/4"', 'Slope per 10ft', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '5-6"', 'Standard Size', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '40ft', 'Max Run/DS', colors.accentWarning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildGutterTypes(ZaftoColors colors) {
    final types = [
      {
        'name': 'K-Style',
        'desc': 'Most common residential. Flat back, decorative front.',
        'sizes': '5" & 6"',
        'capacity': '5": 5,520 sq ft\n6": 7,960 sq ft',
        'color': colors.accentSuccess,
      },
      {
        'name': 'Half-Round',
        'desc': 'Traditional/historic look. Easier to clean.',
        'sizes': '5" & 6"',
        'capacity': 'Less than K-style\nat same size',
        'color': colors.accentInfo,
      },
      {
        'name': 'Box/Commercial',
        'desc': 'Large capacity for commercial buildings.',
        'sizes': '6" to 10"',
        'capacity': 'High volume\napplications',
        'color': colors.accentWarning,
      },
      {
        'name': 'Fascia Gutter',
        'desc': 'Replaces fascia board entirely.',
        'sizes': 'Custom',
        'capacity': 'Varies by\nprofile',
        'color': colors.accentPrimary,
      },
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
          Text(
            'Gutter Profiles',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildGutterTypeCard(colors, t)),
        ],
      ),
    );
  }

  Widget _buildGutterTypeCard(ZaftoColors colors, Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (type['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Column(
              children: [
                Text(type['name'] as String, style: TextStyle(color: type['color'] as Color, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(type['sizes'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type['desc'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(type['capacity'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizingGuide(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sizing & Calculations',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
ROOF DRAINAGE AREA CALCULATION
═══════════════════════════════════════════════════

Drainage Area = Footprint + (Wall Height × 0.5)

Example:
  Roof footprint: 30' × 20' = 600 sq ft
  Wall catching rain: 10' tall
  Add: 10' × 0.5 × roof length = 150 sq ft
  Total: 750 sq ft

DOWNSPOUT SPACING
═══════════════════════════════════════════════════

Rule: 1 downspout per 40 linear feet of gutter
      OR 1 per 600 sq ft of roof area

5" K-Style Gutter:
  • 2×3" downspout handles 600 sq ft
  • 3×4" downspout handles 1,200 sq ft

6" K-Style Gutter:
  • 3×4" downspout handles 1,500 sq ft

SLOPE REQUIREMENTS
═══════════════════════════════════════════════════

Minimum: 1/16" per foot (1/4" per 10')
Optimal: 1/8" per foot (1/2" per 10')

Max run to single downspout: 40 feet
Longer runs: Add mid-section downspout''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationDiagram(ZaftoColors colors) {
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
          Text(
            'Gutter Installation Details',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
GUTTER POSITIONING (Side View)
═══════════════════════════════════════════════════════

                    SHINGLES
                   ╱╱╱╱╱╱╱╱╱╱╱
                  ╱╱╱╱╱╱╱╱╱╱╱╱
                 ╱╱╱╱╱╱╱╱╱╱╱╱╱
                ╱           ╱
    ═══════════╱           ╱═════════════  DRIP EDGE
              ╱           ╱    │
              ▼           │    │
    ─────────────────────────┐ │ ← Back of gutter
              │             │ │   below drip edge
              │   GUTTER    │◄┘
              │             │    1/2" to 1" below
              └─────────────┘    roof line


HANGER SPACING
═══════════════════════════════════════════════════════

Standard: 24" on center
Snow loads: 18" on center
Heavy snow: 12" on center

    ═══════════════════════════════════════════════
    │   │   │   │   │   │   │   │   │   │   │   │
    ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼
    24" between hangers (standard)


DOWNSPOUT CONNECTION
═══════════════════════════════════════════════════════

    ┌──────GUTTER──────┐
    │                  │
    │    ┌──────┐      │
    └────┤OUTLET├──────┘
         └──┬───┘
            │
    ┌───────┴───────┐
    │   ELBOW (A)   │ ← 75° angle
    └───────┬───────┘
            │ Downspout
            │ Section
    ┌───────┴───────┐
    │   ELBOW (B)   │ ← Against wall
    └───────┬───────┘
            │
      DOWNSPOUT
         TO
       GROUND''',
              style: TextStyle(
                color: colors.accentPrimary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonIssues(ZaftoColors colors) {
    final issues = [
      {'issue': 'Overflowing', 'cause': 'Clogged, undersized, or wrong slope', 'fix': 'Clean, resize, or adjust slope'},
      {'issue': 'Sagging', 'cause': 'Insufficient hangers or failed fasteners', 'fix': 'Add hangers, resecure'},
      {'issue': 'Leaking Seams', 'cause': 'Failed sealant or damaged joints', 'fix': 'Reseal or replace section'},
      {'issue': 'Ice Dams', 'cause': 'Heat loss melting snow, refreezing at edge', 'fix': 'Improve attic insulation/venting'},
      {'issue': 'Foundation Water', 'cause': 'Downspouts discharging at foundation', 'fix': 'Add extensions, 4-6ft from house'},
      {'issue': 'Fascia Rot', 'cause': 'Water getting behind gutter', 'fix': 'Install drip edge, reseal'},
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
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Issues & Solutions',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...issues.map((i) => _buildIssueRow(colors, i)),
        ],
      ),
    );
  }

  Widget _buildIssueRow(ZaftoColors colors, Map<String, String> issue) {
    return Container(
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
              Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 14),
              const SizedBox(width: 6),
              Text(issue['issue']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('Cause: ${issue['cause']!}', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.check, color: colors.accentSuccess, size: 10),
              const SizedBox(width: 4),
              Expanded(
                child: Text(issue['fix']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
