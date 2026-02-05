import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class SuspensionComponentsScreen extends ConsumerWidget {
  const SuspensionComponentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Suspension Components',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFrontSuspension(colors),
            const SizedBox(height: 24),
            _buildRearSuspension(colors),
            const SizedBox(height: 24),
            _buildShocksStruts(colors),
            const SizedBox(height: 24),
            _buildAlignmentAngles(colors),
            const SizedBox(height: 24),
            _buildWearSigns(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontSuspension(ZaftoColors colors) {
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
              Icon(LucideIcons.car, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Front Suspension (MacPherson Strut)',
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
              '''MACPHERSON STRUT (Front View)

           STRUT MOUNT
              ┌───┐
              │ ○ │ ← Upper mount/bearing
              └─┬─┘
         ┌────┴────┐
         │ SPRING  │
         │ /^^^^\\  │
         │/      \\ │
         │  STRUT  │ ← Shock absorber inside
         │   │     │
         │   │     │
         │   │     │
         └───┼─────┘
    ─────────┼──────────── STEERING
    │        │            │  KNUCKLE
    │   ┌────┴────┐       │
    │   │  LOWER  │       │
    └───┤ CONTROL ├───────┘
        │  ARM    │
        └────┬────┘
             │
        ○────┴────○
          BALL JOINT

Common type: FWD vehicles''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSuspensionPart(colors, 'Strut assembly', 'Spring + shock in one unit'),
          _buildSuspensionPart(colors, 'Control arm', 'Connects knuckle to frame'),
          _buildSuspensionPart(colors, 'Ball joint', 'Pivot point, allows steering'),
          _buildSuspensionPart(colors, 'Strut mount', 'Bearing for steering rotation'),
          _buildSuspensionPart(colors, 'Sway bar link', 'Connects sway bar to strut'),
        ],
      ),
    );
  }

  Widget _buildSuspensionPart(ZaftoColors colors, String part, String function) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(part, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(function, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildRearSuspension(ZaftoColors colors) {
    final types = [
      {
        'type': 'Solid Axle',
        'diagram': '──○──────○──',
        'use': 'Trucks, SUVs',
        'pros': 'Strong, simple',
      },
      {
        'type': 'Semi-Independent',
        'diagram': '○──╲╱──○',
        'use': 'FWD cars',
        'pros': 'Compact, economical',
      },
      {
        'type': 'Independent',
        'diagram': '○    ○',
        'use': 'Performance',
        'pros': 'Best handling',
      },
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
              Icon(LucideIcons.move, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rear Suspension Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(t['use']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                      Text(t['pros']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      t['diagram']!,
                      style: TextStyle(color: colors.accentWarning, fontFamily: 'monospace', fontSize: 12),
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

  Widget _buildShocksStruts(ZaftoColors colors) {
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
              Icon(LucideIcons.arrowUpDown, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Shocks vs Struts',
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
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SHOCK', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        '• Damping only\n• Not structural\n• Easier to replace\n• Used with separate spring',
                        style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STRUT', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        '• Structural support\n• Holds spring\n• Affects alignment\n• Part of suspension',
                        style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Replace in pairs (both front or both rear). Alignment required after strut replacement.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentAngles(ZaftoColors colors) {
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
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alignment Angles',
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
              '''CAMBER (Front View)    CASTER (Side View)
   Positive  Negative      Positive
      ╱        ╲              │╲
     ╱          ╲             │ ╲
    ○            ○            │  ╲
   Tire leans   leans        Steering axis
   outward      inward       tilts back

TOE (Top View)
         TOE-IN              TOE-OUT
    ╲            ╱        ╱            ╲
     ╲   ○  ○   ╱        ╱   ○  ○   ╲
      ╲        ╱          ╲        ╱
       ╲      ╱            ╲      ╱
    Front closer         Front farther''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildAngleSpec(colors, 'Camber', '±0.5° typical', 'Tire wear inside/outside'),
          _buildAngleSpec(colors, 'Caster', '3-5° positive', 'Steering feel, return'),
          _buildAngleSpec(colors, 'Toe', '0-1/8" total', 'Tire wear, handling'),
        ],
      ),
    );
  }

  Widget _buildAngleSpec(ZaftoColors colors, String angle, String spec, String affects) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(angle, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(spec, style: TextStyle(color: colors.accentInfo, fontSize: 10), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(affects, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildWearSigns(ZaftoColors colors) {
    final signs = [
      {'part': 'Ball joint', 'symptom': 'Clunking over bumps, loose steering', 'test': 'Pry bar check, visual'},
      {'part': 'Tie rod end', 'symptom': 'Play in steering, uneven tire wear', 'test': 'Shake wheel side-to-side'},
      {'part': 'Control arm bushing', 'symptom': 'Vibration, wandering', 'test': 'Visual cracking, pry test'},
      {'part': 'Strut mount', 'symptom': 'Noise turning, bouncing', 'test': 'Visual, bearing feel'},
      {'part': 'Shock/Strut', 'symptom': 'Bouncy ride, nose dive', 'test': 'Bounce test, leak check'},
      {'part': 'Sway bar link', 'symptom': 'Clunk on bumps, body roll', 'test': 'Visual, shake test'},
    ];

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
              Icon(LucideIcons.alertCircle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wear Signs & Testing',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...signs.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['part']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['symptom']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
                Row(
                  children: [
                    Icon(LucideIcons.search, color: colors.accentInfo, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['test']!, style: TextStyle(color: colors.accentInfo, fontSize: 10))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
