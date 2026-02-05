import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class JointTypesScreen extends ConsumerWidget {
  const JointTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Joint Types',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicJoints(colors),
            const SizedBox(height: 24),
            _buildWeldTypes(colors),
            const SizedBox(height: 24),
            _buildGroovePreps(colors),
            const SizedBox(height: 24),
            _buildWeldPositions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicJoints(ZaftoColors colors) {
    final joints = [
      {
        'name': 'Butt Joint',
        'diagram': '════╪════',
        'use': 'Edge to edge',
        'strength': 'High',
      },
      {
        'name': 'Lap Joint',
        'diagram': '════\n   ════',
        'use': 'Overlapping',
        'strength': 'Medium',
      },
      {
        'name': 'T-Joint',
        'diagram': '  │\n════',
        'use': 'Perpendicular',
        'strength': 'High',
      },
      {
        'name': 'Corner Joint',
        'diagram': '│\n└──',
        'use': 'Inside corner',
        'strength': 'Medium',
      },
      {
        'name': 'Edge Joint',
        'diagram': '═══\n═══',
        'use': 'Parallel edges',
        'strength': 'Low',
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
              Icon(LucideIcons.link, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                '5 Basic Joint Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...joints.map((j) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
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
                      Text(j['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(j['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                      Row(
                        children: [
                          Text('Strength: ', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                          Text(
                            j['strength']!,
                            style: TextStyle(
                              color: j['strength'] == 'High' ? colors.accentSuccess :
                                     j['strength'] == 'Medium' ? colors.accentWarning : colors.accentError,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      j['diagram']!,
                      style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 10),
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

  Widget _buildWeldTypes(ZaftoColors colors) {
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
              Icon(LucideIcons.layers, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weld Types',
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
              '''FILLET WELD             GROOVE WELD
    │                       │ ← Backing
    │▓                      │
    │▓▓                  ▓▓▓│▓▓▓
    │▓▓▓               ═════╪═════
════╪════

Leg size = a           Full penetration
Throat = 0.707a        or partial pen.

PLUG WELD               SPOT WELD
═══════════             ═══════════
   │ ◯ │                   (●)
═══════════             ═══════════

Through hole            No visible hole
                        (resistance weld)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildWeldNote(colors, 'Fillet', 'Most common, triangular cross-section'),
          _buildWeldNote(colors, 'Groove', 'Full or partial penetration'),
          _buildWeldNote(colors, 'Plug/Slot', 'Fills holes in overlapping joints'),
          _buildWeldNote(colors, 'Spot', 'Resistance welding, sheet metal'),
        ],
      ),
    );
  }

  Widget _buildWeldNote(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroovePreps(ZaftoColors colors) {
    final grooves = [
      {'name': 'Square', 'diagram': '│  │', 'angle': '0°', 'gap': '0-1/8"'},
      {'name': 'V-Groove', 'diagram': '╲  ╱', 'angle': '60-75°', 'gap': '0-1/8"'},
      {'name': 'Bevel', 'diagram': '│  ╱', 'angle': '30-45°', 'gap': '0-1/8"'},
      {'name': 'U-Groove', 'diagram': '╰  ╯', 'angle': '20°', 'gap': '0-1/16"'},
      {'name': 'J-Groove', 'diagram': '│  ╯', 'angle': '20°', 'gap': '0-1/16"'},
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
              Icon(LucideIcons.scissors, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Groove Preparations',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...grooves.map((g) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(g['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(g['diagram']!, style: TextStyle(color: colors.accentWarning, fontFamily: 'monospace', fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Angle: ${g['angle']}', style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                    Text('Gap: ${g['gap']}', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWeldPositions(ZaftoColors colors) {
    final positions = [
      {'code': '1G/1F', 'name': 'Flat', 'diagram': '═══', 'difficulty': 'Easy'},
      {'code': '2G/2F', 'name': 'Horizontal', 'diagram': '│══', 'difficulty': 'Medium'},
      {'code': '3G/3F', 'name': 'Vertical', 'diagram': '║', 'difficulty': 'Hard'},
      {'code': '4G/4F', 'name': 'Overhead', 'diagram': '▔▔▔', 'difficulty': 'Hardest'},
      {'code': '5G', 'name': 'Pipe Fixed', 'diagram': '◯', 'difficulty': 'Hard'},
      {'code': '6G', 'name': 'Pipe 45°', 'diagram': '◯/', 'difficulty': 'Hardest'},
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
              Icon(LucideIcons.move, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weld Positions',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'G = Groove, F = Fillet',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: positions.map((p) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p['code']!, style: TextStyle(color: colors.accentPrimary, fontSize: 9), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p['name']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(
                          p['difficulty']!,
                          style: TextStyle(
                            color: p['difficulty'] == 'Easy' ? colors.accentSuccess :
                                   p['difficulty'] == 'Medium' ? colors.accentWarning :
                                   colors.accentError,
                            fontSize: 9,
                          ),
                        ),
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
}
