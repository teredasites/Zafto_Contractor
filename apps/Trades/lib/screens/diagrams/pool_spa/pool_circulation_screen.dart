import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PoolCirculationScreen extends ConsumerWidget {
  const PoolCirculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Pool Circulation',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCirculationDiagram(colors),
            const SizedBox(height: 24),
            _buildPlumbingComponents(colors),
            const SizedBox(height: 24),
            _buildFlowRates(colors),
            const SizedBox(height: 24),
            _buildPipeSizing(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCirculationDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.refreshCw, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Circulation System',
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
              '''POOL CIRCULATION FLOW

┌─────────────────────────────────────┐
│           POOL WATER                │
│  ┌─────┐              ┌─────┐      │
│  │MAIN │              │SKIM-│      │
│  │DRAIN│              │MER  │      │
│  └──┬──┘              └──┬──┘      │
└─────│────────────────────│─────────┘
      │                    │
      └────────┬───────────┘
               │ SUCTION LINE
               ▼
         ┌─────────┐
         │  PUMP   │ ← Moves water
         └────┬────┘
              │ PRESSURE LINE
              ▼
         ┌─────────┐
         │ FILTER  │ ← Removes debris
         └────┬────┘
              │
         ┌────┴────┐
         │ HEATER  │ ← Optional
         └────┬────┘
              │
         ┌────┴────┐
         │ CHLOR-  │ ← Sanitizer
         │ INATOR  │
         └────┬────┘
              │ RETURN LINE
              ▼
┌─────────────────────────────────────┐
│           POOL WATER                │
│      ←○─────────○→                  │
│       RETURN JETS                   │
└─────────────────────────────────────┘''',
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
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water should turn over 1-2 times per day. Run pump 8-12 hours daily.',
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

  Widget _buildPlumbingComponents(ZaftoColors colors) {
    final components = [
      {
        'name': 'Main Drain',
        'purpose': 'Bottom suction, debris removal',
        'code': 'VGB compliant dual drains required',
      },
      {
        'name': 'Skimmer',
        'purpose': 'Surface debris collection',
        'code': '1 per 500 sq ft of surface',
      },
      {
        'name': 'Return Inlets',
        'purpose': 'Distribute clean water',
        'code': 'Position for circulation pattern',
      },
      {
        'name': 'Suction Lines',
        'purpose': 'Carry water to pump',
        'code': 'Below water level, airtight',
      },
      {
        'name': 'Pressure Lines',
        'purpose': 'Carry water from pump',
        'code': 'After pump, rated for PSI',
      },
      {
        'name': 'Valves',
        'purpose': 'Control flow direction',
        'code': 'Ball or gate valves',
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
              Icon(LucideIcons.pipette, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plumbing Components',
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
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name']!, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(c['purpose']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text(c['code']!, style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFlowRates(ZaftoColors colors) {
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
                'Flow Rate Calculations',
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
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPM Requirement:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  'GPM = Pool Volume (gal) ÷ Turnover Time (min)',
                  style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: 20,000 gal ÷ 480 min (8hr) = 42 GPM',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFlowRow(colors, 'Residential', '40-80 GPM', '8-hour turnover'),
          _buildFlowRow(colors, 'Commercial', '100-500 GPM', '6-hour turnover'),
          _buildFlowRow(colors, 'Spa/Hot Tub', '50-100 GPM', '15-30 min turnover'),
          _buildFlowRow(colors, 'Wading Pool', '50-150 GPM', '1-hour turnover'),
        ],
      ),
    );
  }

  Widget _buildFlowRow(ZaftoColors colors, String type, String gpm, String turnover) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(gpm, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(turnover, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizing(ZaftoColors colors) {
    final sizes = [
      {'pipe': '1.5"', 'maxGpm': '45', 'velocity': '6 ft/s', 'use': 'Residential suction'},
      {'pipe': '2"', 'maxGpm': '75', 'velocity': '6 ft/s', 'use': 'Standard residential'},
      {'pipe': '2.5"', 'maxGpm': '115', 'velocity': '6 ft/s', 'use': 'Large residential'},
      {'pipe': '3"', 'maxGpm': '165', 'velocity': '6 ft/s', 'use': 'Commercial'},
      {'pipe': '4"', 'maxGpm': '300', 'velocity': '6 ft/s', 'use': 'Large commercial'},
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
              Icon(LucideIcons.circle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pipe Sizing Guide',
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
            'Schedule 40 PVC - Max 6 ft/s velocity suction, 8 ft/s pressure',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(width: 45, child: Text('Size', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              SizedBox(width: 55, child: Text('Max GPM', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              SizedBox(width: 55, child: Text('Velocity', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(child: Text('Application', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
            ],
          ),
          const SizedBox(height: 8),
          ...sizes.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(width: 45, child: Text(s['pipe']!, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                SizedBox(width: 55, child: Text(s['maxGpm']!, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
                SizedBox(width: 55, child: Text(s['velocity']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(child: Text(s['use']!, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
