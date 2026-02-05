import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class BathroomRemodelScreen extends ConsumerWidget {
  const BathroomRemodelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Bathroom Remodel Basics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLayoutDiagram(colors),
            const SizedBox(height: 24),
            _buildClearances(colors),
            const SizedBox(height: 24),
            _buildRoughInDimensions(colors),
            const SizedBox(height: 24),
            _buildWaterproofing(colors),
            const SizedBox(height: 24),
            _buildVentilation(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.bath, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Bathroom Layout Types',
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
              '''FULL BATH (5x8 min)      3/4 BATH (6x6 min)
┌─────────────┐          ┌─────────────┐
│ ┌─────────┐ │          │ ┌───┐       │
│ │  TUB/   │ │          │ │SHW│  ┌──┐ │
│ │ SHOWER  │ │          │ └───┘  │WC│ │
│ └─────────┘ │          │        └──┘ │
│ ┌──┐  ┌───┐ │          │ ┌─────────┐ │
│ │WC│  │SNK│ │          │ │  SINK   │ │
│ └──┘  └───┘ │          │ └─────────┘ │
└─────────────┘          └─────────────┘

HALF BATH (3x6 min)      MASTER BATH
┌─────────┐              ┌─────────────────┐
│   ┌───┐ │              │ ┌─────┐ ┌─────┐ │
│   │SNK│ │              │ │ TUB │ │ SHW │ │
│   └───┘ │              │ └─────┘ └─────┘ │
│   ┌──┐  │              │ ┌──┐   DBL SNK  │
│   │WC│  │              │ │WC│  ┌───────┐ │
│   └──┘  │              │ └──┘  └───────┘ │
└─────────┘              └─────────────────┘''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearances(ZaftoColors colors) {
    final clearances = [
      {'fixture': 'Toilet', 'front': '21" (24" pref)', 'side': '15" CL min', 'total': '30" width'},
      {'fixture': 'Sink', 'front': '21" min', 'side': '4" to wall', 'total': '24-30" wide'},
      {'fixture': 'Shower', 'front': '24" min', 'side': 'N/A', 'total': '30x30" min'},
      {'fixture': 'Tub', 'front': '21" min', 'side': 'N/A', 'total': '60x30" std'},
      {'fixture': 'Door swing', 'front': '32" clear', 'side': 'Full swing in', 'total': 'Out-swing ok'},
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
              Icon(LucideIcons.ruler, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Code Clearances',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
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
              dataRowMinHeight: 28,
              dataRowMaxHeight: 36,
              columnSpacing: 16,
              columns: [
                DataColumn(label: Text('Fixture', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Front', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Side', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Size', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
              rows: clearances.map((c) => DataRow(
                cells: [
                  DataCell(Text(c['fixture']!, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
                  DataCell(Text(c['front']!, style: TextStyle(color: colors.accentWarning, fontSize: 11))),
                  DataCell(Text(c['side']!, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                  DataCell(Text(c['total']!, style: TextStyle(color: colors.accentInfo, fontSize: 11))),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoughInDimensions(ZaftoColors colors) {
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
              Icon(LucideIcons.pipette, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plumbing Rough-In Dimensions',
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
              '''TOILET ROUGH-IN
                    ┌─────────┐
  Supply: 6" left   │         │
  of CL, 8" high    │   WC    │
                    │         │
      ◯ ←───────── 12" from wall (std)
     Supply        └─────────┘
                   │← 15" →│ to side wall min

SINK ROUGH-IN           SHOWER ROUGH-IN
  ┌───────────┐         ┌───────────┐
  │   SINK    │         │  SHOWER   │
  └─────┬─────┘         │           │
  Supply│Drain          │     ◯     │ ← Valve: 48" AFF
  ├──┼──┤               │   Drain   │   (38-48" range)
  │  │  │               └─────┬─────┘
Hot│  │Cold                   │
20"  18"  20"           Drain: centered
  AFF  AFF              2" min drain''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRoughInNote(colors, 'Toilet', '12" rough-in standard, verify before purchase'),
          _buildRoughInNote(colors, 'Sink drain', '18-20" AFF center'),
          _buildRoughInNote(colors, 'Sink supply', '20-22" AFF, 4" apart'),
          _buildRoughInNote(colors, 'Shower valve', '38-48" AFF (48" standard)'),
          _buildRoughInNote(colors, 'Tub spout', '4" above tub rim'),
        ],
      ),
    );
  }

  Widget _buildRoughInNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.accentInfo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterproofing(ZaftoColors colors) {
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
              Icon(LucideIcons.droplets, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Waterproofing Critical Zones',
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
              '''SHOWER WATERPROOFING
┌─────────────────────────────────┐
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← Ceiling optional
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  Membrane to
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  ceiling or 6"
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  above shower
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  head
│░░░░░░░░ SHOWER PAN ░░░░░░░░░░░░░│
└───────────────┬─────────────────┘
                │
          Pre-slope to drain
          1/4" per foot min

░ = Waterproof membrane required''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildWaterproofItem(colors, 'Shower floor', 'Pre-slope + liner + mortar + membrane'),
          _buildWaterproofItem(colors, 'Shower walls', 'Cement board + liquid/sheet membrane'),
          _buildWaterproofItem(colors, 'Tub surround', 'Moisture barrier min 72" high'),
          _buildWaterproofItem(colors, 'Curb', 'Waterproof all surfaces, slope top'),
          _buildWaterproofItem(colors, 'Corners', 'Pre-formed corners or extra membrane'),
          _buildWaterproofItem(colors, 'Penetrations', 'Seal around valve, showerhead, drain'),
        ],
      ),
    );
  }

  Widget _buildWaterproofItem(ZaftoColors colors, String area, String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$area: ',
                    style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: requirement,
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

  Widget _buildVentilation(ZaftoColors colors) {
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
              Icon(LucideIcons.wind, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ventilation Requirements',
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
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code Requirement (IRC R303.3)',
                  style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bathrooms must have either:\n• Openable window (3 sq ft min)\n• Mechanical exhaust (50 CFM intermittent or 20 CFM continuous)',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildVentRow(colors, 'Small bath (<50 sq ft)', '50 CFM'),
          _buildVentRow(colors, 'Medium bath (50-100 sq ft)', '1 CFM/sq ft'),
          _buildVentRow(colors, 'Large bath (>100 sq ft)', '1 CFM/sq ft'),
          _buildVentRow(colors, 'Toilet room', '50 CFM'),
          _buildVentRow(colors, 'Jetted tub', '100 CFM'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
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
                    'Duct to exterior required. Never vent to attic.',
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

  Widget _buildVentRow(ZaftoColors colors, String room, String cfm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(room, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(cfm, style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
