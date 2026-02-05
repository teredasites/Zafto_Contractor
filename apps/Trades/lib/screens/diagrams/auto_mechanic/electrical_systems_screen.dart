import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ElectricalSystemsScreen extends ConsumerWidget {
  const ElectricalSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Electrical Systems',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChargingSystem(colors),
            const SizedBox(height: 24),
            _buildStartingSystem(colors),
            const SizedBox(height: 24),
            _buildBatterySpecs(colors),
            const SizedBox(height: 24),
            _buildWireGauge(colors),
            const SizedBox(height: 24),
            _buildFuseChart(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildChargingSystem(ZaftoColors colors) {
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
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Charging System',
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
              '''CHARGING SYSTEM LAYOUT

    ┌─────────────┐
    │  ALTERNATOR │
    │   ┌─────┐   │
    │   │ ROTOR│  │ ← Spins via belt
    │   │ ~~~~ │  │   Creates AC
    │   └─────┘   │
    └──────┬──────┘
           │ AC output
    ┌──────▼──────┐
    │  RECTIFIER  │ ← Converts AC to DC
    │  (diodes)   │
    └──────┬──────┘
           │ DC output
    ┌──────▼──────┐    ┌──────────┐
    │  VOLTAGE    │───→│ BATTERY  │
    │  REGULATOR  │    │  12V DC  │
    └─────────────┘    └──────────┘
                              │
                        To vehicle
                        electrical
                        system

NORMAL READINGS:
• Battery: 12.4-12.7V (resting)
• Charging: 13.8-14.5V (running)
• Below 13.5V = undercharging
• Above 15V = overcharging''',
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

  Widget _buildStartingSystem(ZaftoColors colors) {
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
              Icon(LucideIcons.power, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Starting System',
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
              '''STARTING CIRCUIT

┌──────────┐     ┌──────────────┐
│ IGNITION │────→│   NEUTRAL    │
│  SWITCH  │     │SAFETY SWITCH │
└──────────┘     └──────┬───────┘
                        │
┌──────────┐     ┌──────▼───────┐
│ BATTERY  │────→│   STARTER    │
│  (+)     │     │   SOLENOID   │
└──────────┘     └──────┬───────┘
                        │ High current
                 ┌──────▼───────┐
                 │   STARTER    │
                 │    MOTOR     │
                 └──────┬───────┘
                        │
                 ┌──────▼───────┐
                 │   FLYWHEEL   │
                 │   (engine)   │
                 └──────────────┘

STARTER DRAW:
• 4-cyl: 100-150 amps
• V6: 150-200 amps
• V8: 200-300 amps
• Diesel: 300-500 amps''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStartNote(colors, 'Clicks once', 'Bad solenoid or connections'),
          _buildStartNote(colors, 'Clicks rapidly', 'Weak battery or bad ground'),
          _buildStartNote(colors, 'No click', 'Ignition switch, safety switch'),
          _buildStartNote(colors, 'Grinds', 'Starter drive or flywheel damage'),
        ],
      ),
    );
  }

  Widget _buildStartNote(ZaftoColors colors, String symptom, String cause) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(
            '$symptom: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildBatterySpecs(ZaftoColors colors) {
    final states = [
      {'voltage': '12.6V+', 'state': '100%', 'status': 'Full charge'},
      {'voltage': '12.4V', 'state': '75%', 'status': 'Good'},
      {'voltage': '12.2V', 'state': '50%', 'status': 'Low'},
      {'voltage': '12.0V', 'state': '25%', 'status': 'Very low'},
      {'voltage': '<11.9V', 'state': '0%', 'status': 'Discharged'},
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
              Icon(LucideIcons.battery, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Battery State of Charge',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...states.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
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
                  child: Text(s['voltage']!, style: TextStyle(color: colors.accentInfo, fontSize: 11), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  child: Text(s['state']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(s['status']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            child: Text(
              'CCA (Cold Cranking Amps): Should match or exceed OEM spec. Higher is acceptable.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWireGauge(ZaftoColors colors) {
    final gauges = [
      {'awg': '18', 'amps': '10A', 'use': 'Small accessories, LEDs'},
      {'awg': '16', 'amps': '15A', 'use': 'General wiring, lights'},
      {'awg': '14', 'amps': '20A', 'use': 'Horns, fans'},
      {'awg': '12', 'amps': '25A', 'use': 'Heavy accessories'},
      {'awg': '10', 'amps': '30A', 'use': 'Fuel pumps, winches'},
      {'awg': '8', 'amps': '50A', 'use': 'High-draw accessories'},
      {'awg': '6', 'amps': '75A', 'use': 'Alternator output'},
      {'awg': '4', 'amps': '100A', 'use': 'Battery cables'},
      {'awg': '2', 'amps': '150A', 'use': 'Heavy battery cables'},
      {'awg': '0', 'amps': '200A', 'use': 'Large vehicles, diesel'},
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
              Icon(LucideIcons.plug, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wire Gauge Chart',
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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 3,
            children: gauges.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.accentWarning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(g['awg']!, style: TextStyle(color: colors.accentWarning, fontSize: 10), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 6),
                  Text(g['amps']!, style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(g['use']!, style: TextStyle(color: colors.textTertiary, fontSize: 8), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFuseChart(ZaftoColors colors) {
    final fuses = [
      {'amps': '5A', 'color': 'Tan', 'use': 'Indicators, sensors'},
      {'amps': '7.5A', 'color': 'Brown', 'use': 'Instrument cluster'},
      {'amps': '10A', 'color': 'Red', 'use': 'Small motors, lights'},
      {'amps': '15A', 'color': 'Blue', 'use': 'Accessories, wipers'},
      {'amps': '20A', 'color': 'Yellow', 'use': 'Power windows, fans'},
      {'amps': '25A', 'color': 'White', 'use': 'Heater, defroster'},
      {'amps': '30A', 'color': 'Green', 'use': 'Electric seats, AC'},
      {'amps': '40A', 'color': 'Orange', 'use': 'Ignition, fuel pump'},
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
              Icon(LucideIcons.minus, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Standard Fuse Colors',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fuses.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(f['amps']!, style: TextStyle(color: colors.accentPrimary, fontSize: 10), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(f['color']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(f['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Text(
            'Always replace with same amperage. Never upsize fuses.',
            style: TextStyle(color: colors.accentError, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
