import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class TireSpecsScreen extends ConsumerWidget {
  const TireSpecsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Tire Specifications',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTireSizeDecoder(colors),
            const SizedBox(height: 24),
            _buildLoadSpeedRatings(colors),
            const SizedBox(height: 24),
            _buildTreadWear(colors),
            const SizedBox(height: 24),
            _buildTirePressure(colors),
            const SizedBox(height: 24),
            _buildRotationPatterns(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTireSizeDecoder(ZaftoColors colors) {
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
              Icon(LucideIcons.circle, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tire Size Decoder',
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
              '''TIRE SIZE FORMAT

      P 225 / 65 R 17  95  H
      │  │    │  │  │   │   │
      │  │    │  │  │   │   └── Speed Rating
      │  │    │  │  │   └────── Load Index
      │  │    │  │  └────────── Rim Diameter (inches)
      │  │    │  └───────────── Construction (R=Radial)
      │  │    └──────────────── Aspect Ratio (% of width)
      │  └───────────────────── Width (mm)
      └──────────────────────── Type (P=Passenger)

EXAMPLE: P225/65R17 95H
• 225mm wide
• Sidewall = 65% of 225 = 146mm
• Fits 17" rim
• Radial construction
• Supports 1521 lbs (load index 95)
• Max 130 mph (speed rating H)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadSpeedRatings(ZaftoColors colors) {
    final speeds = [
      {'rating': 'S', 'mph': '112', 'use': 'Family sedans'},
      {'rating': 'T', 'mph': '118', 'use': 'Family sedans, minivans'},
      {'rating': 'H', 'mph': '130', 'use': 'Sport sedans'},
      {'rating': 'V', 'mph': '149', 'use': 'Sports cars'},
      {'rating': 'W', 'mph': '168', 'use': 'High-performance'},
      {'rating': 'Y', 'mph': '186', 'use': 'Exotic sports cars'},
    ];

    final loads = [
      {'index': '91', 'lbs': '1356'},
      {'index': '95', 'lbs': '1521'},
      {'index': '100', 'lbs': '1764'},
      {'index': '105', 'lbs': '2039'},
      {'index': '110', 'lbs': '2337'},
      {'index': '115', 'lbs': '2679'},
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
              Icon(LucideIcons.gauge, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Load & Speed Ratings',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed Rating', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...speeds.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentInfo.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s['rating']!, style: TextStyle(color: colors.accentInfo, fontSize: 10), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 6),
                          Text('${s['mph']} mph', style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Load Index', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...loads.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentWarning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(l['index']!, style: TextStyle(color: colors.accentWarning, fontSize: 10), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 6),
                          Text('${l['lbs']} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreadWear(ZaftoColors colors) {
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
              Icon(LucideIcons.ruler, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tread Wear Patterns',
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
              '''WEAR PATTERNS & CAUSES

CENTER WEAR         EDGE WEAR          ONE-SIDE WEAR
  ____               ____               ____
 │▓▓▓▓│             │▓  ▓│             │▓   │
 │▓▓▓▓│             │▓  ▓│             │▓   │
 │▓▓▓▓│             │▓  ▓│             │▓   │
 └────┘             └────┘             └────┘
Overinflation      Underinflation      Camber issue

CUPPING/SCALLOPING  FEATHERING         DIAGONAL WEAR
  ____               ____               ____
 │▓ ▓ │             │╱╱╱╱│             │▓ ▓ │
 │ ▓ ▓│             │╱╱╱╱│             │ ▓ ▓│
 │▓ ▓ │             │╱╱╱╱│             │▓ ▓ │
 └────┘             └────┘             └────┘
Worn shocks/struts  Toe misalignment    Multiple issues''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildWearNote(colors, 'Minimum tread', '2/32" (penny test - Lincoln\'s head visible)'),
          _buildWearNote(colors, 'Safe tread', '4/32" for rain, 6/32" for snow'),
          _buildWearNote(colors, 'Wear indicators', 'Bars across tread at 2/32"'),
        ],
      ),
    );
  }

  Widget _buildWearNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildTirePressure(ZaftoColors colors) {
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
              Icon(LucideIcons.gauge, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tire Pressure',
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
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where to Find Specs:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '• Driver door jamb placard\n• Fuel door\n• Owner\'s manual\n• NOT the tire sidewall (max pressure)',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPressureNote(colors, 'Check when', 'Cold (driven <1 mile)'),
          _buildPressureNote(colors, 'Typical range', '30-35 PSI (passenger cars)'),
          _buildPressureNote(colors, 'Temp change', '±1 PSI per 10°F'),
          _buildPressureNote(colors, 'TPMS light', 'Triggers at 25% below placard'),
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
                    'Underinflation causes 3x more tire failures than overinflation.',
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

  Widget _buildPressureNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationPatterns(ZaftoColors colors) {
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
              Icon(LucideIcons.refreshCw, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rotation Patterns',
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
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''ROTATION PATTERNS

FWD/REARWARD CROSS     RWD/4WD REARWARD CROSS
    ○───────○               ○───────○
    │╲     ╱│               │       │
    │ ╲   ╱ │               │   ╳   │
    │  ╲ ╱  │               │       │
    ○───────○               ○───────○
  Front tires cross       Rear tires cross
  to rear straight        to front straight

X-PATTERN (All)        FRONT-TO-BACK (Dir.)
    ○───────○               ○       ○
    │╲     ╱│               │       │
    │  ╳   │               │       │
    │╱     ╲│               │       │
    ○───────○               ○       ○
  All tires cross        Same side, no cross

Rotate every 5,000-7,500 miles''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Directional tires: Front-to-back only, same side',
            style: TextStyle(color: colors.accentWarning, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
