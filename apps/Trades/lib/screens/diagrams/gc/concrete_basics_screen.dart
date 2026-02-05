import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ConcreteBasicsScreen extends ConsumerWidget {
  const ConcreteBasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Concrete Basics',
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
            _buildMixDesign(colors),
            const SizedBox(height: 24),
            _buildSlumpTest(colors),
            const SizedBox(height: 24),
            _buildReinforcementSection(colors),
            const SizedBox(height: 24),
            _buildCuringSection(colors),
            const SizedBox(height: 24),
            _buildVolumeCalculation(colors),
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Concrete Basics Overview',
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
            'Concrete is a mixture of cement, aggregates (sand and gravel), and water. Its strength develops over time through hydration. Proper mix design, placement, and curing are essential for durable concrete.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '3000', 'PSI Typical', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '28', 'Days Full Cure', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '4"', 'Slump Typical', colors.accentWarning)),
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
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMixDesign(ZaftoColors colors) {
    final mixes = [
      {'psi': '2500', 'use': 'Non-structural, fills', 'water': 'High'},
      {'psi': '3000', 'use': 'Footings, slabs, walls', 'water': 'Medium'},
      {'psi': '3500', 'use': 'Driveways, exterior', 'water': 'Medium'},
      {'psi': '4000', 'use': 'Structural, high load', 'water': 'Low'},
      {'psi': '4500+', 'use': 'Commercial, freeze/thaw', 'water': 'Low'},
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
              Icon(LucideIcons.flaskConical, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Concrete Mix Strengths',
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
                      Expanded(child: Text('Strength', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text('Typical Use', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('W/C Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ...mixes.map((m) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('${m['psi']} PSI', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(flex: 2, child: Text(m['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                      Expanded(child: Text(m['water']!, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
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

  Widget _buildSlumpTest(ZaftoColors colors) {
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
            'Slump Test (Workability)',
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
SLUMP TEST PROCEDURE
═══════════════════════════════════════════════════════

    1. Fill cone in         2. Remove cone       3. Measure slump
       3 layers (rod 25×)

       ╔═════╗                   │               ╔═════╗ ← Original
       ║     ║                   │               ║░░░░░║   height
       ║░░░░░║              ┌────┴────┐          ║░░░░░║
       ║░░░░░║              │ CONCRETE │          ╠═════╣ ← Slump
       ║░░░░░║              │  SLUMPS  │          ║░░░░░║   distance
       ║░░░░░║              │    ↓     │          ║░░░░░║
       ╚══╤══╝              └─────────┘          ╚══╤══╝
          │                       │                  │
    ══════╧══════          ══════╧══════      ══════╧══════


SLUMP GUIDELINES:
═══════════════════════════════════════════════════════

Slump      Workability      Typical Application
──────────────────────────────────────────────────────
1-2"       Stiff            Pavements, mass pours
3-4"       Medium           Footings, slabs, walls
5-6"       Wet              Pumped concrete
7"+        Very wet         Only with superplasticizer

Note: Higher slump = weaker concrete (more water)
      Add water only if specified (admix preferred)''',
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

  Widget _buildReinforcementSection(ZaftoColors colors) {
    final rebar = [
      {'size': '#3', 'diameter': '3/8"', 'area': '0.11 sq in'},
      {'size': '#4', 'diameter': '1/2"', 'area': '0.20 sq in'},
      {'size': '#5', 'diameter': '5/8"', 'area': '0.31 sq in'},
      {'size': '#6', 'diameter': '3/4"', 'area': '0.44 sq in'},
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
              Icon(LucideIcons.layoutGrid, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reinforcement',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Common Rebar Sizes:', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: rebar.map((r) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(r['size']!, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(r['diameter']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    Text(r['area']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Welded Wire Mesh (WWM):', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildMeshInfo(colors, '6×6 W1.4×W1.4', 'Light duty slabs, patios'),
          _buildMeshInfo(colors, '6×6 W2.9×W2.9', 'Standard residential slabs'),
          _buildMeshInfo(colors, '4×4 W4×W4', 'Heavy duty applications'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maintain 3" cover (bottom) and 1.5" (sides) for rebar in slabs.',
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

  Widget _buildMeshInfo(ZaftoColors colors, String mesh, String use) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text(mesh, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(width: 8),
          Text('- $use', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCuringSection(ZaftoColors colors) {
    final curing = [
      {'day': '1', 'strength': '16%'},
      {'day': '3', 'strength': '40%'},
      {'day': '7', 'strength': '65%'},
      {'day': '14', 'strength': '90%'},
      {'day': '28', 'strength': '100%'},
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
              Icon(LucideIcons.clock, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Curing & Strength Gain',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: curing.map((c) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Day ${c['day']}', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                    const SizedBox(height: 4),
                    Text(c['strength']!, style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Curing Methods:', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildCuringMethod(colors, 'Water curing', 'Ponding, wet burlap, sprinklers'),
          _buildCuringMethod(colors, 'Membrane curing', 'Spray-on compound seals moisture'),
          _buildCuringMethod(colors, 'Sheet curing', 'Plastic sheeting retains moisture'),
          const SizedBox(height: 12),
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
                    'Never pour concrete below 40°F or above 90°F without special precautions.',
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

  Widget _buildCuringMethod(ZaftoColors colors, String method, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text('$method: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildVolumeCalculation(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Volume Calculation',
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
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
CUBIC YARD CALCULATION
═══════════════════════════════════════════════════

Formula:
  Cubic Yards = (L × W × D) ÷ 27

Where:
  L = Length (feet)
  W = Width (feet)
  D = Depth (feet)
  27 = cubic feet per yard

Example: 20' × 10' slab, 4" thick
  D = 4" ÷ 12 = 0.333 feet
  Volume = 20 × 10 × 0.333 ÷ 27
         = 66.6 ÷ 27
         = 2.47 cubic yards

Add 5-10% for waste and over-excavation

Quick Reference (4" slab):
  100 sq ft = 1.24 yards
  200 sq ft = 2.47 yards
  500 sq ft = 6.17 yards''',
              style: TextStyle(
                color: colors.accentPrimary,
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
