import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class IrrigationSystemsScreen extends ConsumerWidget {
  const IrrigationSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Irrigation Systems',
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
            _buildSprinklerTypes(colors),
            const SizedBox(height: 24),
            _buildZoneDesign(colors),
            const SizedBox(height: 24),
            _buildPipeSizing(colors),
            const SizedBox(height: 24),
            _buildControllerSetup(colors),
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
              Icon(LucideIcons.droplets, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Irrigation System Layout',
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
              '''BASIC IRRIGATION SYSTEM

    WATER METER         BACKFLOW
        │                PREVENTER
        ▼                   │
    ┌───────┐           ┌───┴───┐
    │ MAIN  │──────────→│ BFP   │
    │ VALVE │           └───┬───┘
    └───────┘               │
                            ▼
                    ┌───────────────┐
                    │  CONTROLLER   │
                    │  (Timer/Smart)│
                    └───────┬───────┘
                            │
        ┌───────────┬───────┼───────┬───────┐
        ▼           ▼       ▼       ▼       ▼
    ┌───────┐  ┌───────┐ ┌─────┐ ┌─────┐ ┌─────┐
    │Zone 1 │  │Zone 2 │ │ Z3  │ │ Z4  │ │ Z5  │
    │ Lawn  │  │ Beds  │ │Drip │ │Back │ │Side │
    └───────┘  └───────┘ └─────┘ └─────┘ └─────┘
       ↑           ↑
    Rotors     Spray heads

Each zone has valve + heads/emitters''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildComponentNote(colors, 'Backflow preventer', 'Required by code, prevents contamination'),
          _buildComponentNote(colors, 'Zone valve', 'Electric solenoid, 24VAC'),
          _buildComponentNote(colors, 'Controller', 'Programs zones, rain sensor compatible'),
        ],
      ),
    );
  }

  Widget _buildComponentNote(ZaftoColors colors, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSprinklerTypes(ZaftoColors colors) {
    final types = [
      {
        'type': 'Pop-up Spray',
        'radius': '4-15 ft',
        'gpm': '0.5-4',
        'use': 'Small lawns, narrow areas',
        'pattern': '●→',
      },
      {
        'type': 'Rotor',
        'radius': '15-50 ft',
        'gpm': '2-8',
        'use': 'Large lawns',
        'pattern': '●→→→',
      },
      {
        'type': 'Drip Emitter',
        'radius': '1-2 ft',
        'gpm': '0.5-2 GPH',
        'use': 'Beds, trees, shrubs',
        'pattern': '○',
      },
      {
        'type': 'Micro Spray',
        'radius': '3-6 ft',
        'gpm': '5-30 GPH',
        'use': 'Ground cover, beds',
        'pattern': '◐',
      },
      {
        'type': 'Bubbler',
        'radius': '1-3 ft',
        'gpm': '0.25-2',
        'use': 'Tree wells, planters',
        'pattern': '◎',
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
              Icon(LucideIcons.sprout, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sprinkler Types',
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  t['pattern']!,
                  style: TextStyle(color: colors.accentPrimary, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['type']!,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        t['use']!,
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t['radius']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                    Text('${t['gpm']} GPM', style: TextStyle(color: colors.accentWarning, fontSize: 9)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildZoneDesign(ZaftoColors colors) {
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
              Icon(LucideIcons.layoutGrid, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Zone Design Principles',
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
              '''HEAD-TO-HEAD COVERAGE

    ●─────────────────●
    │╲               ╱│
    │ ╲             ╱ │
    │  ╲           ╱  │
    │   ╲    ●    ╱   │
    │   ╱         ╲   │
    │  ╱           ╲  │
    │ ╱             ╲ │
    │╱               ╲│
    ●─────────────────●

Spray reaches adjacent head
for uniform coverage

MATCHED PRECIPITATION RATE
Same nozzle types per zone:
• All rotors OR all sprays
• Same GPM per sq ft
• Prevents dry/wet spots''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildZoneRule(colors, 'Group by water needs', 'Lawn, shrubs, drip separate'),
          _buildZoneRule(colors, 'Group by sun exposure', 'Shade vs full sun zones'),
          _buildZoneRule(colors, 'Match head types', 'Same precipitation rate'),
          _buildZoneRule(colors, 'Stay within GPM budget', 'Don\'t exceed supply flow'),
          _buildZoneRule(colors, 'Avoid mixed slopes', 'Flat areas separate from hills'),
        ],
      ),
    );
  }

  Widget _buildZoneRule(ZaftoColors colors, String rule, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(detail, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizing(ZaftoColors colors) {
    final pipes = [
      {'size': '3/4"', 'gpm': '8-10', 'use': 'Laterals, small zones'},
      {'size': '1"', 'gpm': '13-17', 'use': 'Main line, medium zones'},
      {'size': '1-1/4"', 'gpm': '22-27', 'use': 'Main line, large systems'},
      {'size': '1-1/2"', 'gpm': '35-40', 'use': 'Commercial, large properties'},
      {'size': '2"', 'gpm': '55-65', 'use': 'Commercial main lines'},
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
              Icon(LucideIcons.pipette, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pipe Sizing',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pipes.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p['size']!, style: TextStyle(color: colors.accentWarning, fontSize: 11), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  child: Text('${p['gpm']} GPM', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
                ),
                Expanded(
                  child: Text(p['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calculator, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rule: Keep velocity under 5 ft/sec to prevent water hammer and wear.',
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

  Widget _buildControllerSetup(ZaftoColors colors) {
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
              Icon(LucideIcons.settings, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Controller Programming',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleItem(colors, 'Lawn (spray)', '2x/week', '15-20 min', 'Early AM'),
          _buildScheduleItem(colors, 'Lawn (rotor)', '2x/week', '30-45 min', 'Early AM'),
          _buildScheduleItem(colors, 'Shrub beds', '2x/week', '20-30 min', 'Early AM'),
          _buildScheduleItem(colors, 'Drip zones', '3x/week', '45-60 min', 'Any time'),
          _buildScheduleItem(colors, 'New plantings', 'Daily', '10-15 min', '2 weeks'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Practices:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  '• Water 4-6 AM (lowest evaporation, wind)\n• Deep, infrequent watering promotes roots\n• Use rain sensor to skip wet days\n• Seasonal adjust: 50% spring/fall, 100% summer',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(ZaftoColors colors, String zone, String freq, String duration, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(zone, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
          ),
          Container(
            width: 55,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(freq, style: TextStyle(color: colors.accentInfo, fontSize: 9), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          Container(
            width: 55,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(duration, style: TextStyle(color: colors.accentWarning, fontSize: 9), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(time, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
