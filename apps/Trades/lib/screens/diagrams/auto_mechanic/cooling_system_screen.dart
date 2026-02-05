import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class CoolingSystemScreen extends ConsumerWidget {
  const CoolingSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Cooling System',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemFlow(colors),
            const SizedBox(height: 24),
            _buildComponents(colors),
            const SizedBox(height: 24),
            _buildCoolantTypes(colors),
            const SizedBox(height: 24),
            _buildThermostat(colors),
            const SizedBox(height: 24),
            _buildTroubleshooting(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemFlow(ZaftoColors colors) {
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
              Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cooling System Flow',
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
              '''COOLANT FLOW DIAGRAM

         ┌──────────────────────────────┐
         │          RADIATOR            │
         │   (hot coolant cooled by air)│
         └──────────────┬───────────────┘
                        │
                        ▼ (cool)
         ┌──────────────┴───────────────┐
         │       THERMOSTAT             │
         │   (controls flow to rad)     │
         └──────────────┬───────────────┘
      ┌─────────────────┼─────────────────┐
      │                 │                 │
      ▼                 ▼                 ▼
┌─────────┐    ┌───────────────┐   ┌──────────┐
│ HEATER  │    │    ENGINE     │   │  BYPASS  │
│  CORE   │    │  (heat added) │   │  (cold)  │
└────┬────┘    └───────┬───────┘   └────┬─────┘
     │                 │                 │
     └─────────────────┼─────────────────┘
                       │
              ┌────────▼────────┐
              │   WATER PUMP    │
              │ (circulates)    │
              └─────────────────┘

Hot coolant = to radiator (thermostat open)
Cold = bypass to engine (thermostat closed)''',
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

  Widget _buildComponents(ZaftoColors colors) {
    final components = [
      {'part': 'Radiator', 'function': 'Heat exchanger, cools hot coolant', 'check': 'Leaks, clogs, fins'},
      {'part': 'Water pump', 'function': 'Circulates coolant through system', 'check': 'Bearing, weep hole'},
      {'part': 'Thermostat', 'function': 'Controls coolant flow to radiator', 'check': 'Stuck open/closed'},
      {'part': 'Radiator cap', 'function': 'Maintains system pressure', 'check': 'Seal, pressure rating'},
      {'part': 'Overflow tank', 'function': 'Holds expanding coolant', 'check': 'Level, cracks'},
      {'part': 'Cooling fan', 'function': 'Pulls air through radiator', 'check': 'Motor, clutch, relay'},
      {'part': 'Heater core', 'function': 'Cabin heat exchanger', 'check': 'Leaks, clogs'},
      {'part': 'Hoses', 'function': 'Carries coolant between components', 'check': 'Soft, cracked, swollen'},
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
              Icon(LucideIcons.settings, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'System Components',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...components.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['part']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('Check: ${c['check']}', style: TextStyle(color: colors.accentWarning, fontSize: 9)),
                  ],
                ),
                Text(c['function']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCoolantTypes(ZaftoColors colors) {
    final coolants = [
      {'type': 'IAT (Green)', 'life': '2-3 years', 'vehicles': 'Older vehicles', 'color': Colors.green},
      {'type': 'OAT (Orange)', 'life': '5 years', 'vehicles': 'GM, VW, Audi', 'color': Colors.orange},
      {'type': 'HOAT (Yellow)', 'life': '5 years', 'vehicles': 'Ford, Chrysler', 'color': Colors.yellow},
      {'type': 'HOAT (Pink/Blue)', 'life': '5 years', 'vehicles': 'Asian vehicles', 'color': Colors.pink},
      {'type': 'Si-OAT (Purple)', 'life': '5 years', 'vehicles': 'Mercedes, others', 'color': Colors.purple},
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
              Icon(LucideIcons.droplets, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coolant Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...coolants.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(c['type'] as String, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(c['life'] as String, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(c['vehicles'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          )),
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
                    'Never mix coolant types. Use manufacturer-specified coolant only.',
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

  Widget _buildThermostat(ZaftoColors colors) {
    final temps = [
      {'temp': '160°F', 'use': 'Racing, performance'},
      {'temp': '180°F', 'use': 'Some trucks, older vehicles'},
      {'temp': '195°F', 'use': 'Most modern vehicles'},
      {'temp': '205°F', 'use': 'Late model, fuel economy'},
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
              Icon(LucideIcons.gauge, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thermostat Ratings',
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
              '''THERMOSTAT OPERATION

    COLD (Closed)         HOT (Open)
    ┌────────────┐       ┌────────────┐
    │   ▓▓▓▓▓▓   │       │            │
    │   ▓▓▓▓▓▓   │       │   ○    ○   │
    │   ══════   │ →→→→  │   │    │   │
    │  (closed)  │       │ ▼▼▼  ▼▼▼  │
    └────────────┘       └────────────┘

    Blocks flow          Allows flow
    to radiator          to radiator

Thermostat opens at rated temp
Full open: ~20°F above rated''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...temps.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t['temp']!, style: TextStyle(color: colors.accentWarning, fontSize: 10), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    final issues = [
      {'symptom': 'Overheating', 'causes': 'Low coolant, bad thermostat, fan failure, clogged rad'},
      {'symptom': 'No heat', 'causes': 'Low coolant, stuck thermostat, clogged heater core'},
      {'symptom': 'Runs cold', 'causes': 'Thermostat stuck open, bad temp sensor'},
      {'symptom': 'Coolant loss', 'causes': 'Leaks, head gasket, cracked block'},
      {'symptom': 'Oil in coolant', 'causes': 'Head gasket, oil cooler failure'},
      {'symptom': 'Bubbles in tank', 'causes': 'Head gasket, air in system'},
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
                'Common Issues',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...issues.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['symptom']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(i['causes']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
