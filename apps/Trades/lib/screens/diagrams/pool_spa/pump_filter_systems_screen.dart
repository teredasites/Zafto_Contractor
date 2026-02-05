import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PumpFilterSystemsScreen extends ConsumerWidget {
  const PumpFilterSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Pump & Filter Systems',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPumpTypes(colors),
            const SizedBox(height: 24),
            _buildPumpSizing(colors),
            const SizedBox(height: 24),
            _buildFilterTypes(colors),
            const SizedBox(height: 24),
            _buildMaintenanceSchedule(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpTypes(ZaftoColors colors) {
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
              Icon(LucideIcons.fan, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Pool Pump Types',
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
              '''PUMP CROSS-SECTION

       MOTOR
    ┌─────────┐
    │  ═══    │ ← Windings
    │ ┌───┐   │
    │ │ ○ │   │ ← Shaft
    │ └─┬─┘   │
    └───┼─────┘
        │
    ┌───┴───┐
    │ SEAL  │ ← Mechanical seal
    └───┬───┘
        │
  ┌─────┴─────┐
  │  IMPELLER │
  │    ╭─╮    │ ← Spinning vanes
  │ ←──│●│──→ │   pull water in,
  │    ╰─╯    │   push it out
  └─────┬─────┘
        │
     ╔══╧══╗
     ║     ║
SUCTION   DISCHARGE
  IN        OUT''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPumpType(colors, 'Single Speed', 'One fixed RPM', '\$200-400', 'High energy cost'),
          _buildPumpType(colors, 'Two Speed', 'High/low settings', '\$400-700', 'Better efficiency'),
          _buildPumpType(colors, 'Variable Speed', 'Adjustable RPM', '\$800-1500', 'Best efficiency, quiet'),
        ],
      ),
    );
  }

  Widget _buildPumpType(ZaftoColors colors, String name, String desc, String cost, String note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
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
                Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(cost, style: TextStyle(color: colors.accentSuccess, fontSize: 9)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpSizing(ZaftoColors colors) {
    final sizing = [
      {'pool': 'Up to 15,000 gal', 'hp': '1.0 HP', 'gpm': '50-60'},
      {'pool': '15,000-25,000 gal', 'hp': '1.5 HP', 'gpm': '60-80'},
      {'pool': '25,000-35,000 gal', 'hp': '2.0 HP', 'gpm': '80-100'},
      {'pool': '35,000-50,000 gal', 'hp': '2.5-3.0 HP', 'gpm': '100-130'},
      {'pool': 'Spa/Hot Tub', 'hp': '1.5-3.0 HP', 'gpm': '100-200'},
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
              Icon(LucideIcons.ruler, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pump Sizing Guide',
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
              Expanded(flex: 3, child: Text('Pool Size', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(flex: 2, child: Text('Motor', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(flex: 2, child: Text('Flow Rate', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
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
                Expanded(flex: 3, child: Text(s['pool']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                Expanded(flex: 2, child: Text(s['hp']!, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('${s['gpm']} GPM', style: TextStyle(color: colors.textSecondary, fontSize: 10))),
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
                    'Oversized pump = wasted energy. Match pump to pool and plumbing size.',
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

  Widget _buildFilterTypes(ZaftoColors colors) {
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
              Icon(LucideIcons.filter, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filter Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterCard(
            colors,
            'Sand Filter',
            '20-40 microns',
            [
              'Lowest maintenance',
              'Backwash to clean',
              'Replace sand every 5-7 years',
            ],
            'Largest footprint, least filtration',
          ),
          _buildFilterCard(
            colors,
            'Cartridge Filter',
            '10-20 microns',
            [
              'No backwashing (saves water)',
              'Remove and hose off',
              'Replace cartridge every 1-2 years',
            ],
            'Best balance of filtration/maintenance',
          ),
          _buildFilterCard(
            colors,
            'DE Filter',
            '3-5 microns',
            [
              'Best filtration quality',
              'Backwash + recharge DE',
              'Requires regular DE addition',
            ],
            'Most maintenance, clearest water',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter Sizing Rule:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  'Filter flow rate ≥ pump flow rate\nSand: 1 sq ft per 10,000 gal\nCartridge: 100 sq ft per 10,000 gal\nDE: 1 sq ft per 10,000 gal',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(ZaftoColors colors, String name, String microns, List<String> points, String note) {
    return Container(
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
              Text(name, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(microns, style: TextStyle(color: colors.accentWarning, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.check, color: colors.accentSuccess, size: 12),
                const SizedBox(width: 6),
                Expanded(child: Text(p, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
              ],
            ),
          )),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 9, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSchedule(ZaftoColors colors) {
    final tasks = [
      {'freq': 'Daily', 'task': 'Check pump basket, skim surface', 'icon': LucideIcons.sun},
      {'freq': 'Weekly', 'task': 'Check filter pressure, backwash if +8-10 PSI', 'icon': LucideIcons.calendar},
      {'freq': 'Monthly', 'task': 'Inspect pump seal, check for leaks', 'icon': LucideIcons.wrench},
      {'freq': 'Quarterly', 'task': 'Deep clean cartridge or DE grids', 'icon': LucideIcons.sparkles},
      {'freq': 'Annually', 'task': 'Inspect motor, lubricate O-rings', 'icon': LucideIcons.settings},
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
              Icon(LucideIcons.clipboardList, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Maintenance Schedule',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(t['icon'] as IconData, color: colors.accentInfo, size: 16),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: Text(t['freq']! as String, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                Expanded(
                  child: Text(t['task']! as String, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
