import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class LoadBearingWallsScreen extends ConsumerWidget {
  const LoadBearingWallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Load-Bearing Wall Identification',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarning(colors),
            const SizedBox(height: 24),
            _buildLoadPathDiagram(colors),
            const SizedBox(height: 24),
            _buildIdentificationSigns(colors),
            const SizedBox(height: 24),
            _buildCommonLocations(colors),
            const SizedBox(height: 24),
            _buildHeaderSizing(colors),
            const SizedBox(height: 24),
            _buildRemovalProcess(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CRITICAL SAFETY WARNING',
                  style: TextStyle(
                    color: colors.accentError,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Removing or modifying load-bearing walls without proper support can cause structural collapse, injury, or death. ALWAYS consult a structural engineer before removing any wall. Permits and inspections are required.',
            style: TextStyle(color: colors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadPathDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.arrowDownToLine, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Load Path Diagram',
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
              '''        ROOF LOAD
           ↓↓↓↓↓
    ┌──────────────────┐
    │   ROOF RAFTERS   │
    └────────┬─────────┘
             ↓
    ┌──────────────────┐
    │  TOP PLATE (2x)  │
    └────────┬─────────┘
             ↓
    ┌────────────────────┐
    │                    │
    │  LOAD-BEARING     │ ← Continuous path
    │      WALL          │   to foundation
    │                    │
    └────────┬───────────┘
             ↓
    ┌──────────────────┐
    │  BOTTOM PLATE    │
    └────────┬─────────┘
             ↓
    ┌──────────────────┐
    │  FLOOR JOISTS    │
    └────────┬─────────┘
             ↓
    ┌──────────────────┐
    │   BEAM/GIRDER    │
    └────────┬─────────┘
             ↓
    ┌──────────────────┐
    │   FOUNDATION     │
    └──────────────────┘''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loads transfer from roof to foundation through a continuous path. Load-bearing walls are part of this path.',
            style: TextStyle(color: colors.textSecondary, height: 1.4, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationSigns(ZaftoColors colors) {
    final signs = [
      {
        'sign': 'Perpendicular joists',
        'description': 'Floor/ceiling joists run perpendicular to wall',
        'reliability': 'High',
        'icon': LucideIcons.arrowUpDown,
      },
      {
        'sign': 'Center of house',
        'description': 'Wall runs down the center of the structure',
        'reliability': 'High',
        'icon': LucideIcons.alignCenterHorizontal,
      },
      {
        'sign': 'Stacked walls',
        'description': 'Wall directly above another wall or beam',
        'reliability': 'High',
        'icon': LucideIcons.layers,
      },
      {
        'sign': 'External walls',
        'description': 'All exterior walls are load-bearing',
        'reliability': 'Certain',
        'icon': LucideIcons.home,
      },
      {
        'sign': 'Beam below',
        'description': 'Main beam or girder runs directly beneath',
        'reliability': 'High',
        'icon': LucideIcons.alignVerticalJustifyEnd,
      },
      {
        'sign': 'Thick wall',
        'description': '2x6 studs vs 2x4 (not definitive)',
        'reliability': 'Medium',
        'icon': LucideIcons.moveHorizontal,
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
              Icon(LucideIcons.search, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Identification Signs',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...signs.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(s['icon'] as IconData, color: colors.accentInfo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['sign'] as String,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        s['description'] as String,
                        style: TextStyle(color: colors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (s['reliability'] == 'Certain' || s['reliability'] == 'High')
                        ? colors.accentSuccess.withValues(alpha: 0.2)
                        : colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s['reliability'] as String,
                    style: TextStyle(
                      color: (s['reliability'] == 'Certain' || s['reliability'] == 'High')
                          ? colors.accentSuccess
                          : colors.accentWarning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCommonLocations(ZaftoColors colors) {
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
              Icon(LucideIcons.map, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Load-Bearing Locations',
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
              '''TYPICAL HOUSE PLAN (Load-bearing walls marked ■)

■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■                    ■                ■
■                    ■                ■
■     BEDROOM        ■    BEDROOM     ■
■                    ■                ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■         │                  │        ■
■  BATH   │    HALLWAY       │  BATH  ■
■         │                  │        ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
■                    ■                ■
■                    ■                ■
■     LIVING         ■    KITCHEN     ■
■                    ■                ■
■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

■ = Load-bearing (exterior + center spine)
│ = Likely non-load-bearing partitions''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Always verify with blueprints, attic inspection, and structural engineer.',
            style: TextStyle(color: colors.accentWarning, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSizing(ZaftoColors colors) {
    final headers = [
      {'span': '3\'-0"', 'header': '2-2x4', 'load': 'Light'},
      {'span': '4\'-0"', 'header': '2-2x6', 'load': 'Light'},
      {'span': '5\'-0"', 'header': '2-2x8', 'load': 'Light'},
      {'span': '6\'-0"', 'header': '2-2x10', 'load': 'Moderate'},
      {'span': '8\'-0"', 'header': '2-2x12', 'load': 'Moderate'},
      {'span': '10\'-0"', 'header': 'LVL/Steel', 'load': 'Heavy'},
      {'span': '12\'+ ', 'header': 'Engineered', 'load': 'Heavy'},
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
              Icon(LucideIcons.ruler, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Header Sizing Guide',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Approximate sizing for single story, roof load only. Engineer required for actual design.',
            style: TextStyle(color: colors.accentWarning, fontSize: 10, fontStyle: FontStyle.italic),
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
              '''HEADER CONSTRUCTION

    ┌─────────────────────────────┐
    │ ╔═══════════════════════╗   │ ← Cripple studs
    │ ║                       ║   │   (above header)
    │ ╠═══════════════════════╣   │
    │ ║   HEADER (2x10 shown) ║   │ ← Sized for span
    │ ║   + 1/2" plywood      ║   │
    │ ╠═══════════════════════╣   │
    │ ║                       ║   │
    │ ║      OPENING          ║   │
    │ ║                       ║   │
    │ ╚═══════════════════════╝   │
    │   ▲                   ▲     │
    │ JACK               JACK     │ ← Support header
    │ KING               KING     │ ← Support jack
    └─────────────────────────────┘''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...headers.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(h['span']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                Expanded(
                  child: Text(h['header']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: h['load'] == 'Light'
                        ? colors.accentSuccess.withValues(alpha: 0.2)
                        : h['load'] == 'Moderate'
                            ? colors.accentWarning.withValues(alpha: 0.2)
                            : colors.accentError.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    h['load']!,
                    style: TextStyle(
                      color: h['load'] == 'Light'
                          ? colors.accentSuccess
                          : h['load'] == 'Moderate'
                              ? colors.accentWarning
                              : colors.accentError,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRemovalProcess(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Get engineer assessment', 'note': 'Required before any work'},
      {'step': '2', 'task': 'Obtain permits', 'note': 'Structural permits required'},
      {'step': '3', 'task': 'Install temporary support', 'note': 'Both sides of wall, shored to floor'},
      {'step': '4', 'task': 'Remove wall finish', 'note': 'Expose framing, verify structure'},
      {'step': '5', 'task': 'Install new header', 'note': 'Per engineer specs, with posts'},
      {'step': '6', 'task': 'Transfer load', 'note': 'Shim header tight, remove temp support'},
      {'step': '7', 'task': 'Remove old framing', 'note': 'After load transferred'},
      {'step': '8', 'task': 'Patch/finish', 'note': 'Floor, ceiling, finishes'},
      {'step': '9', 'task': 'Final inspection', 'note': 'Required before covering'},
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
              Icon(LucideIcons.listOrdered, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wall Removal Process',
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      s['step']!,
                      style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['task']!,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        s['note']!,
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
}
