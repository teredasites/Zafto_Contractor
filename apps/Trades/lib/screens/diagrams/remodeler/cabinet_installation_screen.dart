import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class CabinetInstallationScreen extends ConsumerWidget {
  const CabinetInstallationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Cabinet Installation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabinetTypes(colors),
            const SizedBox(height: 24),
            _buildStandardDimensions(colors),
            const SizedBox(height: 24),
            _buildInstallationProcess(colors),
            const SizedBox(height: 24),
            _buildLevelingDiagram(colors),
            const SizedBox(height: 24),
            _buildFillerAndScribing(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCabinetTypes(ZaftoColors colors) {
    final types = [
      {'type': 'Base', 'height': '34.5"', 'depth': '24"', 'note': '+1.5" counter = 36" total'},
      {'type': 'Wall/Upper', 'height': '30-42"', 'depth': '12"', 'note': '18" above counter typical'},
      {'type': 'Tall/Pantry', 'height': '84-96"', 'depth': '24"', 'note': 'Full height storage'},
      {'type': 'Vanity', 'height': '31.5"', 'depth': '21"', 'note': '+1.5" = 33" or comfort height'},
      {'type': 'Drawer Base', 'height': '34.5"', 'depth': '24"', 'note': 'All drawers, no doors'},
      {'type': 'Sink Base', 'height': '34.5"', 'depth': '24"', 'note': 'False front, open interior'},
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
              Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cabinet Types',
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
                  width: 80,
                  child: Text(
                    t['type']!,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['height']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['depth']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStandardDimensions(ZaftoColors colors) {
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
                'Standard Dimensions',
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
              '''KITCHEN CABINET LAYOUT (Side View)

                    ↑
            ┌───────────────┐
            │   WALL CAB    │ 30-42"
            │    12" deep   │ height
            └───────────────┘
                    ↓
              ←── 18" ──→ (gap to counter)
                    ↑
╔═══════════════════════════╗
║      COUNTERTOP 1.5"      ║
╠═══════════════════════════╣
║                           ║
║       BASE CABINET        ║ 34.5"
║        24" deep           ║ height
║                           ║
╚═══════════════════════════╝
            ↓
      ←── 4" ──→ (toe kick)

Total: 36" counter height
       54" to upper bottom
       84-96" to upper top''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Standard widths', '9", 12", 15", 18", 21", 24", 27", 30", 33", 36"'),
          _buildDimRow(colors, 'Toe kick', '4" high x 3" deep'),
          _buildDimRow(colors, 'Counter overhang', '1-1.5" past doors'),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildInstallationProcess(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Find high point', 'detail': 'Level across floor, mark high spot'},
      {'step': '2', 'task': 'Mark layout lines', 'detail': '54" from high point for upper bottom'},
      {'step': '3', 'task': 'Locate studs', 'detail': 'Mark all stud locations on wall'},
      {'step': '4', 'task': 'Install ledger', 'detail': 'Temporary support for upper cabs'},
      {'step': '5', 'task': 'Install corner upper', 'detail': 'Start at corner, work outward'},
      {'step': '6', 'task': 'Install remaining uppers', 'detail': 'Clamp, shim, screw through stiles'},
      {'step': '7', 'task': 'Install corner base', 'detail': 'Start at corner, level front-to-back'},
      {'step': '8', 'task': 'Install remaining bases', 'detail': 'Shim for level and plumb'},
      {'step': '9', 'task': 'Connect cabinets', 'detail': 'Screw through face frames'},
      {'step': '10', 'task': 'Install fillers/trim', 'detail': 'Scribe to walls as needed'},
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
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Sequence',
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
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      s['step']!,
                      style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['task']!,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                      Text(
                        s['detail']!,
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
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

  Widget _buildLevelingDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.alignCenterVertical, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Leveling & Shimming',
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
              '''SHIMMING BASE CABINETS

     ┌─────────────────────────────┐
     │         CABINET             │
     │                             │
     └─────────────────────────────┘
       △        △          △      ← Shims at front
       ▲        ▲          ▲      ← Shims at back
    ───────────────────────────────
            UNEVEN FLOOR

Check level:
• Front to back
• Side to side
• Between adjacent cabinets

SECURING TO WALL
    │Wall│
    │    │ ←─ #8 x 2.5" screw
    │════╪═══════════════╗  through
    │    │   CABINET     ║  back rail
    │    │               ║  into stud
    │════╪═══════════════╝
    │    │

Use washer if oversized hole''',
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
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always screw into studs. Wall anchors are not acceptable for cabinet installation.',
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

  Widget _buildFillerAndScribing(ZaftoColors colors) {
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
              Icon(LucideIcons.pencil, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fillers & Scribing',
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
              '''SCRIBING TO UNEVEN WALL

Set compass to largest gap:

Wall →│╲
      │ ╲  ← Compass follows wall
      │  ╲
      │   ╲────────────┐
      │    FILLER      │
      │   ╱────────────┘
      │  ╱  ← Line transferred
      │ ╱     to filler
      │╱

1. Position filler against wall
2. Set compass to widest gap
3. Run compass along wall
4. Cut along scribed line
5. Test fit, sand as needed

FILLER PLACEMENT
┌────┬──────────────────┐
│FILL│                  │ Corners
│ ER │    CABINET       │
└────┴──────────────────┘

┌──────────────────┬────┐
│                  │FILL│ Walls
│    CABINET       │ ER │
└──────────────────┴────┘''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildScribeNote(colors, 'Min filler width', '1.5" (or per manufacturer)'),
          _buildScribeNote(colors, 'Attach method', 'Pocket screws or clamp + face screw'),
          _buildScribeNote(colors, 'Finish edges', 'Edge band before install'),
        ],
      ),
    );
  }

  Widget _buildScribeNote(ZaftoColors colors, String label, String value) {
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
}
