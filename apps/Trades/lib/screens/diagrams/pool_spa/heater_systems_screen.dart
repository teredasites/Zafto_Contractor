import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class HeaterSystemsScreen extends ConsumerWidget {
  const HeaterSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Heater Systems',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaterTypes(colors),
            const SizedBox(height: 24),
            _buildGasHeaterDiagram(colors),
            const SizedBox(height: 24),
            _buildHeatPumpDiagram(colors),
            const SizedBox(height: 24),
            _buildSizingGuide(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaterTypes(ZaftoColors colors) {
    final heaters = [
      {
        'type': 'Gas Heater',
        'fuel': 'Natural gas / Propane',
        'efficiency': '80-95%',
        'heating': 'Fastest',
        'cost': '\$1,500-4,000',
        'best': 'Occasional use, cold climates',
      },
      {
        'type': 'Heat Pump',
        'fuel': 'Electricity (air heat)',
        'efficiency': '300-600% COP',
        'heating': 'Slower',
        'cost': '\$3,000-6,000',
        'best': 'Regular use, mild climates',
      },
      {
        'type': 'Electric Resistance',
        'fuel': 'Electricity',
        'efficiency': '100%',
        'heating': 'Slow',
        'cost': '\$1,500-3,000',
        'best': 'Small spas only',
      },
      {
        'type': 'Solar',
        'fuel': 'Sun (free)',
        'efficiency': 'N/A',
        'heating': 'Slowest',
        'cost': '\$3,000-8,000',
        'best': 'Sunny climates, low operating cost',
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
              Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Heater Comparison',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...heaters.map((h) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
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
                    Text(h['type']!, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentSuccess.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(h['cost']!, style: TextStyle(color: colors.accentSuccess, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaterStat(colors, 'Fuel', h['fuel']!),
                    const SizedBox(width: 16),
                    _buildHeaterStat(colors, 'Efficiency', h['efficiency']!),
                    const SizedBox(width: 16),
                    _buildHeaterStat(colors, 'Speed', h['heating']!),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Best for: ${h['best']}', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeaterStat(ZaftoColors colors, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
          Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGasHeaterDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.flame, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gas Heater Operation',
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''GAS HEATER CROSS-SECTION

    EXHAUST ↑
    ════════════════════════
    │      HEAT          │
    │    EXCHANGER       │ ← Copper tubes
    │  ┌──────────────┐  │
    │  │ ~~~~~~~~~~~~ │  │ ← Water flows
    │  │ ~~~~~~~~~~~~ │  │   through tubes
    │  │ ~~~~~~~~~~~~ │  │
    │  └──────────────┘  │
    │                    │
    │   🔥 🔥 🔥 🔥 🔥    │ ← Burner tray
    │                    │
    ════════════════════════
         ↑ GAS IN

WATER IN →    ← WATER OUT
(from filter)   (to pool)

BTU Output / 10 = °F rise per hour
(for each 10,000 gallons)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildHeaterNote(colors, 'Gas Type', 'Natural: 1000 BTU/cu ft | Propane: 2500 BTU/cu ft'),
          _buildHeaterNote(colors, 'Clearances', 'Check local codes (typically 2-4 ft from structure)'),
          _buildHeaterNote(colors, 'Venting', 'Proper draft hood, never enclose'),
        ],
      ),
    );
  }

  Widget _buildHeaterNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatPumpDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.wind, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Heat Pump Operation',
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''HEAT PUMP REFRIGERATION CYCLE

      WARM AIR IN →     ← COLD AIR OUT
    ╔═══════════════════════════════╗
    ║    ┌───────────────────┐     ║
    ║    │   EVAPORATOR      │     ║
    ║    │   (absorbs heat   │     ║
    ║    │    from air)      │     ║
    ║    └─────────┬─────────┘     ║
    ║              │ Low pressure  ║
    ║              │ cold gas      ║
    ║         ┌────┴────┐          ║
    ║         │COMPRESSOR│         ║
    ║         │  (motor) │         ║
    ║         └────┬────┘          ║
    ║              │ High pressure ║
    ║              │ hot gas       ║
    ║    ┌─────────┴─────────┐     ║
    ║    │    CONDENSER      │     ║
    ║    │  (titanium heat   │     ║
    ║    │    exchanger)     │     ║
    ║    └───────────────────┘     ║
    ╚═══════════════════════════════╝
    WATER IN →         ← WATER OUT
                 (heated)

COP (Coefficient of Performance)
= Heat Output / Electrical Input
Typical: 5.0-6.0 (500-600% efficient)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
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
                Icon(LucideIcons.thermometerSnowflake, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Heat pumps work best when air temp > 50°F. Efficiency drops significantly in cold weather.',
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

  Widget _buildSizingGuide(ZaftoColors colors) {
    final sizing = [
      {'pool': '10,000 gal', 'gas': '200,000 BTU', 'heatPump': '85,000 BTU'},
      {'pool': '15,000 gal', 'gas': '250,000 BTU', 'heatPump': '100,000 BTU'},
      {'pool': '20,000 gal', 'gas': '300,000 BTU', 'heatPump': '120,000 BTU'},
      {'pool': '25,000 gal', 'gas': '400,000 BTU', 'heatPump': '140,000 BTU'},
      {'pool': '30,000 gal', 'gas': '400,000 BTU', 'heatPump': '140,000 BTU'},
      {'pool': 'Spa (500 gal)', 'gas': '125,000 BTU', 'heatPump': '50,000 BTU'},
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
              Icon(LucideIcons.calculator, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Heater Sizing Guide',
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
            'Based on 10°F rise in reasonable time',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 2, child: Text('Pool Size', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(flex: 2, child: Text('Gas', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Heat Pump', style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          ...sizing.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(s['pool']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                Expanded(flex: 2, child: Text(s['gas']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(flex: 2, child: Text(s['heatPump']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
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
              'Formula: BTU = Pool Gallons × 8.34 × Temp Rise ÷ Hours\nExample: 20,000 gal × 8.34 × 10°F ÷ 8 hr = 208,500 BTU',
              style: TextStyle(color: colors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
