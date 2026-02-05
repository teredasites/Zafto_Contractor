import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class RetainingWallsScreen extends ConsumerWidget {
  const RetainingWallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Retaining Walls',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWallTypes(colors),
            const SizedBox(height: 24),
            _buildSRWInstallation(colors),
            const SizedBox(height: 24),
            _buildDrainageSystem(colors),
            const SizedBox(height: 24),
            _buildSetbackAndBatter(colors),
            const SizedBox(height: 24),
            _buildGeogridReinforcement(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWallTypes(ZaftoColors colors) {
    final types = [
      {'type': 'SRW Block', 'height': '0-4\'', 'engineer': 'No', 'drain': 'Yes', 'note': 'DIY friendly'},
      {'type': 'SRW + Geogrid', 'height': '4-6\'', 'engineer': 'Maybe', 'drain': 'Yes', 'note': 'Reinforced'},
      {'type': 'Engineered SRW', 'height': '6\'+ ', 'engineer': 'Yes', 'drain': 'Yes', 'note': 'Permit required'},
      {'type': 'Boulder', 'height': '0-3\'', 'engineer': 'No', 'drain': 'Yes', 'note': 'Natural look'},
      {'type': 'Timber', 'height': '0-3\'', 'engineer': 'No', 'drain': 'Yes', 'note': 'Shorter lifespan'},
      {'type': 'Poured Concrete', 'height': 'Any', 'engineer': 'Yes', 'drain': 'Yes', 'note': 'Structural'},
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
              Icon(LucideIcons.box, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Wall Types',
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
              dataRowMinHeight: 28,
              dataRowMaxHeight: 36,
              columnSpacing: 12,
              columns: [
                DataColumn(label: Text('Type', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Height', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Engineer', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                DataColumn(label: Text('Note', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
              rows: types.map((t) => DataRow(
                cells: [
                  DataCell(Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                  DataCell(Text(t['height']!, style: TextStyle(color: colors.accentInfo, fontSize: 10))),
                  DataCell(Text(
                    t['engineer']!,
                    style: TextStyle(
                      color: t['engineer'] == 'Yes' ? colors.accentError : colors.accentSuccess,
                      fontSize: 10,
                    ),
                  )),
                  DataCell(Text(t['note']!, style: TextStyle(color: colors.textSecondary, fontSize: 9))),
                ],
              )).toList(),
            ),
          ),
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
                    'Walls over 4\' typically require engineering and permits. Check local codes.',
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

  Widget _buildSRWInstallation(ZaftoColors colors) {
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
              Icon(LucideIcons.layers, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'SRW Block Installation',
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
              '''SRW BLOCK WALL CROSS-SECTION

         BACKFILL (native)
              │  │  │
    ══════════╪══╪══╪════════ ← Cap block
    ▓▓▓▓▓▓▓▓▓▓│  │  │▓▓▓▓▓▓▓▓  (adhesive)
    ██████████│░░░░░│████████ ← Block courses
    ██████████│░░░░░│████████   (staggered)
    ██████████│░░░░░│████████
    ██████████│░░░░░│████████
────██████████│░░░░░│████████────
    ░░░░░░░░░░│░░░░░│░░░░░░░░ ← Base course
    ▓▓▓▓▓▓▓▓▓▓│░░░░░│▓▓▓▓▓▓▓▓   (below grade)
    ──────────┴─────┴────────
           Drain gravel
           + 4" perf pipe

█ = SRW blocks
░ = 3/4" clean gravel
▓ = Compacted base''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInstallStep(colors, '1', 'Excavate trench', '24" wide, below frost line'),
          _buildInstallStep(colors, '2', 'Compact subgrade', '95% compaction'),
          _buildInstallStep(colors, '3', 'Install base material', '6" compacted base'),
          _buildInstallStep(colors, '4', 'Set first course', 'Level and align, below grade'),
          _buildInstallStep(colors, '5', 'Stack courses', 'Stagger joints, check level'),
          _buildInstallStep(colors, '6', 'Backfill with gravel', '12" behind wall minimum'),
          _buildInstallStep(colors, '7', 'Install drain pipe', 'At base, daylight outlet'),
          _buildInstallStep(colors, '8', 'Install cap', 'Construction adhesive'),
        ],
      ),
    );
  }

  Widget _buildInstallStep(ZaftoColors colors, String num, String task, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.accentSuccess,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(task, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                Expanded(
                  child: Text(detail, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainageSystem(ZaftoColors colors) {
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
                'Drainage (Critical)',
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
              '''DRAINAGE SYSTEM

    Water infiltration
           ↓  ↓  ↓
    ┌──────────────────┐
    │   BACKFILL       │
    │      ↓           │
    │   ┌──────────┐   │
    │   │ GRAVEL   │   │ ← Drainage aggregate
    │   │  ZONE    │   │   12" min behind wall
    │   │    ↓     │   │
    │   │  ══════  │   │ ← Filter fabric wrap
    │   │  ○○○○○○  │   │ ← 4" perforated pipe
    │   └──────────┘   │   holes DOWN
    └──────────────────┘
              ↓
        To daylight or
        dry well outlet

PIPE SLOPE: 1/8" per foot minimum''',
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
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Without drainage:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '• Hydrostatic pressure builds behind wall\n• Freeze/thaw cycles cause heaving\n• Wall will lean, crack, and fail\n• Always install drainage system',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetbackAndBatter(ZaftoColors colors) {
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
              Icon(LucideIcons.alignEndVertical, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Setback & Batter',
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
              '''SETBACK (Built-in lean)

    Vertical    With Setback
       │            ╲
       │             ╲
    ███│          ████╲
    ███│         █████╲
    ███│        ██████╲
    ███│       ███████╲
    ───┴──     ────────╲

Each course sets back from
the one below (per block design)

TYPICAL SETBACK:
• SRW blocks: 3/4" - 1" per course
• Creates batter angle ~10-15°
• Moves weight into slope
• Increases stability

SURCHARGE ZONE:
Keep heavy loads away from top:
┌────────────────────────┐
│  NO PARKING/STRUCTURES │
│  within H distance     │
└────────────────────────┘
         ↑ H (wall height)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeogridReinforcement(ZaftoColors colors) {
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
              Icon(LucideIcons.layoutGrid, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Geogrid Reinforcement',
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
              '''GEOGRID PLACEMENT

              ←── Grid length = 60% wall height
    ──────────────────────────────────
    ████████│ GRID 3 │░░░░░░░░░░░░░░░
    ████████├────────┤░░░░░░░░░░░░░░░
    ████████│        │░░░░░░░░░░░░░░░
    ████████│ GRID 2 │░░░░░░░░░░░░░░░
    ████████├────────┤░░░░░░░░░░░░░░░
    ████████│        │░░░░░░░░░░░░░░░
    ████████│ GRID 1 │░░░░░░░░░░░░░░░
    ████████├────────┤░░░░░░░░░░░░░░░
    ▓▓▓▓▓▓▓▓└────────┘▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ────────────────────────────────

GRID SPACING (typical):
• First grid: 8-12" from base
• Additional grids: every 16-24"
• Per engineer specs for walls >4\'''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildGeogridNote(colors, 'Grid length', 'Typically 60-100% of wall height'),
          _buildGeogridNote(colors, 'Overlap', '12" minimum at splices'),
          _buildGeogridNote(colors, 'Compaction', 'Compact fill over grid before next course'),
          _buildGeogridNote(colors, 'Orientation', 'Strong direction perpendicular to wall'),
        ],
      ),
    );
  }

  Widget _buildGeogridNote(ZaftoColors colors, String label, String value) {
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
}
