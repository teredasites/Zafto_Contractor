import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class FlatRoofingScreen extends ConsumerWidget {
  const FlatRoofingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Flat Roofing Systems',
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
            _buildMembraneTypes(colors),
            const SizedBox(height: 24),
            _buildInstallationDiagram(colors),
            const SizedBox(height: 24),
            _buildDrainageSection(colors),
            const SizedBox(height: 24),
            _buildRepairMethods(colors),
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Flat Roofing Overview',
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
            'Low-slope roofing requires continuous waterproof membrane systems. Common types include TPO, EPDM, PVC, and modified bitumen. Minimum slope is 1/4" per foot for drainage.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '1/4":12"', 'Min Slope', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '15-30', 'Year Life', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, 'ASTM', 'Standards', colors.accentWarning)),
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
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMembraneTypes(ZaftoColors colors) {
    final types = [
      {
        'name': 'TPO',
        'full': 'Thermoplastic Polyolefin',
        'life': '15-25 years',
        'seam': 'Heat welded',
        'color': 'White (reflective)',
        'pros': ['Energy efficient', 'Chemical resistant', 'Cost effective'],
        'accent': colors.accentSuccess,
      },
      {
        'name': 'EPDM',
        'full': 'Ethylene Propylene Diene Monomer',
        'life': '20-30 years',
        'seam': 'Adhesive/tape',
        'color': 'Black or white',
        'pros': ['Durable', 'UV resistant', 'Easy repair'],
        'accent': colors.accentInfo,
      },
      {
        'name': 'PVC',
        'full': 'Polyvinyl Chloride',
        'life': '20-30 years',
        'seam': 'Heat welded',
        'color': 'White/gray',
        'pros': ['Fire resistant', 'Chemical resistant', 'Strongest seams'],
        'accent': colors.accentWarning,
      },
      {
        'name': 'Mod-Bit',
        'full': 'Modified Bitumen',
        'life': '15-20 years',
        'seam': 'Torch/cold adhesive',
        'color': 'Black/mineral cap',
        'pros': ['Multi-layer protection', 'Self-healing', 'Traditional'],
        'accent': colors.accentPrimary,
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
          Text(
            'Membrane Types',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildMembraneCard(colors, t)),
        ],
      ),
    );
  }

  Widget _buildMembraneCard(ZaftoColors colors, Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (type['accent'] as Color).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: type['accent'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type['name'] as String, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(type['full'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSpecChip(colors, 'Life: ${type['life']}'),
              const SizedBox(width: 6),
              _buildSpecChip(colors, type['seam'] as String),
              const SizedBox(width: 6),
              _buildSpecChip(colors, type['color'] as String),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: (type['pros'] as List<String>).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p, style: TextStyle(color: colors.accentSuccess, fontSize: 9)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(ZaftoColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 9)),
    );
  }

  Widget _buildInstallationDiagram(ZaftoColors colors) {
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
            'Flat Roof Assembly',
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
SINGLE-PLY MEMBRANE ASSEMBLY (TPO/EPDM/PVC)
════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────┐
│             MEMBRANE (TPO/EPDM/PVC)                 │ ← 45-90 mil
│  ═══════════════════════════════════════════════   │
│             Fully adhered, mechanically             │
│             attached, or ballasted                  │
├─────────────────────────────────────────────────────┤
│             COVER BOARD (Optional)                  │ ← 1/4"-1/2"
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │   Gypsum/HD ISO
├─────────────────────────────────────────────────────┤
│             INSULATION (ISO/EPS/XPS)                │ ← R-value varies
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │   Tapered for slope
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
├─────────────────────────────────────────────────────┤
│             VAPOR BARRIER                           │ ← 6 mil poly
│  ─────────────────────────────────────────────────  │   or peel & stick
├─────────────────────────────────────────────────────┤
│             ROOF DECK                               │ ← Steel/Concrete
│  ══════════════════════════════════════════════════ │   /Wood/Gypsum
└─────────────────────────────────────────────────────┘


PARAPET DETAIL
════════════════════════════════════════════════════════

        ┌──────────┐
        │  CAP     │ ← Metal coping or membrane cap
        │  METAL   │
        ├──────────┤
        │          │
    ────┤ PARAPET  │
    MEM │  WALL    │ ← Membrane terminates min 8"
    ────┤          │   above roof surface
        │          │
════════╧══════════╧═══════════════════════════
        ROOF MEMBRANE → (base flashing up wall)''',
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

  Widget _buildDrainageSection(ZaftoColors colors) {
    final drainTypes = [
      {'name': 'Interior Drains', 'desc': 'Through deck to interior pipes. Best for large roofs.', 'icon': LucideIcons.circleDot},
      {'name': 'Scuppers', 'desc': 'Openings through parapet walls. Simple, easy to maintain.', 'icon': LucideIcons.square},
      {'name': 'Gutters', 'desc': 'At roof edge. For roofs without parapets.', 'icon': LucideIcons.alignLeft},
      {'name': 'Crickets', 'desc': 'Tapered diverts around obstructions.', 'icon': LucideIcons.mountain},
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
              Icon(LucideIcons.droplet, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Drainage Systems',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...drainTypes.map((d) => _buildDrainRow(colors, d)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Drainage Rules:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Minimum 1/4" per foot slope to drains\n• Maximum 48 hours ponding allowed\n• Overflow/secondary drainage required\n• Keep drains clear of debris',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrainRow(ZaftoColors colors, Map<String, dynamic> drain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(drain['icon'] as IconData, color: colors.accentInfo, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drain['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(drain['desc'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairMethods(ZaftoColors colors) {
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
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Repair Methods',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRepairMethod(colors, 'TPO/PVC', 'Heat weld patch of same material. Clean area, apply patch min 2" beyond damage.'),
          _buildRepairMethod(colors, 'EPDM', 'Clean with EPDM cleaner, apply seam tape or fully adhered patch.'),
          _buildRepairMethod(colors, 'Mod-Bit', 'Torch or cold-adhesive patch. Must be same type as original.'),
          _buildRepairMethod(colors, 'Seam Failure', 'Re-weld or re-apply tape. Cover with 6" strip of same material.'),
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
                    'Never use incompatible materials. TPO and EPDM have different chemistries and cannot be heat-welded together.',
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

  Widget _buildRepairMethod(ZaftoColors colors, String material, String method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(material, style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          Expanded(child: Text(method, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }
}
