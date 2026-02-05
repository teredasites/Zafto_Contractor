import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PlantingGuidelinesScreen extends ConsumerWidget {
  const PlantingGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Planting Guidelines',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTreePlanting(colors),
            const SizedBox(height: 24),
            _buildShrubPlanting(colors),
            const SizedBox(height: 24),
            _buildSpacingGuide(colors),
            const SizedBox(height: 24),
            _buildMulching(colors),
            const SizedBox(height: 24),
            _buildWateringEstablishment(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTreePlanting(ZaftoColors colors) {
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
              Icon(LucideIcons.treePine, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tree Planting',
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
              '''PROPER TREE PLANTING DEPTH

                    │ │
                   ╱│ │╲
                  ╱ │ │ ╲
                 ╱  │ │  ╲
                ╱   │ │   ╲
               ╱    │ │    ╲  CANOPY
              ╱     │ │     ╲
             ╱      │ │      ╲
            ────────┘ └────────
                    │ │  TRUNK
    ════════════════╧═╧════════════════
    ░░░░░░░░░░░MULCH░░░░░░░░░░░ ← 2-4" mulch
    ════════════════╤═╤══════════RING← Keep away
         │    ROOT ═╪═╪═ FLARE ←     from trunk
         │  ┌──────═╪═╪═──────┐
         │  │ ROOT  │ │  BALL │      Root flare
         │  │       │ │       │      AT or ABOVE
         │  └───────┴─┴───────┘      grade level
         ▼
    Hole 2-3× wider than root ball
    Same depth or slightly shallower''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
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
                    '#1 planting mistake: Too deep. Root flare must be visible at soil surface.',
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

  Widget _buildShrubPlanting(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Dig hole 2× root ball width', 'note': 'Same depth as container'},
      {'step': '2', 'task': 'Score root ball sides', 'note': 'Break circling roots'},
      {'step': '3', 'task': 'Set plant at proper height', 'note': 'Top of root ball at grade'},
      {'step': '4', 'task': 'Backfill with native soil', 'note': 'No amendments in hole'},
      {'step': '5', 'task': 'Create water basin', 'note': 'Soil ring around plant'},
      {'step': '6', 'task': 'Water deeply', 'note': 'Fill basin 2-3 times'},
      {'step': '7', 'task': 'Apply mulch', 'note': '2-4" depth, away from stem'},
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
              Icon(LucideIcons.flower, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Shrub Planting Steps',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['task']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                      Text(s['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
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

  Widget _buildSpacingGuide(ZaftoColors colors) {
    final spacing = [
      {'type': 'Large shade tree', 'mature': '60-80\'', 'spacing': '40-60\'', 'fromHouse': '20\''},
      {'type': 'Medium tree', 'mature': '30-50\'', 'spacing': '25-35\'', 'fromHouse': '15\''},
      {'type': 'Small ornamental', 'mature': '15-25\'', 'spacing': '15-20\'', 'fromHouse': '10\''},
      {'type': 'Large shrub', 'mature': '8-12\'', 'spacing': '6-10\'', 'fromHouse': '6\''},
      {'type': 'Medium shrub', 'mature': '4-6\'', 'spacing': '3-5\'', 'fromHouse': '4\''},
      {'type': 'Small shrub', 'mature': '2-3\'', 'spacing': '2-3\'', 'fromHouse': '2\''},
      {'type': 'Perennials', 'mature': '1-3\'', 'spacing': '12-24"', 'fromHouse': '1\''},
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
              Icon(LucideIcons.ruler, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spacing Guide',
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
              columnSpacing: 12,
              columns: [
                DataColumn(label: Text('Type', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Mature', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Spacing', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('House', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
              rows: spacing.map((s) => DataRow(
                cells: [
                  DataCell(Text(s['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                  DataCell(Text(s['mature']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  DataCell(Text(s['spacing']!, style: TextStyle(color: colors.accentInfo, fontSize: 10))),
                  DataCell(Text(s['fromHouse']!, style: TextStyle(color: colors.accentWarning, fontSize: 10))),
                ],
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Spacing = mature width. Plant for mature size, not nursery size.',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMulching(ZaftoColors colors) {
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
              Icon(LucideIcons.layers, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mulching',
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
              '''CORRECT vs VOLCANO MULCHING

    CORRECT:              WRONG (Volcano):
        │                      ╱│╲
        │                     ╱ │ ╲
        │                    ╱  │  ╲
    ────┴────            ───╱───┴───╲───
   ░░░░░░░░░░            ░░░░░░░░░░░░░░░
   ░░░░░░░░░░            ░░░░░░░░░░░░░░░
   ═══════════           ═══════════════

   2-4" depth            TOO DEEP!
   3" from trunk         Against trunk

Volcano mulch causes:
• Bark rot and disease
• Girdling roots
• Rodent damage
• Moisture stress''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildMulchItem(colors, 'Hardwood bark', 'Best for beds, decomposes slowly'),
          _buildMulchItem(colors, 'Pine needles', 'Acid-loving plants, stays in place'),
          _buildMulchItem(colors, 'Wood chips', 'Trees, paths, naturalizes'),
          _buildMulchItem(colors, 'Rubber mulch', 'Playgrounds only, not for plants'),
          _buildMulchItem(colors, 'Stone/gravel', 'Doesn\'t decompose, heats soil'),
        ],
      ),
    );
  }

  Widget _buildMulchItem(ZaftoColors colors, String type, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(
            '$type: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildWateringEstablishment(ZaftoColors colors) {
    final schedule = [
      {'period': 'Week 1-2', 'trees': 'Daily', 'shrubs': 'Daily', 'perennials': '2x daily'},
      {'period': 'Week 3-4', 'trees': 'Every other day', 'shrubs': 'Every other day', 'perennials': 'Daily'},
      {'period': 'Month 2-3', 'trees': '2x weekly', 'shrubs': '2x weekly', 'perennials': 'Every other day'},
      {'period': 'Months 3-12', 'trees': 'Weekly', 'shrubs': 'Weekly', 'perennials': '2x weekly'},
      {'period': 'Year 2+', 'trees': 'As needed', 'shrubs': 'As needed', 'perennials': 'As needed'},
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
                'Establishment Watering',
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
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(s['period']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(s['trees']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                Expanded(
                  child: Text(s['shrubs']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10)),
                ),
                Expanded(
                  child: Text(s['perennials']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(colors, 'Trees', colors.accentInfo),
              _buildLegendItem(colors, 'Shrubs', colors.accentSuccess),
              _buildLegendItem(colors, 'Perennials', colors.accentWarning),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rule: 1 gallon per inch of trunk caliper, 2-3x weekly for trees. Deep, infrequent watering builds deep roots.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ZaftoColors colors, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
      ],
    );
  }
}
