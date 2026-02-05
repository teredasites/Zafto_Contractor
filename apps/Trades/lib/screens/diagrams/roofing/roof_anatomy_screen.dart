import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class RoofAnatomyScreen extends ConsumerWidget {
  const RoofAnatomyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Roof Anatomy',
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
            _buildLayersDiagram(colors),
            const SizedBox(height: 24),
            _buildStructuralComponents(colors),
            const SizedBox(height: 24),
            _buildRoofStyles(colors),
            const SizedBox(height: 24),
            _buildTerminology(colors),
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
              Icon(LucideIcons.home, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Roof Anatomy Overview',
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
            'Understanding roof anatomy is essential for proper installation, repair, and inspection. A roof system consists of structural components, weatherproofing layers, and drainage elements.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '15-30', 'Year Lifespan', LucideIcons.calendar)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, '4:12+', 'Min Slope Shingles', LucideIcons.mountain)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, '3 Tab', 'Budget Option', LucideIcons.layers)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String value, String label, IconData icon) {
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
          Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLayersDiagram(ZaftoColors colors) {
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
            'Roof System Layers (Top to Bottom)',
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
                          RIDGE CAP
                             ╱╲
                            ╱  ╲
                           ╱    ╲
═══════════════════════════════════════════════════════════

LAYER 1: SHINGLES (Weather Surface)
┌─────────────────────────────────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│  ████████████████████████████████████████████████████  │
│     Asphalt/Architectural Shingles - 5" exposure       │
└─────────────────────────────────────────────────────────┘

LAYER 2: STARTER STRIP (At eaves)
┌─────────────────────────────────────────────────────────┐
│████████████████████████████████████████████████████████│
│  Adhesive strip seals first course, prevents blow-off  │
└─────────────────────────────────────────────────────────┘

LAYER 3: UNDERLAYMENT (Secondary barrier)
┌─────────────────────────────────────────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│  Synthetic or #15/#30 felt - overlapped 4-6"           │
└─────────────────────────────────────────────────────────┘

LAYER 4: ICE & WATER SHIELD (At eaves, valleys, penetrations)
┌─────────────────────────────────────────────────────────┐
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
│  Self-adhering membrane - seals around nails           │
│  Extends 24" past interior wall line (ice dam zone)    │
└─────────────────────────────────────────────────────────┘

LAYER 5: DRIP EDGE (Metal at eaves and rakes)
┌─────────────────────────────────────────────────────────┐
│══════════════════════════════════════════════════════  │
│  Metal flashing - directs water into gutters           │
└─────────────────────────────────────────────────────────┘

LAYER 6: ROOF DECK (Structural surface)
┌─────────────────────────────────────────────────────────┐
│═══════════════════════════════════════════════════════ │
│  7/16" or 1/2" OSB or plywood sheathing                │
│  H-clips between panels for spacing                    │
└─────────────────────────────────────────────────────────┘

LAYER 7: RAFTERS/TRUSSES (Structural support)
    │         │         │         │         │
    │         │         │         │         │
    ▼         ▼         ▼         ▼         ▼
   16" or 24" on center spacing''',
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

  Widget _buildStructuralComponents(ZaftoColors colors) {
    final components = [
      {'name': 'Ridge', 'desc': 'Horizontal line at roof peak where two slopes meet', 'icon': LucideIcons.minus},
      {'name': 'Hip', 'desc': 'External angle where two roof slopes meet', 'icon': LucideIcons.cornerUpRight},
      {'name': 'Valley', 'desc': 'Internal angle where two roof slopes meet (high water flow)', 'icon': LucideIcons.cornerDownRight},
      {'name': 'Eave', 'desc': 'Lower edge of roof that overhangs the wall', 'icon': LucideIcons.alignLeft},
      {'name': 'Rake', 'desc': 'Sloped edge of roof at gable end', 'icon': LucideIcons.minus},
      {'name': 'Soffit', 'desc': 'Underside of eave overhang (often vented)', 'icon': LucideIcons.square},
      {'name': 'Fascia', 'desc': 'Vertical board at end of rafters (gutter attachment)', 'icon': LucideIcons.minusSquare},
      {'name': 'Dormer', 'desc': 'Window projection through sloped roof', 'icon': LucideIcons.maximize2},
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
              Icon(LucideIcons.layoutGrid, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Structural Components',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: components.map((c) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(c['icon'] as IconData, color: colors.accentSuccess, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                        Text(c['desc'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoofStyles(ZaftoColors colors) {
    final styles = [
      {'name': 'Gable', 'desc': 'Two slopes meeting at ridge. Most common.', 'slope': '4:12 - 12:12'},
      {'name': 'Hip', 'desc': 'Four slopes meeting at ridge. More wind resistant.', 'slope': '4:12 - 8:12'},
      {'name': 'Gambrel', 'desc': 'Barn-style with two different slopes per side.', 'slope': 'Varies'},
      {'name': 'Mansard', 'desc': 'Four-sided gambrel with dormer windows.', 'slope': 'Varies'},
      {'name': 'Flat', 'desc': 'Slight slope for drainage (min 1/4" per foot).', 'slope': '0.25:12 - 2:12'},
      {'name': 'Shed', 'desc': 'Single slope, lean-to style.', 'slope': '4:12+'},
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
              Icon(LucideIcons.home, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Roof Styles',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...styles.map((s) => _buildStyleRow(colors, s)),
        ],
      ),
    );
  }

  Widget _buildStyleRow(ZaftoColors colors, Map<String, String> style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(style['name']!, style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(style['desc']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(style['slope']!, style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminology(ZaftoColors colors) {
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
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Key Terminology',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTermRow(colors, 'Square', '100 sq ft of roof area. Standard measurement unit.'),
          _buildTermRow(colors, 'Slope/Pitch', 'Rise over run (e.g., 6:12 = 6" rise per 12" run)'),
          _buildTermRow(colors, 'Exposure', 'Portion of shingle visible after installation (typically 5")'),
          _buildTermRow(colors, 'Course', 'Horizontal row of shingles'),
          _buildTermRow(colors, 'Bundle', 'Package of shingles. 3 bundles = 1 square (typical)'),
          _buildTermRow(colors, 'Headlap', 'Distance shingle overlaps two courses below (min 2")'),
          _buildTermRow(colors, 'Sidelap', 'Horizontal overlap between adjacent shingles'),
        ],
      ),
    );
  }

  Widget _buildTermRow(ZaftoColors colors, String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(child: Text(definition, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
