import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class FlashingDetailsScreen extends ConsumerWidget {
  const FlashingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Flashing Details',
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
            _buildStepFlashing(colors),
            const SizedBox(height: 24),
            _buildValleyFlashing(colors),
            const SizedBox(height: 24),
            _buildChimneyFlashing(colors),
            const SizedBox(height: 24),
            _buildPipeFlashing(colors),
            const SizedBox(height: 24),
            _buildDripEdge(colors),
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
              Icon(LucideIcons.shield, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Flashing Overview',
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
            'Flashing prevents water infiltration at roof transitions, penetrations, and edges. Most roof leaks occur at flashing locations. Proper installation is critical for a watertight roof.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildFlashingType(colors, 'Step Flashing', 'Walls, dormers, chimneys sides', LucideIcons.chevronUp),
          _buildFlashingType(colors, 'Valley Flashing', 'Where two roof planes meet', LucideIcons.cornerDownRight),
          _buildFlashingType(colors, 'Drip Edge', 'Eaves and rakes', LucideIcons.alignLeft),
          _buildFlashingType(colors, 'Pipe Boot', 'Plumbing vents', LucideIcons.circle),
          _buildFlashingType(colors, 'Counter Flashing', 'Chimney caps, wall tops', LucideIcons.layers),
        ],
      ),
    );
  }

  Widget _buildFlashingType(ZaftoColors colors, String name, String use, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStepFlashing(ZaftoColors colors) {
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
            'Step Flashing (Wall Intersections)',
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
STEP FLASHING AT SIDEWALL
═══════════════════════════════════════════════════════

        WALL SIDING
           │  ║    ║ ← Counter Flashing
           │  ║════╝   (tucked behind siding)
           │  ║
           │  ║   Step Flashing
           │  ║   (L-shaped, 5"×7" min)
           │  ╠═══╗
           │  ║   ║
           │  ║   ╠═══╗
           │  ║   ║   ║
           │  ║   ║   ╠═══╗
           │  ║   ║   ║   ║
    ═══════╩══╩═══╩═══╩═══╩═══════════════════
    │████│████│████│████│████│████│████│████│
    │    │    │    │    │    │    │    │    │
    └────┴────┴────┴────┴────┴────┴────┴────┘
              SHINGLES (5" exposure)


INSTALLATION SEQUENCE:
1. Install shingle course
2. Place step flashing over shingle
3. Nail ONLY top corner of flashing (into wall)
4. Install next shingle course OVER step flashing
5. Repeat - one flashing piece per shingle course

SIZING:
• Width: 5" min (2" on wall, 3"+ on roof)
• Length: 7" min (2" headlap + 5" exposure)
• Material: Galvanized steel or aluminum''',
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

  Widget _buildValleyFlashing(ZaftoColors colors) {
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
              Icon(LucideIcons.cornerDownRight, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Valley Flashing Methods',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildValleyMethod(colors, 'Open Valley',
            'Metal valley exposed, shingles cut back 3" each side. Best water flow.',
            'Best for steep slopes, heavy rain areas', colors.accentSuccess),
          const SizedBox(height: 12),
          _buildValleyMethod(colors, 'Closed Cut Valley',
            'One side shingles run through, other side cut. Faster install.',
            'Common residential method', colors.accentInfo),
          const SizedBox(height: 12),
          _buildValleyMethod(colors, 'Woven Valley',
            'Shingles woven across valley. No metal exposed.',
            'Architectural shingles only', colors.accentWarning),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valley Best Practices:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTipRow(colors, 'Ice & water shield full length of valley'),
                _buildTipRow(colors, 'No nails within 6" of valley centerline'),
                _buildTipRow(colors, 'Seal cut shingle edges with roofing cement'),
                _buildTipRow(colors, 'Clip top corner of shingles at 45° to direct water'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValleyMethod(ZaftoColors colors, String name, String desc, String best, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(best, style: TextStyle(color: accent, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildChimneyFlashing(ZaftoColors colors) {
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
            'Chimney Flashing System',
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
CHIMNEY FLASHING COMPONENTS (Top View)
═══════════════════════════════════════════════════════

                    CHIMNEY
         ┌──────────────────────┐
         │                      │
    STEP │                      │ STEP
    FLASH│      COUNTER         │ FLASH
    (L)  │      FLASHING        │ (R)
         │   (embedded in       │
         │    mortar joints)    │
         │                      │
         └──────────────────────┘
                    ↓
               CRICKET/SADDLE
              (diverts water)
                   ╱╲
                  ╱  ╲
                 ╱    ╲
         ═══════      ═══════
         Shingles    Shingles


CHIMNEY FLASHING (Side View)
═══════════════════════════════════════════════════════

              COUNTER FLASHING
              (in mortar joint)
                    │
         ║═════════╧═════════╗
    ┌────╫─────────────────────┐
    │    ║                     │
    │    ║   CHIMNEY           │
    │    ║                     │
    │    ║   BASE/STEP         │
    │    ╚═══╗  FLASHING       │
    │        ║                 │
    │════════╝                 │
    │████████│████████│████████│ Shingles
    └────────┴────────┴────────┘


INSTALLATION ORDER:
1. Front apron flashing (base)
2. Step flashing up sides
3. Back pan / cricket
4. Counter flashing into mortar joints
5. Seal all joints with roofing sealant''',
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

  Widget _buildPipeFlashing(ZaftoColors colors) {
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
              Icon(LucideIcons.circle, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pipe Boot / Vent Flashing',
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
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
PIPE BOOT INSTALLATION
════════════════════════════════════════

            ┌───────┐
            │ PIPE  │
            │       │
       ┌────┴───────┴────┐
      ╱                   ╲  ← Rubber/Lead
     ╱     BOOT COLLAR     ╲    Boot Cone
    ╱                       ╲
   ╱═════════════════════════╲
  │                           │ ← Metal Base
  │     BASE FLASHING         │
  └───────────────────────────┘
  ═══════════════════════════════  Shingles

INSTALLATION:
1. Cut shingle to fit around pipe
2. Slide boot base UNDER upper shingles
3. Boot base sits OVER lower shingles
4. Nail only top corners of base
5. Apply sealant around boot/pipe junction
6. Shingles lap OVER top of base flashing''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBootType(colors, 'Rubber Boot', 'Standard pipes\n1-6" diameter', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildBootType(colors, 'Lead Boot', 'Custom fit\nMoldable', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildBootType(colors, 'Split Boot', 'Retrofit\nNo pipe removal', colors.accentWarning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBootType(ZaftoColors colors, String name, String desc, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDripEdge(ZaftoColors colors) {
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
              Icon(LucideIcons.alignLeft, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Drip Edge Installation',
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
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
DRIP EDGE SEQUENCE (Critical!)
══════════════════════════════════════════════════

AT EAVES: Drip Edge UNDER Underlayment
─────────────────────────────────────────────────
    ┌────────────────────┐
    │    Underlayment    │ (Goes OVER drip edge)
    │════════════════════│
    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ Ice & Water Shield
    └────────────────────┤
            DRIP EDGE ───┤═══╗
                         │   ║
                         │   ╚═══► Water directed
    ─────────────────────┘        into gutter


AT RAKES: Drip Edge OVER Underlayment
─────────────────────────────────────────────────
    ┌────────────────────┐
    │    Underlayment    │ (Goes UNDER drip edge)
    │════════════════════│
           DRIP EDGE ────┤═══╗
                         │   ║
                         │   ╚═══► Water directed
    ─────────────────────┘        off roof edge

WHY THIS ORDER?
• At eaves: Water running down underlayment
  flows ONTO drip edge, into gutter
• At rakes: Water blowing up can't get under
  drip edge because underlayment is below''',
              style: TextStyle(
                color: colors.accentSuccess,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
