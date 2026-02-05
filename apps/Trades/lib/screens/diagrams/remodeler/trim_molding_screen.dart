import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class TrimMoldingScreen extends ConsumerWidget {
  const TrimMoldingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Trim & Molding',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrimTypes(colors),
            const SizedBox(height: 24),
            _buildMiterCuts(colors),
            const SizedBox(height: 24),
            _buildCopingTechnique(colors),
            const SizedBox(height: 24),
            _buildCrownMolding(colors),
            const SizedBox(height: 24),
            _buildNailingSchedule(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimTypes(ZaftoColors colors) {
    final types = [
      {'name': 'Baseboard', 'size': '3-5.25"', 'use': 'Floor/wall junction'},
      {'name': 'Base Shoe', 'size': '1/2" x 3/4"', 'use': 'Baseboard to floor'},
      {'name': 'Crown', 'size': '2.5-6"', 'use': 'Ceiling/wall junction'},
      {'name': 'Casing', 'size': '2.25-3.5"', 'use': 'Door/window frames'},
      {'name': 'Chair Rail', 'size': '2-3"', 'use': 'Wall protection, 32-36" AFF'},
      {'name': 'Quarter Round', 'size': '3/4"', 'use': 'Corner transitions'},
      {'name': 'Window Stool', 'size': '3/4" x 3.5"', 'use': 'Interior window sill'},
      {'name': 'Apron', 'size': 'Match casing', 'use': 'Below window stool'},
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
              Icon(LucideIcons.frame, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Trim Types',
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
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    t['name']!,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['size']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMiterCuts(ZaftoColors colors) {
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
              Icon(LucideIcons.scissors, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Miter Cuts',
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
              '''OUTSIDE CORNER (45° + 45° = 90°)

        ╱╲
       ╱  ╲
  ════╱    ╲════
     │      │
     │      │

Inside: Back of miter faces out
Outside: Back of miter faces in

INSIDE CORNER (Miter or Cope)

  ════╲
       ╲
        ╲════════
         │
         │

Standard miter gaps over time
Cope joint stays tight

MITER ANGLES FOR CORNERS
┌─────────────┬─────────┬─────────┐
│ Corner      │ Miter   │ Bevel   │
├─────────────┼─────────┼─────────┤
│ 90° (std)   │ 45°     │ 0°      │
│ 135°        │ 22.5°   │ 0°      │
│ 45°         │ 67.5°   │ 0°      │
└─────────────┴─────────┴─────────┘

Formula: Miter = Corner angle ÷ 2''',
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
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Measure corners with angle finder. Few corners are exactly 90°.',
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

  Widget _buildCopingTechnique(ZaftoColors colors) {
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
              Icon(LucideIcons.scissors, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coping Technique',
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
              '''COPING STEPS

1. First piece butts into corner
   │
   │════════════════
   │     FIRST PIECE
   │════════════════

2. Second piece: Cut 45° miter
         ╱
        ╱
   ════╱═══════════
      ╱  SECOND PIECE
     ╱

3. Back-cut along profile line
   Follow the profile edge with
   coping saw at 45° back angle

      ╲│
       │══════════
       │ COPED
      ╱│══════════
     ╱

4. Result: Perfect inside corner
   │
   │═══╗══════════
   │   ║  SECOND
   │═══╝══════════
   │ FIRST''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCopingStep(colors, '1', 'Cut 45° inside miter', 'Reveals profile line'),
          _buildCopingStep(colors, '2', 'Highlight edge', 'Pencil along profile'),
          _buildCopingStep(colors, '3', 'Back-cut with coping saw', 'Follow profile at 45° angle'),
          _buildCopingStep(colors, '4', 'Test fit and adjust', 'File/sand as needed'),
        ],
      ),
    );
  }

  Widget _buildCopingStep(ZaftoColors colors, String num, String action, String note) {
    return Padding(
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
              child: Text(num, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrownMolding(ZaftoColors colors) {
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
              Icon(LucideIcons.frame, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Crown Molding',
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
              '''CROWN ORIENTATION ON SAW

Standard 38° Crown (52°/38° spring angle)

    FENCE  │  Ceiling flat
    ═══════│═══════════════
           │╲
           │ ╲  CROWN
           │  ╲  (upside
           │   ╲  down)
    ───────│────╲──────────
           │  TABLE  Wall flat

Cut crown UPSIDE DOWN:
• Ceiling edge against fence
• Wall edge on table
• "Bottom" facing you

INSIDE CORNER    OUTSIDE CORNER
┌─────────────┬─────────────┐
│ L: 45° R    │ L: 45° L    │
│ R: 45° L    │ R: 45° R    │
│ (cope pref) │ (miter)     │
└─────────────┴─────────────┘''',
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
                    'Common crown is 38° spring angle. Check manufacturer specs - angles vary.',
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

  Widget _buildNailingSchedule(ZaftoColors colors) {
    final schedule = [
      {'trim': 'Baseboard', 'nail': '15ga 2"', 'spacing': '16" OC into studs'},
      {'trim': 'Base shoe', 'nail': '18ga 1.25"', 'spacing': '12" OC into floor'},
      {'trim': 'Casing', 'nail': '15ga 2"', 'spacing': '12" OC, both edges'},
      {'trim': 'Crown (small)', 'nail': '15ga 2"', 'spacing': '16" OC'},
      {'trim': 'Crown (large)', 'nail': '15ga 2.5"', 'spacing': '16" OC + blocking'},
      {'trim': 'Chair rail', 'nail': '15ga 2"', 'spacing': '16" OC into studs'},
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
              Icon(LucideIcons.hammer, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nailing Schedule',
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    s['trim']!,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s['nail']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s['spacing']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tips:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '• Fill nail holes after painting primer coat\n• Pre-drill hardwoods to prevent splitting\n• Glue miters in addition to nailing\n• Set nails 1/16" below surface',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
