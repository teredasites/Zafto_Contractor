import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class BlueprintSymbolsScreen extends ConsumerWidget {
  const BlueprintSymbolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Blueprint Symbols',
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
            _buildArchitecturalSymbols(colors),
            const SizedBox(height: 24),
            _buildDoorWindowSymbols(colors),
            const SizedBox(height: 24),
            _buildMaterialSymbols(colors),
            const SizedBox(height: 24),
            _buildLineTypes(colors),
            const SizedBox(height: 24),
            _buildScaleReference(colors),
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
              Icon(LucideIcons.fileText, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Blueprint Reading Overview',
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
            'Construction drawings use standardized symbols to convey building information efficiently. Understanding these symbols is essential for reading plans, specs, and shop drawings.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSheetType(colors, 'A', 'Architectural', colors.accentSuccess)),
              const SizedBox(width: 6),
              Expanded(child: _buildSheetType(colors, 'S', 'Structural', colors.accentInfo)),
              const SizedBox(width: 6),
              Expanded(child: _buildSheetType(colors, 'M', 'Mechanical', colors.accentWarning)),
              const SizedBox(width: 6),
              Expanded(child: _buildSheetType(colors, 'E', 'Electrical', colors.accentError)),
              const SizedBox(width: 6),
              Expanded(child: _buildSheetType(colors, 'P', 'Plumbing', colors.accentPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSheetType(ZaftoColors colors, String letter, String type, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Center(child: Text(letter, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 4),
          Text(type, style: TextStyle(color: colors.textTertiary, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildArchitecturalSymbols(ZaftoColors colors) {
    final symbols = [
      {'symbol': '→ A1', 'name': 'Section Cut', 'desc': 'Arrow shows viewing direction'},
      {'symbol': '○ 1/A1', 'name': 'Detail Callout', 'desc': 'Detail # / Sheet #'},
      {'symbol': '△', 'name': 'Elevation Mark', 'desc': 'Interior elevation reference'},
      {'symbol': '⊕', 'name': 'Column Grid', 'desc': 'Grid line intersection'},
      {'symbol': '◇', 'name': 'Room Number', 'desc': 'With room name/finish'},
      {'symbol': '// //', 'name': 'Match Line', 'desc': 'Where plans continue'},
      {'symbol': 'CL', 'name': 'Centerline', 'desc': 'Center of element'},
      {'symbol': '↺', 'name': 'North Arrow', 'desc': 'Plan orientation'},
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
              Icon(LucideIcons.shapes, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Architectural Symbols',
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
            childAspectRatio: 2.5,
            children: symbols.map((s) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.bgBase,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(s['symbol']!, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                        Text(s['desc']!, style: TextStyle(color: colors.textTertiary, fontSize: 8)),
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

  Widget _buildDoorWindowSymbols(ZaftoColors colors) {
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
            'Door & Window Symbols (Plan View)',
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
DOOR SYMBOLS (Plan View)
═══════════════════════════════════════════════════════

  Single Swing        Double Door        Bi-Fold
  ║      ╱            ║    ╱╲    ║       ║ ╱╱╲╲ ║
  ║    ╱              ║  ╱    ╲  ║       ║╱    ╲║
  ║  ╱                ║╱        ╲║       ╠══════╣
  ╠══                 ╠══════════╣

  Pocket Door         Sliding Door       Garage OH
  ══╗                 ═══════════        ════════
    ║                 ╔═══╗             ╔════════╗
    ║                 ║   ║◄─Panel      ║        ║
  ══╝                 ╠═══╣             ║  OPEN  ║
                      ║   ║◄─Fixed      ║   ↑    ║


WINDOW SYMBOLS (Plan View)
═══════════════════════════════════════════════════════

  Fixed              Casement           Double Hung
  ══════════         ══════════         ══════════
  │        │         │   ╱    │         │        │
  │        │         │ ╱      │         │========│
  │        │         │╱       │         │        │
  ══════════         ══════════         ══════════

  Sliding            Awning
  ══════════         ══════════
  │   │    │         │   ↓    │
  │ → │    │         │========│
  │   │    │         │        │
  ══════════         ══════════''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSymbols(ZaftoColors colors) {
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
            'Material Indication (Section)',
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
MATERIAL HATCHING PATTERNS
═══════════════════════════════════════════════════════

  Concrete           Earth/Fill         Wood (End Grain)
  ┌──────────┐       ┌──────────┐       ┌──────────┐
  │ ∙  ∙  ∙ │       │ ×  ×  × │       │ ○○○○○○○ │
  │∙  ∙  ∙  │       │×  ×  ×  │       │ ○○○○○○○ │
  │ ∙  ∙  ∙ │       │ ×  ×  × │       │ ○○○○○○○ │
  └──────────┘       └──────────┘       └──────────┘

  Wood (Section)     Insulation         Steel
  ┌──────────┐       ┌──────────┐       ┌──────────┐
  │ ────── │       │ ∿∿∿∿∿∿ │       │██████████│
  │ ────── │       │ ∿∿∿∿∿∿ │       │          │
  │ ────── │       │ ∿∿∿∿∿∿ │       │██████████│
  └──────────┘       └──────────┘       └──────────┘

  Brick              Block              Glass
  ┌──────────┐       ┌──────────┐       ┌──────────┐
  │▒▒▒│▒▒▒│▒│       │▓▓▓│▓▓▓│▓│       │ ──────── │
  │▒│▒▒▒│▒▒▒│       │▓▓▓▓▓│▓▓▓│       │          │
  │▒▒▒│▒▒▒│▒│       │▓▓▓│▓▓▓│▓│       │ ──────── │
  └──────────┘       └──────────┘       └──────────┘''',
              style: TextStyle(
                color: colors.accentWarning,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineTypes(ZaftoColors colors) {
    final lines = [
      {'type': '────────', 'name': 'Object Line', 'use': 'Visible edges'},
      {'type': '─ ─ ─ ─', 'name': 'Hidden Line', 'use': 'Hidden edges'},
      {'type': '─·─·─·─', 'name': 'Centerline', 'use': 'Symmetry, centers'},
      {'type': '─ · · ─', 'name': 'Property Line', 'use': 'Site boundaries'},
      {'type': '─ ─ X ─', 'name': 'Demo Line', 'use': 'Items to remove'},
      {'type': '════════', 'name': 'Section Cut', 'use': 'Where section cuts'},
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Line Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  child: Text(l['type']!, style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 12)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(l['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                Expanded(child: Text(l['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScaleReference(ZaftoColors colors) {
    final scales = [
      {'scale': '1/8" = 1\'-0"', 'use': 'Floor plans', 'ratio': '1:96'},
      {'scale': '1/4" = 1\'-0"', 'use': 'Floor plans, elevations', 'ratio': '1:48'},
      {'scale': '3/8" = 1\'-0"', 'use': 'Large buildings', 'ratio': '1:32'},
      {'scale': '1/2" = 1\'-0"', 'use': 'Wall sections', 'ratio': '1:24'},
      {'scale': '3/4" = 1\'-0"', 'use': 'Details', 'ratio': '1:16'},
      {'scale': '1" = 1\'-0"', 'use': 'Details', 'ratio': '1:12'},
      {'scale': '1 1/2" = 1\'-0"', 'use': 'Details', 'ratio': '1:8'},
      {'scale': '3" = 1\'-0"', 'use': 'Large details', 'ratio': '1:4'},
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
                'Common Drawing Scales',
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
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('Scale', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text('Typical Use', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ...scales.map((s) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(s['scale']!, style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 11))),
                      Expanded(flex: 2, child: Text(s['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                      Expanded(child: Text(s['ratio']!, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
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
}
