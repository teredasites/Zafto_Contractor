import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class LandscapeLightingScreen extends ConsumerWidget {
  const LandscapeLightingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Landscape Lighting',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(colors),
            const SizedBox(height: 24),
            _buildLightingTechniques(colors),
            const SizedBox(height: 24),
            _buildFixtureTypes(colors),
            const SizedBox(height: 24),
            _buildWiringSizing(colors),
            const SizedBox(height: 24),
            _buildInstallationTips(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview(ZaftoColors colors) {
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
              Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Low Voltage System',
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
              '''LOW VOLTAGE LANDSCAPE LIGHTING

    ┌─────────────┐
    │   120V AC   │ ← House power
    │   OUTLET    │   (GFCI protected)
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │ TRANSFORMER │ ← Steps down to 12V
    │  12V AC     │   (sized for total watts)
    │  300-600W   │
    └──────┬──────┘
           │
    ═══════╪═════════════════════════
           │         Main cable
    ┌──────┼───────┬───────┬───────┐
    │      │       │       │       │
    ◐      ◐       ◐       ◐       ◐
   Path   Up     Spot   Wash   Down
  light  light  light  light  light

Wire buried 6" minimum
Direct burial cable required''',
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
                Icon(LucideIcons.zap, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '12V systems are safe for DIY. No electrician needed for low voltage.',
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

  Widget _buildLightingTechniques(ZaftoColors colors) {
    final techniques = [
      {
        'name': 'Uplighting',
        'diagram': '  ○\n  │\n  ◐',
        'use': 'Trees, architecture',
        'effect': 'Drama, height',
      },
      {
        'name': 'Downlighting',
        'diagram': '  ◐\n  │\n  ○',
        'use': 'Patios, pathways',
        'effect': 'Moonlight effect',
      },
      {
        'name': 'Path Lighting',
        'diagram': '◐──○──◐',
        'use': 'Walkways, drives',
        'effect': 'Safety, guidance',
      },
      {
        'name': 'Silhouette',
        'diagram': '█ ◐',
        'use': 'Feature plants',
        'effect': 'Dramatic outline',
      },
      {
        'name': 'Wall Wash',
        'diagram': '||||\n◐',
        'use': 'Fences, walls',
        'effect': 'Texture, depth',
      },
      {
        'name': 'Spotlighting',
        'diagram': '  ★\n ╱\n◐',
        'use': 'Focal points',
        'effect': 'Highlight feature',
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
              Icon(LucideIcons.sparkles, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lighting Techniques',
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
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: techniques.map((t) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        t['diagram']!,
                        style: TextStyle(color: colors.accentWarning, fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 9)),
                  Text(t['effect']!, style: TextStyle(color: colors.accentInfo, fontSize: 9)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureTypes(ZaftoColors colors) {
    final fixtures = [
      {'type': 'Path light', 'height': '18-24"', 'spacing': '8-10 ft', 'watts': '2-4W LED'},
      {'type': 'Spot/Bullet', 'height': 'Ground', 'spacing': 'As needed', 'watts': '4-8W LED'},
      {'type': 'Well light', 'height': 'Flush', 'spacing': 'As needed', 'watts': '6-10W LED'},
      {'type': 'Wall sconce', 'height': '66" AFF', 'spacing': '8-10 ft', 'watts': '4-6W LED'},
      {'type': 'Step light', 'height': 'In riser', 'spacing': 'Each step', 'watts': '1-2W LED'},
      {'type': 'Deck light', 'height': 'Post cap', 'spacing': 'Each post', 'watts': '1-3W LED'},
    ];

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
              Icon(LucideIcons.lamp, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fixture Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fixtures.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(f['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 50,
                  child: Text(f['height']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                SizedBox(
                  width: 60,
                  child: Text(f['spacing']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                Expanded(
                  child: Text(f['watts']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWiringSizing(ZaftoColors colors) {
    final wiring = [
      {'gauge': '16 AWG', 'maxLoad': '150W', 'maxRun': '100 ft', 'use': 'Short runs, few fixtures'},
      {'gauge': '14 AWG', 'maxLoad': '200W', 'maxRun': '150 ft', 'use': 'Medium systems'},
      {'gauge': '12 AWG', 'maxLoad': '300W', 'maxRun': '200 ft', 'use': 'Longer runs'},
      {'gauge': '10 AWG', 'maxLoad': '400W', 'maxRun': '250 ft', 'use': 'Main trunk lines'},
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
              Icon(LucideIcons.plug, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wire Sizing',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...wiring.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(w['gauge']!, style: TextStyle(color: colors.accentInfo, fontSize: 10), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 45,
                  child: Text(w['maxLoad']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                SizedBox(
                  width: 50,
                  child: Text(w['maxRun']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Expanded(
                  child: Text(w['use']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voltage Drop Rule:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  'Keep voltage drop under 10% (1.2V on 12V system). Use larger wire for longer runs. Check voltage at furthest fixture.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationTips(ZaftoColors colors) {
    final tips = [
      {'tip': 'Transformer sizing', 'detail': 'Total watts × 1.25 = minimum VA rating'},
      {'tip': 'Wire connections', 'detail': 'Use waterproof connectors (not wire nuts)'},
      {'tip': 'Burial depth', 'detail': '6" minimum, under mulch OK'},
      {'tip': 'Hub method', 'detail': 'Radial runs from transformer reduce voltage drop'},
      {'tip': 'Timer/photocell', 'detail': 'Combine both for best efficiency'},
      {'tip': 'LED advantage', 'detail': '80% less power, 50,000+ hour life'},
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
              Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 20),
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
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${t['tip']}: ',
                          style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: t['detail'],
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ],
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
}
