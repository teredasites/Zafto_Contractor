import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class EngineBasicsScreen extends ConsumerWidget {
  const EngineBasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Engine Basics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFourStrokeCycle(colors),
            const SizedBox(height: 24),
            _buildEngineComponents(colors),
            const SizedBox(height: 24),
            _buildFiringOrders(colors),
            const SizedBox(height: 24),
            _buildEngineConfigurations(colors),
            const SizedBox(height: 24),
            _buildCommonSpecs(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFourStrokeCycle(ZaftoColors colors) {
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
              Icon(LucideIcons.cog, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                '4-Stroke Engine Cycle',
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
              '''1. INTAKE         2. COMPRESSION
   ┌────┐            ┌────┐
   │↓air│            │    │
   │░░░░│            │▓▓▓▓│
   │    │            │▓▓▓▓│
   │    │            │▓▓▓▓│
   └──▲─┘            └──▲─┘
   Piston down       Piston up
   Valve open        Both closed

3. POWER          4. EXHAUST
   ┌────┐            ┌────┐
   │ ★  │ ← Spark    │↑   │
   │▓▓▓▓│            │░░░░│
   │▓▓▓▓│            │    │
   │    │            │    │
   └──▼─┘            └──▲─┘
   Piston pushed     Piston up
   Both closed       Exhaust open

One complete cycle = 2 crankshaft revolutions''',
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
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Remember: Suck, Squeeze, Bang, Blow (Intake, Compression, Power, Exhaust)',
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

  Widget _buildEngineComponents(ZaftoColors colors) {
    final components = [
      {'part': 'Block', 'function': 'Main structure, houses cylinders', 'icon': LucideIcons.box},
      {'part': 'Head', 'function': 'Contains valves, spark plugs, combustion chamber', 'icon': LucideIcons.layoutGrid},
      {'part': 'Crankshaft', 'function': 'Converts linear to rotational motion', 'icon': LucideIcons.refreshCw},
      {'part': 'Camshaft', 'function': 'Opens/closes valves via lobes', 'icon': LucideIcons.settings},
      {'part': 'Pistons', 'function': 'Compress air/fuel, transmit power', 'icon': LucideIcons.arrowUpDown},
      {'part': 'Connecting Rod', 'function': 'Links piston to crankshaft', 'icon': LucideIcons.link},
      {'part': 'Timing Chain/Belt', 'function': 'Synchronizes cam to crank', 'icon': LucideIcons.timer},
      {'part': 'Head Gasket', 'function': 'Seals between head and block', 'icon': LucideIcons.layers},
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
              Icon(LucideIcons.wrench, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Major Components',
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
            child: Row(
              children: [
                Icon(c['icon'] as IconData, color: colors.accentInfo, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['part'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(c['function'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFiringOrders(ZaftoColors colors) {
    final orders = [
      {'config': '4-cyl Inline', 'order': '1-3-4-2', 'common': 'Most 4-cyl'},
      {'config': '4-cyl Inline', 'order': '1-2-4-3', 'common': 'Some VW/Audi'},
      {'config': 'V6 (90°)', 'order': '1-6-5-4-3-2', 'common': 'GM 3.8L'},
      {'config': 'V6 (60°)', 'order': '1-2-3-4-5-6', 'common': 'Many V6s'},
      {'config': 'V8 (GM)', 'order': '1-8-4-3-6-5-7-2', 'common': 'LS engines'},
      {'config': 'V8 (Ford)', 'order': '1-3-7-2-6-5-4-8', 'common': '5.0L, Modular'},
      {'config': 'V8 (Mopar)', 'order': '1-8-4-3-6-5-7-2', 'common': 'Hemi'},
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
              Icon(LucideIcons.listOrdered, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Firing Orders',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map((o) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(o['config']!, style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(o['order']!, style: TextStyle(color: colors.accentWarning, fontSize: 10, fontFamily: 'monospace')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(o['common']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEngineConfigurations(ZaftoColors colors) {
    final configs = [
      {
        'type': 'Inline-4',
        'diagram': '│1│2│3│4│',
        'pros': 'Simple, compact',
        'cons': 'Vibration at high RPM',
      },
      {
        'type': 'Inline-6',
        'diagram': '│1│2│3│4│5│6│',
        'pros': 'Smooth, balanced',
        'cons': 'Long, packaging issues',
      },
      {
        'type': 'V6',
        'diagram': '│1│3│5│\n│2│4│6│',
        'pros': 'Compact, good power',
        'cons': 'Complex, vibration',
      },
      {
        'type': 'V8',
        'diagram': '│1│3│5│7│\n│2│4│6│8│',
        'pros': 'Smooth, high power',
        'cons': 'Heavy, complex',
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
              Icon(LucideIcons.layoutGrid, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Engine Configurations',
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
            childAspectRatio: 1.0,
            children: configs.map((c) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['type']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      c['diagram']!,
                      style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  Text('+ ${c['pros']}', style: TextStyle(color: colors.accentSuccess, fontSize: 9)),
                  Text('- ${c['cons']}', style: TextStyle(color: colors.accentError, fontSize: 9)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonSpecs(ZaftoColors colors) {
    final specs = [
      {'spec': 'Oil pressure (idle)', 'value': '25-65 PSI', 'note': 'Varies by engine'},
      {'spec': 'Oil pressure (hot)', 'value': '10 PSI/1000 RPM', 'note': 'Rule of thumb'},
      {'spec': 'Operating temp', 'value': '195-220°F', 'note': 'Thermostat controls'},
      {'spec': 'Compression (gas)', 'value': '125-180 PSI', 'note': 'Per cylinder'},
      {'spec': 'Compression (diesel)', 'value': '300-500 PSI', 'note': 'Per cylinder'},
      {'spec': 'Variance max', 'value': '10%', 'note': 'Between cylinders'},
      {'spec': 'Timing advance', 'value': '10-20° BTDC', 'note': 'At idle, varies'},
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
              Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Specifications',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...specs.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(s['spec']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(s['value']!, style: TextStyle(color: colors.accentInfo, fontSize: 10), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
