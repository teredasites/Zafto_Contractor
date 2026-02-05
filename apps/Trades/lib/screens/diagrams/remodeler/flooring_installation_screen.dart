import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class FlooringInstallationScreen extends ConsumerWidget {
  const FlooringInstallationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Flooring Installation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlooringTypes(colors),
            const SizedBox(height: 24),
            _buildSubfloorPrep(colors),
            const SizedBox(height: 24),
            _buildLayoutPatterns(colors),
            const SizedBox(height: 24),
            _buildTransitions(colors),
            const SizedBox(height: 24),
            _buildExpansionGaps(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFlooringTypes(ZaftoColors colors) {
    final types = [
      {'type': 'Hardwood', 'install': 'Nail/Staple/Glue', 'subfloor': 'Wood only', 'acclimate': '3-5 days'},
      {'type': 'Engineered', 'install': 'Float/Glue/Nail', 'subfloor': 'Wood/Concrete', 'acclimate': '2-3 days'},
      {'type': 'Laminate', 'install': 'Float', 'subfloor': 'Wood/Concrete', 'acclimate': '48 hrs'},
      {'type': 'LVP/LVT', 'install': 'Float/Glue', 'subfloor': 'Any flat', 'acclimate': '48 hrs'},
      {'type': 'Tile', 'install': 'Thinset mortar', 'subfloor': 'Cement board', 'acclimate': 'None'},
      {'type': 'Carpet', 'install': 'Stretch/Glue', 'subfloor': 'Any smooth', 'acclimate': '24 hrs'},
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Flooring Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 40,
              columnSpacing: 16,
              columns: [
                DataColumn(label: Text('Type', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Install', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Subfloor', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Acclimate', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
              rows: types.map((t) => DataRow(
                cells: [
                  DataCell(Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                  DataCell(Text(t['install']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  DataCell(Text(t['subfloor']!, style: TextStyle(color: colors.accentInfo, fontSize: 10))),
                  DataCell(Text(t['acclimate']!, style: TextStyle(color: colors.accentWarning, fontSize: 10))),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubfloorPrep(ZaftoColors colors) {
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
              Icon(LucideIcons.alignVerticalJustifyEnd, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Subfloor Preparation',
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
              '''FLATNESS CHECK

        10' STRAIGHTEDGE
    ┌─────────────────────────┐
    │         ═══════         │
    │        ╱       ╲        │
────┴───────╱─────────╲───────┴────
    SUBFLOOR         GAP
                   (measure)

Max Variation (per 10'):
• Hardwood: 3/16"
• Laminate: 3/16"
• LVP/LVT: 3/16"
• Tile: 1/4"

MOISTURE TEST LOCATIONS
┌────────────────────────────┐
│  ◯            ◯            │
│       ◯            ◯       │
│  ◯            ◯            │
└────────────────────────────┘
One test per 200 sq ft, plus
exterior walls & plumbing areas''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPrepItem(colors, 'Clean', 'Remove debris, adhesive, staples'),
          _buildPrepItem(colors, 'Level', 'Fill low spots, grind high spots'),
          _buildPrepItem(colors, 'Dry', 'Concrete: <3 lbs/1000sf/24hr'),
          _buildPrepItem(colors, 'Secure', 'Screw squeaky spots, replace damaged OSB'),
          _buildPrepItem(colors, 'Prime', 'Concrete may need primer/sealer'),
        ],
      ),
    );
  }

  Widget _buildPrepItem(ZaftoColors colors, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: desc,
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

  Widget _buildLayoutPatterns(ZaftoColors colors) {
    final patterns = [
      {
        'name': 'Straight/Parallel',
        'diagram': '═══════════\n═══════════\n═══════════',
        'note': 'Most common, easy install',
      },
      {
        'name': 'Staggered',
        'diagram': '═══════════\n  ═══════════\n═══════════',
        'note': 'Random end joints, 6"+ stagger',
      },
      {
        'name': 'Diagonal',
        'diagram': '  ╲  ╲  ╲\n ╲  ╲  ╲\n╲  ╲  ╲',
        'note': '45°, 10-15% more waste',
      },
      {
        'name': 'Herringbone',
        'diagram': '╲╱╲╱╲╱\n╱╲╱╲╱╲\n╲╱╲╱╲╱',
        'note': 'Classic pattern, more labor',
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
          Row(
            children: [
              Icon(LucideIcons.layoutGrid, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Layout Patterns',
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
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: patterns.map((p) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] as String,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p['diagram'] as String,
                    style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    p['note'] as String,
                    style: TextStyle(color: colors.textTertiary, fontSize: 9),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
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
                    'Run planks parallel to longest wall or toward main light source for best appearance.',
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

  Widget _buildTransitions(ZaftoColors colors) {
    final transitions = [
      {'type': 'T-Molding', 'use': 'Same-height floors', 'diagram': '══╤══'},
      {'type': 'Reducer', 'use': 'Higher to lower floor', 'diagram': '══╲__'},
      {'type': 'End Cap', 'use': 'Floor to vertical surface', 'diagram': '══╗'},
      {'type': 'Threshold', 'use': 'Door openings, exterior', 'diagram': '▁▂▃▂▁'},
      {'type': 'Stair Nose', 'use': 'Stair edges', 'diagram': '══╮'},
      {'type': 'Quarter Round', 'use': 'Wall base, expansion gap cover', 'diagram': '│╲'},
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
              Icon(LucideIcons.arrowRightLeft, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transition Strips',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...transitions.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    t['diagram']!,
                    style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['type']!,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        t['use']!,
                        style: TextStyle(color: colors.textSecondary, fontSize: 10),
                      ),
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

  Widget _buildExpansionGaps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.moveHorizontal, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Expansion Gaps (Critical)',
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
              '''EXPANSION GAP LOCATIONS

   ┌─────────────────────────────┐
   │                             │
 ←→│                             │←→
   │         FLOORING            │
   │                             │
 ←→│              ■ ←→           │←→
   │           (island)          │
   │                             │
   └─────────────────────────────┘
         ↕               ↕

←→ = Gap at all walls, cabinets,
     islands, pipes, door frames

TYPICAL GAP SIZES:
• Hardwood: 3/4"
• Laminate: 1/4" - 3/8"
• LVP/LVT: 1/4"
• Engineered: 1/2"''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No gap = buckling, peaking, and floor failure. Always use spacers during install and remove before trim.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildGapNote(colors, 'Floating floors', 'Never secure to subfloor'),
          _buildGapNote(colors, 'Heavy furniture', 'Use furniture pads, allow movement'),
          _buildGapNote(colors, 'Doorways >40\'', 'Add transition strip for long runs'),
          _buildGapNote(colors, 'Room changes', 'Break at doorways with transitions'),
        ],
      ),
    );
  }

  Widget _buildGapNote(ZaftoColors colors, String label, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
