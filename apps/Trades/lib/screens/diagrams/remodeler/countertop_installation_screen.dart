import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class CountertopInstallationScreen extends ConsumerWidget {
  const CountertopInstallationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Countertop Installation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountertopTypes(colors),
            const SizedBox(height: 24),
            _buildTemplating(colors),
            const SizedBox(height: 24),
            _buildLaminateInstall(colors),
            const SizedBox(height: 24),
            _buildStoneInstall(colors),
            const SizedBox(height: 24),
            _buildCutouts(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCountertopTypes(ZaftoColors colors) {
    final types = [
      {'type': 'Laminate', 'thickness': '1.5"', 'cost': '\$', 'seams': 'Visible', 'diy': 'Yes'},
      {'type': 'Butcher Block', 'thickness': '1.5"', 'cost': '\$\$', 'seams': 'Visible', 'diy': 'Yes'},
      {'type': 'Solid Surface', 'thickness': '0.5-1"', 'cost': '\$\$', 'seams': 'Invisible', 'diy': 'No'},
      {'type': 'Quartz', 'thickness': '1.25-3cm', 'cost': '\$\$\$', 'seams': 'Minimal', 'diy': 'No'},
      {'type': 'Granite', 'thickness': '2-3cm', 'cost': '\$\$\$', 'seams': 'Visible', 'diy': 'No'},
      {'type': 'Concrete', 'thickness': '1.5-2"', 'cost': '\$\$', 'seams': 'None (cast)', 'diy': 'Possible'},
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
              Icon(LucideIcons.square, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Countertop Types',
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
              columnSpacing: 12,
              columns: [
                DataColumn(label: Text('Type', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Thick', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Cost', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Seams', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('DIY', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
              rows: types.map((t) => DataRow(
                cells: [
                  DataCell(Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
                  DataCell(Text(t['thickness']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  DataCell(Text(t['cost']!, style: TextStyle(color: colors.accentWarning, fontSize: 10))),
                  DataCell(Text(t['seams']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  DataCell(Text(t['diy']!, style: TextStyle(color: t['diy'] == 'Yes' ? colors.accentSuccess : colors.accentError, fontSize: 10))),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplating(ZaftoColors colors) {
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
              Icon(LucideIcons.ruler, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Templating',
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
              '''TEMPLATE MEASUREMENTS

┌─────────────────────────────────────────┐
│                                         │
│  ◯ Sink cutout    ◯ Cooktop             │
│  ┌─────────┐      ┌─────────┐           │
│  │         │      │         │           │
│  │  SINK   │      │ COOKTOP │           │
│  │         │      │         │           │
│  └─────────┘      └─────────┘           │
│                               ◯ Faucet  │
│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
│         BACKSPLASH ZONE                 │
└─────────────────────────────────────────┘
  ↕ 1-1.5" overhang

MEASUREMENTS NEEDED:
• Overall length (each section)
• Depth at multiple points
• All cutout positions from edges
• Wall contours (use compass)
• Corner angles if not 90°''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTemplateNote(colors, 'Digital template', 'Laser measure + digital output'),
          _buildTemplateNote(colors, 'Physical template', 'Cardboard, thin plywood, or sticks'),
          _buildTemplateNote(colors, 'Overhang', '1" front, 1/2" on sides typical'),
          _buildTemplateNote(colors, 'Faucet holes', 'Mark center, verify clearance'),
        ],
      ),
    );
  }

  Widget _buildTemplateNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
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

  Widget _buildLaminateInstall(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Check cabinet level', 'note': 'Shim cabinets if needed'},
      {'step': '2', 'task': 'Dry fit countertop', 'note': 'Check all joints and walls'},
      {'step': '3', 'task': 'Scribe to walls', 'note': 'Mark and trim irregular walls'},
      {'step': '4', 'task': 'Cut sink/cooktop holes', 'note': 'Jigsaw with fine blade'},
      {'step': '5', 'task': 'Apply adhesive', 'note': 'Silicone at corners, construction adhesive'},
      {'step': '6', 'task': 'Set countertop', 'note': 'Press firmly into adhesive'},
      {'step': '7', 'task': 'Join sections', 'note': 'Miter bolts underneath'},
      {'step': '8', 'task': 'Secure from below', 'note': 'Screws through corner blocks'},
      {'step': '9', 'task': 'Caulk backsplash', 'note': 'Silicone, color match'},
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
              Icon(LucideIcons.layers, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Laminate Installation',
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
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(s['step']!, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['task']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                      Text(s['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
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

  Widget _buildStoneInstall(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mountain, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stone/Quartz Installation',
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
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stone countertops require professional installation due to weight (15-20 lbs/sq ft) and specialized tools.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
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
              '''STONE SUPPORT REQUIREMENTS

Standard cabinets sufficient for:
• 3cm (1.25") granite/quartz
• With supports every 24"

Additional support needed for:
• 2cm material
• Overhangs > 10"
• Heavy-use areas
• Dishwasher openings

OVERHANG SUPPORT
┌────────────────────────────────┐
│        COUNTERTOP              │
│                     ┌──────────┤
│                     │overhang  │ ≤10": no support
│                     │          │ >10": brackets
└─────────────────────┴──────────┘
                      ↕ max 12" unsupported
                        for 3cm stone''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStoneNote(colors, 'Seams', 'Epoxy color-matched, nearly invisible'),
          _buildStoneNote(colors, 'Sink mount', 'Undermount typical for stone'),
          _buildStoneNote(colors, 'Edge profiles', 'Eased, bullnose, ogee, beveled'),
        ],
      ),
    );
  }

  Widget _buildStoneNote(ZaftoColors colors, String label, String value) {
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
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCutouts(ZaftoColors colors) {
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
              Icon(LucideIcons.scissors, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sink & Cooktop Cutouts',
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
              '''SINK CUTOUT (Laminate DIY)

    Template provided with sink
    ┌───────────────────────────┐
    │   ╭───────────────────╮   │
    │   │                   │   │
    │   │      CUTOUT       │   │ ← Use template
    │   │     (inside)      │   │   or measure
    │   │                   │   │   from sink
    │   ╰───────────────────╯   │
    │                           │
    │←──────── SINK ──────────→│
    └───────────────────────────┘

CUTTING STEPS:
1. Position template, tape securely
2. Trace outline
3. Drill starter holes at corners (3/8")
4. Cut with jigsaw (fine tooth blade)
5. Cut from underneath to prevent chipping
6. Support cutout piece to prevent breaking

DROP-IN vs UNDERMOUNT
┌─────────────────┐  ┌─────────────────┐
│ ┌───────────┐   │  │                 │
│ │ DROP-IN   │   │  │  ╔═══════════╗  │
│ │  (rim on  │   │  │  ║UNDERMOUNT ║  │
│ │   top)    │   │  │  ║(rim below)║  │
│ └───────────┘   │  │  ╚═══════════╝  │
└─────────────────┘  └─────────────────┘''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                    'Measure twice, cut once. Cutouts cannot be undone. Verify dimensions match actual sink/cooktop.',
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
}
