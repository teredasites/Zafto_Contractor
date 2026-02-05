import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class SpaEquipmentScreen extends ConsumerWidget {
  const SpaEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Spa Equipment',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpaComponents(colors),
            const SizedBox(height: 24),
            _buildJetTypes(colors),
            const SizedBox(height: 24),
            _buildControlSystems(colors),
            const SizedBox(height: 24),
            _buildSpaVsPool(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaComponents(ZaftoColors colors) {
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
              Icon(LucideIcons.waves, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Spa System Components',
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
              '''SPA EQUIPMENT LAYOUT

┌─────────────────────────────────────┐
│            SPA SHELL                │
│  ┌─────┐              ┌─────┐      │
│  │ JET │   ○ ○ ○ ○   │ JET │      │
│  └──┬──┘   AIR JETS  └──┬──┘      │
│     │                    │          │
│     └────────┬───────────┘          │
│              │                      │
│         ┌────┴────┐    ┌────────┐  │
│         │  DRAIN  │    │SKIMMER │  │
│         └────┬────┘    └────┬───┘  │
└──────────────│──────────────│──────┘
               │              │
     ┌─────────┴──────────────┴─────┐
     │      SUCTION MANIFOLD        │
     └─────────────┬────────────────┘
                   │
           ┌───────┴───────┐
           │   JET PUMP    │ ← 2-4 HP
           └───────┬───────┘
                   │
           ┌───────┴───────┐
           │    HEATER     │
           └───────┬───────┘
                   │
           ┌───────┴───────┐
           │   BLOWER      │ ← Air injection
           └───────┬───────┘
                   │
     ┌─────────────┴────────────────┐
     │      PRESSURE MANIFOLD       │
     └─────────────┬────────────────┘
                   │
              TO JETS''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildComponentRow(colors, 'Jet Pump', '2-4 HP', 'Main water movement'),
          _buildComponentRow(colors, 'Circulation Pump', '1/8-1/4 HP', '24/7 filtration'),
          _buildComponentRow(colors, 'Blower', '1-2 HP', 'Air bubble injection'),
          _buildComponentRow(colors, 'Heater', '4-11 kW', 'Electric element'),
          _buildComponentRow(colors, 'Ozonator', 'Optional', 'Supplemental sanitation'),
        ],
      ),
    );
  }

  Widget _buildComponentRow(ZaftoColors colors, String name, String spec, String purpose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(spec, style: TextStyle(color: colors.accentPrimary, fontSize: 9), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildJetTypes(ZaftoColors colors) {
    final jets = [
      {
        'type': 'Rotary Jets',
        'action': 'Spinning massage',
        'diagram': '◎',
        'best': 'Deep tissue, back',
      },
      {
        'type': 'Directional Jets',
        'action': 'Focused stream',
        'diagram': '→',
        'best': 'Targeted therapy',
      },
      {
        'type': 'Cluster Jets',
        'action': 'Multiple streams',
        'diagram': ':::',
        'best': 'Wide coverage',
      },
      {
        'type': 'Pulsating Jets',
        'action': 'On/off rhythm',
        'diagram': '○●○',
        'best': 'Circulation, calves',
      },
      {
        'type': 'Air Jets',
        'action': 'Bubble massage',
        'diagram': '°°°',
        'best': 'Gentle relaxation',
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
              Icon(LucideIcons.target, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Jet Types & Therapy',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...jets.map((j) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(j['diagram']!, style: TextStyle(color: colors.accentInfo, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j['type']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                      Text(j['action']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(j['best']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
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
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jet pressure adjustable via air intake venturi. More air = softer massage.',
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

  Widget _buildControlSystems(ZaftoColors colors) {
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
              Icon(LucideIcons.settings, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Control Systems',
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
              '''TYPICAL SPA PACK WIRING

MAIN PANEL (50A 240V)
       │
       ▼
┌──────────────────────────────┐
│         SPA PACK             │
│  ┌─────────────────────────┐ │
│  │    CONTROL BOARD        │ │
│  │  ┌───┬───┬───┬───┬───┐  │ │
│  │  │P1 │P2 │BL │HT │OZ │  │ │
│  │  └─┬─┴─┬─┴─┬─┴─┬─┴─┬─┘  │ │
│  └────│───│───│───│───│────┘ │
│       │   │   │   │   │      │
│    ┌──┴┐┌─┴─┐┌┴─┐┌┴──┐┌┴──┐ │
│    │J1 ││J2 ││BL││HTR││OZN│ │
│    │PMP││PMP││WR││   ││   │ │
│    └───┘└───┘└──┘└───┘└───┘ │
└──────────────────────────────┘
  ↓     ↓    ↓    ↓    ↓
JET1  JET2  AIR  HEAT  OZONE

Topside Control: RS-485 or optical
Sensors: Temp (hi-limit + control)
Safety: GFCI, pressure switch, flow switch''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildControlFeature(colors, 'Topside Panel', 'User interface for temp, jets, lights'),
          _buildControlFeature(colors, 'Hi-Limit Sensor', 'Safety cutoff at 104°F+'),
          _buildControlFeature(colors, 'Flow Switch', 'Prevents heater dry-fire'),
          _buildControlFeature(colors, 'Pressure Switch', 'Verifies pump operation'),
          _buildControlFeature(colors, 'GFCI Breaker', 'Required, 50A 240V typical'),
        ],
      ),
    );
  }

  Widget _buildControlFeature(ZaftoColors colors, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(name, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaVsPool(ZaftoColors colors) {
    final differences = [
      {'aspect': 'Water Volume', 'spa': '300-500 gal', 'pool': '15,000-30,000 gal'},
      {'aspect': 'Temperature', 'spa': '100-104°F', 'pool': '78-82°F'},
      {'aspect': 'Turnover', 'spa': '15-30 min', 'pool': '6-8 hours'},
      {'aspect': 'Sanitizer', 'spa': 'Bromine preferred', 'pool': 'Chlorine preferred'},
      {'aspect': 'Chemical dose', 'spa': 'Small, frequent', 'pool': 'Larger, less often'},
      {'aspect': 'Water change', 'spa': 'Every 3-4 months', 'pool': 'Rarely'},
      {'aspect': 'Filter clean', 'spa': 'Weekly', 'pool': 'Monthly'},
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
              Icon(LucideIcons.gitCompare, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spa vs Pool Differences',
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
              Expanded(flex: 2, child: Text('Aspect', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(flex: 2, child: Text('Spa', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Pool', style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          ...differences.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(d['aspect']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                Expanded(flex: 2, child: Text(d['spa']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(flex: 2, child: Text(d['pool']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
