import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class MetalRoofingScreen extends ConsumerWidget {
  const MetalRoofingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Metal Roofing',
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
            _buildPanelTypes(colors),
            const SizedBox(height: 24),
            _buildInstallationDiagram(colors),
            const SizedBox(height: 24),
            _buildFastenerTypes(colors),
            const SizedBox(height: 24),
            _buildTrimDetails(colors),
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
              Icon(LucideIcons.square, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Metal Roofing Overview',
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
            'Metal roofing offers exceptional durability, energy efficiency, and longevity. Available in various profiles from standing seam to corrugated, metal roofs can last 40-70 years with proper installation.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '40-70', 'Year Lifespan', colors.accentSuccess)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '3:12', 'Min Slope', colors.accentInfo)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(colors, '100%', 'Recyclable', colors.accentWarning)),
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
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPanelTypes(ZaftoColors colors) {
    final types = [
      {
        'name': 'Standing Seam',
        'desc': 'Vertical panels with raised interlocking seams. Hidden fasteners.',
        'pros': ['No exposed fasteners', 'Premium appearance', 'Longest life'],
        'slope': '3:12+',
        'color': colors.accentSuccess,
      },
      {
        'name': 'Exposed Fastener',
        'desc': 'Panels attached with visible screws through face. Cost-effective.',
        'pros': ['Lower cost', 'DIY-friendly', 'Easy repairs'],
        'slope': '3:12+',
        'color': colors.accentInfo,
      },
      {
        'name': 'Metal Shingles',
        'desc': 'Individual pieces mimicking slate, shake, or tile.',
        'pros': ['Traditional look', 'Lightweight', 'Wind resistant'],
        'slope': '3:12+',
        'color': colors.accentWarning,
      },
      {
        'name': 'Corrugated',
        'desc': 'Wavy profile panels. Agricultural and industrial.',
        'pros': ['Lowest cost', 'Strong', 'Easy install'],
        'slope': '3:12+',
        'color': colors.accentPrimary,
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
            'Metal Panel Types',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildPanelTypeCard(colors, t)),
        ],
      ),
    );
  }

  Widget _buildPanelTypeCard(ZaftoColors colors, Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (type['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: type['color'] as Color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(type['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentInfo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(type['slope'] as String, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(type['desc'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
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
            'Standing Seam Installation',
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
STANDING SEAM PANEL PROFILE
═══════════════════════════════════════════════════════

    ┌───┐       ┌───┐       ┌───┐       ┌───┐
    │   │       │   │       │   │       │   │
    │ S │       │ S │       │ S │       │ S │
    │ E │       │ E │       │ E │       │ E │
    │ A │       │ A │       │ A │       │ A │
    │ M │       │ M │       │ M │       │ M │
    │   │       │   │       │   │       │   │
════╧═══╧═══════╧═══╧═══════╧═══╧═══════╧═══╧════
         12-18" typical panel width


SEAM DETAIL (Cross Section)
═══════════════════════════════════════════════════════

  Snap-Lock Seam:          Mechanically Seamed:
        ┌─┐                      ╔═╗
        │ │                      ║ ║
    ┌───┘ └───┐              ╔═══╝ ╚═══╗
    │  CLIP   │              ║  CLIP   ║
════╧═════════╧════      ════╩═════════╩════
    (clicks together)    (rolled with seamer)


CLIP ATTACHMENT
═══════════════════════════════════════════════════════

         SEAM
           │
           ▼
    ╔═════════════╗
    ║             ║ ← Panel interlocks
    ║   ┌─────┐   ║    with clip
    ║   │CLIP │   ║
    ║   │     │   ║
════╩═══╧═════╧═══╩════════════════════════════
              │
              ▼
         Screw to deck
    (allows thermal movement)''',
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

  Widget _buildFastenerTypes(ZaftoColors colors) {
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
              Icon(LucideIcons.circleDot, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fastener Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFastenerRow(colors, 'Pancake Head', 'Exposed fastener panels. EPDM washer seals.', '12-24" spacing'),
          _buildFastenerRow(colors, 'Clips', 'Standing seam. Hidden, allows movement.', '12-24" O.C.'),
          _buildFastenerRow(colors, 'Stitch Screws', 'Panel-to-panel at overlaps.', 'Every 12"'),
          _buildFastenerRow(colors, 'Wood Screws', 'To wood purlins/deck.', '#10-#14'),
          _buildFastenerRow(colors, 'Self-Drilling', 'To steel purlins.', '#12-#14'),
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
                    'Exposed fastener screws need washer inspection/replacement every 10-15 years.',
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

  Widget _buildFastenerRow(ZaftoColors colors, String name, String desc, String spacing) {
    return Container(
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
            child: Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(spacing, style: TextStyle(color: colors.accentInfo, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimDetails(ZaftoColors colors) {
    final trims = [
      {'name': 'Ridge Cap', 'use': 'Covers ridge peak'},
      {'name': 'Eave Trim', 'use': 'Finishes eave edge'},
      {'name': 'Rake Trim', 'use': 'Finishes gable edge'},
      {'name': 'Valley', 'use': 'W-shaped valley lining'},
      {'name': 'Z-Flashing', 'use': 'Wall-to-roof transition'},
      {'name': 'End Wall', 'use': 'Panel to vertical wall'},
      {'name': 'Sidewall', 'use': 'Panel running along wall'},
      {'name': 'Hip Cap', 'use': 'Covers hip ridges'},
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
              Icon(LucideIcons.maximize2, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trim & Flashing',
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
            childAspectRatio: 3,
            children: trims.map((t) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.check, color: colors.accentInfo, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                        Text(t['use']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
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

  Widget _buildBestPractices(ZaftoColors colors) {
    final tips = [
      'Allow for thermal expansion (1/8" per 10ft)',
      'Use same metal for all contact points (avoid galvanic corrosion)',
      'Apply butyl tape at all laps and penetrations',
      'Pre-drill holes slightly oversized for expansion',
      'Install high-temp underlayment under metal',
      'Do not over-tighten fasteners (crushing washers)',
      'Stagger panel end laps minimum 4"',
      'Seal all cut edges with touch-up paint',
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
                'Installation Best Practices',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
