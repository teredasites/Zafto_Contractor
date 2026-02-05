import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class RoofVentilationScreen extends ConsumerWidget {
  const RoofVentilationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Roof Ventilation',
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
            _buildVentilationDiagram(colors),
            const SizedBox(height: 24),
            _buildVentTypes(colors),
            const SizedBox(height: 24),
            _buildCalculations(colors),
            const SizedBox(height: 24),
            _buildBestPractices(colors),
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
              Icon(LucideIcons.wind, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Roof Ventilation Overview',
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
            'Proper attic ventilation removes heat and moisture, extending roof life and preventing ice dams. A balanced system requires intake (soffit) and exhaust (ridge/roof) vents.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildBenefitCard(colors, 'Extends', 'Shingle Life', LucideIcons.clock)),
              const SizedBox(width: 8),
              Expanded(child: _buildBenefitCard(colors, 'Prevents', 'Ice Dams', LucideIcons.snowflake)),
              const SizedBox(width: 8),
              Expanded(child: _buildBenefitCard(colors, 'Reduces', 'Energy Cost', LucideIcons.dollarSign)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(ZaftoColors colors, String action, String benefit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 20),
          const SizedBox(height: 8),
          Text(action, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          Text(benefit, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVentilationDiagram(ZaftoColors colors) {
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
            'Balanced Ventilation System',
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
BALANCED ATTIC VENTILATION
═══════════════════════════════════════════════════════════

                    RIDGE VENT
                   (EXHAUST 50%)
                        ▲
                       ╱│╲
    Hot air rises ──► ╱ │ ╲ ◄── Hot air rises
                     ╱  │  ╲
                    ╱ ▲ │ ▲ ╲
                   ╱  │ │ │  ╲
                  ╱   │ │ │   ╲
                 ╱    │ │ │    ╲
                ╱     │ │ │     ╲
    ═══════════╱══════╧═╧═╧══════╲═══════════
              │                   │
              │    ATTIC SPACE    │   ← Hot/moist
              │                   │     air rises
              │   ▲           ▲   │
              │   │           │   │
    ══════════│═══│═══════════│═══│══════════
              │   │           │   │
    SOFFIT ──►│ ○ │           │ ○ │◄── SOFFIT
    VENT      │   │           │   │    VENT
   (INTAKE)   └───┘           └───┘  (INTAKE)
                ▲               ▲
                │               │
           Cool outside air enters


AIRFLOW PATH:
1. Cool air enters through soffit vents (intake)
2. Air moves up through attic space
3. Hot/moist air exits through ridge vent (exhaust)
4. Continuous airflow keeps attic cool and dry


KEY RATIO: 1:150 to 1:300
• 1 sq ft NFA per 150 sq ft attic floor (standard)
• 1 sq ft NFA per 300 sq ft if balanced 50/50
• Split: 50% intake (low) / 50% exhaust (high)''',
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

  Widget _buildVentTypes(ZaftoColors colors) {
    final intakeVents = [
      {'name': 'Soffit Vent', 'nfa': '9 sq in/ft', 'desc': 'Continuous or individual vents in soffit'},
      {'name': 'Edge Vent', 'nfa': '9-12 sq in/ft', 'desc': 'At eave edge when no soffit exists'},
      {'name': 'Fascia Vent', 'nfa': 'Varies', 'desc': 'Hidden behind fascia board'},
    ];

    final exhaustVents = [
      {'name': 'Ridge Vent', 'nfa': '18 sq in/ft', 'desc': 'Continuous along ridge - best option'},
      {'name': 'Box Vent', 'nfa': '50 sq in each', 'desc': 'Static roof vents, multiple needed'},
      {'name': 'Power Vent', 'nfa': 'N/A', 'desc': 'Electric/solar fan - use cautiously'},
      {'name': 'Turbine Vent', 'nfa': '150+ sq in', 'desc': 'Wind-powered spinning vent'},
      {'name': 'Gable Vent', 'nfa': 'Varies', 'desc': 'In gable end - not for ridge vent systems'},
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
          Text(
            'Vent Types',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildVentSection(colors, 'INTAKE (Low)', intakeVents, colors.accentInfo),
          const SizedBox(height: 16),
          _buildVentSection(colors, 'EXHAUST (High)', exhaustVents, colors.accentWarning),
        ],
      ),
    );
  }

  Widget _buildVentSection(ZaftoColors colors, String title, List<Map<String, String>> vents, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(title, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const SizedBox(height: 8),
        ...vents.map((v) => _buildVentRow(colors, v, accent)),
      ],
    );
  }

  Widget _buildVentRow(ZaftoColors colors, Map<String, String> vent, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(vent['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(vent['nfa']!, style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(vent['desc']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildCalculations(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ventilation Calculation',
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
VENTILATION CALCULATION (IRC R806)
════════════════════════════════════════════════════

NFA = Net Free Area (actual open area for airflow)

FORMULA:
  Attic Floor Area ÷ 150 = Total NFA Required
  (or ÷ 300 if balanced 50/50 intake/exhaust)

EXAMPLE: 1,500 sq ft attic
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Using 1:150 ratio:
  1,500 ÷ 150 = 10 sq ft NFA total

Split 50/50:
  Intake:  5 sq ft NFA = 720 sq inches
  Exhaust: 5 sq ft NFA = 720 sq inches

Ridge Vent Needed:
  720 sq in ÷ 18 sq in/ft = 40 linear feet

Soffit Vent Needed:
  720 sq in ÷ 9 sq in/ft = 80 linear feet


CONVERSION:
  1 sq ft = 144 sq inches

ADJUSTMENT:
  If exhaust > intake, system is intake-limited
  Always match or exceed intake to exhaust''',
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

  Widget _buildBestPractices(ZaftoColors colors) {
    final practices = [
      {'do': 'Balance intake and exhaust 50/50', 'dont': 'Mix ridge vents with gable vents'},
      {'do': 'Use continuous soffit + ridge', 'dont': 'Block soffit vents with insulation'},
      {'do': 'Install baffles at each rafter bay', 'dont': 'Over-ventilate (causes problems)'},
      {'do': 'Check NFA ratings on products', 'dont': 'Mix power vents with ridge vents'},
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
              Icon(LucideIcons.checkCircle, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Best Practices',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...practices.map((p) => _buildPracticeRow(colors, p)),
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
                    'Never mix different exhaust types. Ridge vent + gable vent = short circuit airflow.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeRow(ZaftoColors colors, Map<String, String> practice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.check, color: colors.accentSuccess, size: 12),
                  const SizedBox(width: 6),
                  Expanded(child: Text(practice['do']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.x, color: colors.accentError, size: 12),
                  const SizedBox(width: 6),
                  Expanded(child: Text(practice['dont']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
