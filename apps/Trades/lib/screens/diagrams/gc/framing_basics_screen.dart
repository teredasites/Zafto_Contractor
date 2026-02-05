import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class FramingBasicsScreen extends ConsumerWidget {
  const FramingBasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Framing Basics',
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
            _buildWallFraming(colors),
            const SizedBox(height: 24),
            _buildFloorFraming(colors),
            const SizedBox(height: 24),
            _buildRoofFraming(colors),
            const SizedBox(height: 24),
            _buildLumberSizes(colors),
            const SizedBox(height: 24),
            _buildNailingSchedule(colors),
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
              Icon(LucideIcons.home, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Framing Basics Overview',
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
            'Wood framing creates the structural skeleton of a building. Standard framing uses 16" or 24" on-center spacing with dimensional lumber. Understanding framing terms and methods is essential for construction.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '16" O.C.', 'Standard Spacing', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '2×4 / 2×6', 'Wall Studs', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, 'SPF #2', 'Common Grade', colors.accentWarning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWallFraming(ZaftoColors colors) {
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
            'Wall Framing Components',
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
TYPICAL WALL SECTION
═══════════════════════════════════════════════════════════

    ╔═══════════════════════════════════════════════════╗
    ║               DOUBLE TOP PLATE                    ║
    ╠═══════════════════════════════════════════════════╣
    ║   │      │      │      │      │      │      │    ║
    ║   │      │      │      │      │      │      │    ║
    ║   │      │      │      │      │      │      │    ║
    ║   │      │      │   HEADER                  │    ║
    ║   │      │      │  ╔═══════════════╗        │    ║
    ║   │      │      │  ║  2×10 or LVL ║        │    ║
    ║   │      │ KING │  ╠═══════════════╣  KING │    ║
    ║   │ STUD │ STUD │  ║   JACK STUD  ║  STUD │    ║
    ║   │      │      │  ║   (Trimmer)  ║       │    ║
    ║   │      │      │  ║              ║       │    ║
    ║   │      │      │  ║   WINDOW     ║       │    ║
    ║   │      │      │  ║   OPENING    ║       │    ║
    ║   │      │      │  ║              ║       │    ║
    ║   │      │      │  ╠═══════════════╣       │    ║
    ║   │      │      │  ║    SILL      ║       │    ║
    ║   │      │      │  ╠═══════════════╣       │    ║
    ║   │      │      │  ║   CRIPPLE    ║       │    ║
    ║   │      │      │  ║    STUDS     ║       │    ║
    ╠═══╪══════╪══════╪══╩═══════════════╩═══════╪════╣
    ║                  BOTTOM PLATE                    ║
    ╚═══════════════════════════════════════════════════╝
         16" O.C.  16" O.C.                 16" O.C.


TERMS:
• Top Plate: Double 2× at top of wall
• Bottom Plate: Single 2× at base (PT if on concrete)
• Stud: Vertical 2×4 or 2×6 at 16" or 24" O.C.
• King Stud: Full-height stud beside opening
• Jack Stud: Shortened stud supporting header
• Header: Beam over opening (sized per span)
• Cripple: Short stud above/below opening''',
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

  Widget _buildFloorFraming(ZaftoColors colors) {
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
            'Floor Framing System',
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
FLOOR FRAMING (Plan View)
═══════════════════════════════════════════════════════════

    BEAM OR BEARING WALL
    ════════════════════════════════════════════════════
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │ FLOOR JOISTS │    │    │    │    │
    │    │    │    │  16" O.C.    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    ═══════════════│════│════│════│════│═════════════════
                   │    │    │    │    │
                   │ BLOCKING/BRIDGING │
                   │    (mid-span)     │
    ═══════════════│════│════│════│════│═════════════════
    │    │    │    │    │    │    │    │    │    │    │
    │    │    │    │    │    │    │    │    │    │    │
    ════════════════════════════════════════════════════
    RIM/BAND JOIST (At perimeter)


JOIST SIZING (L/360 deflection, 40 PSF live + 10 dead)
═══════════════════════════════════════════════════════════
Span        16" O.C.       24" O.C.
8'          2×6            2×8
10'         2×8            2×8
12'         2×8            2×10
14'         2×10           2×10
16'         2×10           2×12
18'         2×12           I-joist''',
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

  Widget _buildRoofFraming(ZaftoColors colors) {
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
            'Roof Framing Options',
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
STICK-FRAMED RAFTER ROOF
═══════════════════════════════════════════════════════════

                     RIDGE BOARD
                         │
                        ╱│╲
                       ╱ │ ╲
           RAFTER ───►╱  │  ╲◄─── RAFTER
                     ╱   │   ╲
                    ╱    │    ╲
                   ╱     │     ╲
                  ╱──────┴──────╲◄── COLLAR TIE
                 ╱               ╲    (upper 1/3)
                ╱                 ╲
═══════════════╱═══════════════════╲═══════════════════
              ║                     ║
    CEILING   ║                     ║  CEILING
    JOIST ───►║                     ║◄─── JOIST
              ║                     ║
              ╚═════════════════════╝
                    WALL PLATES


PRE-ENGINEERED TRUSSES (More common today)
═══════════════════════════════════════════════════════════

                        ╱╲
                       ╱  ╲  TOP CHORD
                      ╱    ╲
                     ╱  WEB ╲
                    ╱   ╲╱   ╲
                   ╱   ╱╲╱╲   ╲
                  ╱   ╱    ╲   ╲
                 ╱   ╱      ╲   ╲
                ╱   ╱        ╲   ╲
═══════════════╱═══════════════════╲═══════════════════
               BOTTOM CHORD
                (Ceiling support)

• Engineered for specific loads
• Spacing: 24" O.C. typical
• Never cut or modify without engineer approval''',
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

  Widget _buildLumberSizes(ZaftoColors colors) {
    final sizes = [
      {'nominal': '2×4', 'actual': '1.5" × 3.5"'},
      {'nominal': '2×6', 'actual': '1.5" × 5.5"'},
      {'nominal': '2×8', 'actual': '1.5" × 7.25"'},
      {'nominal': '2×10', 'actual': '1.5" × 9.25"'},
      {'nominal': '2×12', 'actual': '1.5" × 11.25"'},
      {'nominal': '4×4', 'actual': '3.5" × 3.5"'},
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
                'Lumber Sizes (Nominal vs Actual)',
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
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: sizes.map((s) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s['nominal']!, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(s['actual']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNailingSchedule(ZaftoColors colors) {
    final schedule = [
      {'connection': 'Stud to plate (end)', 'nails': '2-16d', 'method': 'End nail'},
      {'connection': 'Stud to plate (toe)', 'nails': '4-8d', 'method': 'Toe nail'},
      {'connection': 'Double top plate', 'nails': '16d @ 16" O.C.', 'method': 'Face nail'},
      {'connection': 'Header to stud', 'nails': '4-16d', 'method': 'End nail'},
      {'connection': 'Joist to sill/plate', 'nails': '3-8d', 'method': 'Toe nail'},
      {'connection': 'Subfloor to joist', 'nails': '8d @ 6"/12"', 'method': 'Face nail'},
      {'connection': 'Sheathing to stud', 'nails': '8d @ 6"/12"', 'method': 'Face nail'},
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
              Icon(LucideIcons.hammer, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nailing Schedule (IRC Table 602.3(1))',
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
                Expanded(
                  flex: 2,
                  child: Text(s['connection']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                Expanded(
                  child: Text(s['nails']!, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                Expanded(
                  child: Text(s['method']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
