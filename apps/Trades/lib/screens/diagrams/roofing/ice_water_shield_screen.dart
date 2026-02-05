import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class IceWaterShieldScreen extends ConsumerWidget {
  const IceWaterShieldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Ice & Water Shield',
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
            _buildApplicationAreas(colors),
            const SizedBox(height: 24),
            _buildInstallationDiagram(colors),
            const SizedBox(height: 24),
            _buildCodeRequirements(colors),
            const SizedBox(height: 24),
            _buildInstallationTips(colors),
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
              Icon(LucideIcons.snowflake, color: colors.accentInfo, size: 24),
              const SizedBox(width: 12),
              Text(
                'Ice & Water Shield Overview',
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
            'Ice and water shield is a self-adhering waterproof membrane that seals around fasteners. It protects against ice dam damage and water infiltration at vulnerable roof areas.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFeatureCard(colors, 'Self-Sealing', 'Seals around nails', LucideIcons.shield)),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureCard(colors, 'Self-Adhering', 'No fasteners needed', LucideIcons.layers)),
              const SizedBox(width: 8),
              Expanded(child: _buildFeatureCard(colors, 'Waterproof', '100% barrier', LucideIcons.droplet)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(ZaftoColors colors, String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentInfo, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildApplicationAreas(ZaftoColors colors) {
    final areas = [
      {
        'area': 'Eaves (Ice Dam Zone)',
        'desc': 'From eave edge to 24" past interior wall line',
        'required': 'Code Required',
        'color': colors.accentError,
      },
      {
        'area': 'Valleys',
        'desc': 'Full length of valley, min 36" wide',
        'required': 'Code Required',
        'color': colors.accentError,
      },
      {
        'area': 'Around Penetrations',
        'desc': 'Skylights, vents, chimneys - extend 8" past',
        'required': 'Code Required',
        'color': colors.accentError,
      },
      {
        'area': 'Dormers',
        'desc': 'Sidewalls and valleys where dormers meet roof',
        'required': 'Recommended',
        'color': colors.accentWarning,
      },
      {
        'area': 'Low Slope Areas',
        'desc': 'Any area below 4:12 pitch',
        'required': 'Recommended',
        'color': colors.accentWarning,
      },
      {
        'area': 'Entire Roof',
        'desc': 'Premium protection in harsh climates',
        'required': 'Optional',
        'color': colors.accentInfo,
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
              Icon(LucideIcons.mapPin, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Application Areas',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...areas.map((a) => _buildAreaRow(colors, a)),
        ],
      ),
    );
  }

  Widget _buildAreaRow(ZaftoColors colors, Map<String, dynamic> area) {
    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area['area'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(area['desc'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (area['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(area['required'] as String, style: TextStyle(color: area['color'] as Color, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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
            'Ice Dam Zone Coverage',
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
ICE DAM PROTECTION ZONE
═══════════════════════════════════════════════════════════

              ╱╲
             ╱  ╲               ROOF PEAK
            ╱    ╲
           ╱      ╲
          ╱        ╲
         ╱          ╲
        ╱            ╲          FIELD (Underlayment)
       ╱              ╲
      ╱                ╲
     ╱                  ╲
════╱════════════════════╲═════ ← 24" MIN past interior
   ╱▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╲        wall line
  ╱▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╲
 ╱▒▒▒ ICE & WATER SHIELD ▒▒▒╲   ← Self-adhered membrane
╱▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╲
════════════════════════════════ ← DRIP EDGE (under I&W)
         │               │
         │   OVERHANG    │
         │               │
    ─────┴───────────────┴─────  FASCIA
              │
         INTERIOR WALL


VALLEY APPLICATION
═══════════════════════════════════════════════════════════

                 VALLEY
                   ╱╲
                  ╱  ╲
       ──────────╱    ╲──────────
       ▒▒▒▒▒▒▒▒▒╱      ╲▒▒▒▒▒▒▒▒▒
       ▒▒▒▒▒▒▒▒╱   36"  ╲▒▒▒▒▒▒▒▒   ← Min 36" wide
       ▒▒▒▒▒▒▒╱   MIN    ╲▒▒▒▒▒▒▒      (18" each side)
       ▒▒▒▒▒▒╱            ╲▒▒▒▒▒▒
       ▒▒▒▒▒╱              ╲▒▒▒▒▒
       ────╱────────────────╲────
          ╱                  ╲
         ╱                    ╲

Center I&W in valley, extend full length
Overlap upper pieces over lower''',
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

  Widget _buildCodeRequirements(ZaftoColors colors) {
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
              Icon(LucideIcons.fileText, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Code Requirements (IRC R905.2.7)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeItem(colors, 'Ice Dam Protection', 'Required in areas where average January temp ≤25°F, or where history of ice dams exists.'),
          _buildCodeItem(colors, 'Eave Coverage', 'From roof edge to min 24" inside the exterior wall line of building.'),
          _buildCodeItem(colors, 'Valley Coverage', 'Full length of valley, both sides covered.'),
          _buildCodeItem(colors, 'Material Standard', 'ASTM D1970 - self-adhering polymer modified bitumen sheet.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local codes may require additional coverage. Some jurisdictions require valleys AND dormers regardless of climate.',
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

  Widget _buildCodeItem(ZaftoColors colors, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationTips(ZaftoColors colors) {
    final tips = [
      {'tip': 'Install on clean, dry deck surface', 'icon': LucideIcons.check},
      {'tip': 'Apply when temp is 40°F+ for adhesion', 'icon': LucideIcons.thermometer},
      {'tip': 'Remove release film as you go', 'icon': LucideIcons.layers},
      {'tip': 'Roll with heavy roller for full adhesion', 'icon': LucideIcons.circleDot},
      {'tip': 'Overlap seams 4" minimum', 'icon': LucideIcons.alignLeft},
      {'tip': 'Extend 4" up vertical surfaces', 'icon': LucideIcons.arrowUp},
      {'tip': 'Do not leave exposed - UV degrades membrane', 'icon': LucideIcons.sun},
      {'tip': 'Use primer on dusty/old decks', 'icon': LucideIcons.droplet},
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
              Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Tips',
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
            childAspectRatio: 3.5,
            children: tips.map((t) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: colors.accentSuccess, size: 12),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t['tip'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
