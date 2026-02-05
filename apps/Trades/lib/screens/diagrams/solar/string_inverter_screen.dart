import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class StringInverterScreen extends ConsumerWidget {
  const StringInverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'String Inverter Wiring',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(colors),
            const SizedBox(height: 24),
            _buildWiringDiagram(colors),
            const SizedBox(height: 24),
            _buildStringConfiguration(colors),
            const SizedBox(height: 24),
            _buildInverterSizing(colors),
            const SizedBox(height: 24),
            _buildWireSizing(colors),
            const SizedBox(height: 24),
            _buildTroubleshooting(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ZaftoColors colors) {
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
                'String Inverter Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'String inverters connect multiple solar panels in series to create high-voltage DC strings. These strings feed a central inverter that converts DC to AC power.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSpecRow(colors, 'Input Voltage', '150-600V DC (residential)'),
          _buildSpecRow(colors, 'Output', '240V split-phase AC'),
          _buildSpecRow(colors, 'Efficiency', '96-99% CEC weighted'),
          _buildSpecRow(colors, 'MPPT Channels', '1-2 typical'),
          _buildSpecRow(colors, 'Warranty', '10-25 years'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWiringDiagram(ZaftoColors colors) {
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
          Text(
            'String Inverter Wiring Diagram',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
STRING 1 (Series Connection - adds voltage)
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│ Panel 1│    │ Panel 2│    │ Panel 3│    │ Panel 4│
│  +  -  │    │  +  -  │    │  +  -  │    │  +  -  │
└──┬──┬──┘    └──┬──┬──┘    └──┬──┬──┘    └──┬──┬──┘
   │  └──────────┘  └──────────┘  └──────────┘  │
   │ (+)                                    (-) │
   │  Voc = 45V × 4 = 180V                      │
   │                                            │
STRING 2 (Parallel Connection - adds current)  │
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│ Panel 5│    │ Panel 6│    │ Panel 7│    │ Panel 8│
│  +  -  │    │  +  -  │    │  +  -  │    │  +  -  │
└──┬──┬──┘    └──┬──┬──┘    └──┬──┬──┘    └──┬──┬──┘
   │  └──────────┘  └──────────┘  └──────────┘  │
   │ (+)                                    (-) │
   │                                            │
   └─────────────┬────────────────┬─────────────┘
                 │ (+)        (-) │
                 ▼                ▼
        ┌────────────────────────────────┐
        │         DC COMBINER BOX        │
        │  ┌────────────────────────┐    │
        │  │ String 1 Fuse  15A     │    │
        │  │ String 2 Fuse  15A     │    │
        │  │ DC Disconnect          │    │
        │  │ Surge Protection       │    │
        │  └────────────────────────┘    │
        └────────────────┬───────────────┘
                         │
                         │ DC+ / DC- (180V, 20A)
                         ▼
        ┌────────────────────────────────┐
        │        STRING INVERTER         │
        │  ┌────────────────────────┐    │
        │  │ DC Input: 180V         │    │
        │  │ MPPT Range: 150-500V   │    │
        │  │ Max Input: 600V        │    │
        │  │ Max Current: 12A/MPPT  │    │
        │  ├────────────────────────┤    │
        │  │ AC Output: 240V        │    │
        │  │ L1 / L2 / N / G        │    │
        │  └────────────────────────┘    │
        └────────────────┬───────────────┘
                         │ AC 240V
                         ▼
                ┌────────────────┐
                │ AC DISCONNECT  │
                └───────┬────────┘
                        │
                        ▼
                ┌────────────────┐
                │  MAIN PANEL    │
                └────────────────┘''',
              style: TextStyle(
                color: colors.accentPrimary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStringConfiguration(ZaftoColors colors) {
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
              Icon(LucideIcons.gitBranch, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'String Configuration Rules',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigRule(colors, 'Voltage Limits',
            'String Voc (cold) must not exceed inverter max input voltage. Use NEC 690.7 temp correction factors.'),
          _buildConfigRule(colors, 'MPPT Window',
            'String Vmp must fall within inverter MPPT range under all conditions.'),
          _buildConfigRule(colors, 'Current Matching',
            'Strings in parallel must have matching current (Imp). Use same panel model and orientation.'),
          _buildConfigRule(colors, 'Panel Matching',
            'All panels in a string should be identical make/model and same orientation.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cold temperature increases Voc! In cold climates, size strings conservatively to avoid exceeding inverter max input voltage.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRule(ZaftoColors colors, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInverterSizing(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Inverter Sizing',
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
DC/AC Ratio Guidelines:
━━━━━━━━━━━━━━━━━━━━━━━━
Optimal: 1.15 - 1.25
Max Recommended: 1.30

Example:
  Array: 8 × 400W = 3,200W DC
  Inverter: 3,000W AC
  DC/AC Ratio: 3,200 ÷ 3,000 = 1.07

String Sizing Check:
━━━━━━━━━━━━━━━━━━━━━━━━
Panel Specs:
  Voc = 45.3V
  Vmp = 37.8V
  Imp = 10.6A

Inverter Specs:
  Max Input: 500V
  MPPT Range: 150-450V
  Max Input Current: 12A/MPPT

Max Panels/String (voltage):
  500V ÷ (45.3V × 1.14*) = 9.7 → 9 panels
  *1.14 = temp correction for -10°C

Min Panels/String (MPPT):
  150V ÷ 37.8V = 3.97 → 4 panels''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWireSizing(ZaftoColors colors) {
    final wireSizes = [
      {'amps': '10A', 'oneWay': '50ft', 'size': '10 AWG'},
      {'amps': '10A', 'oneWay': '100ft', 'size': '8 AWG'},
      {'amps': '10A', 'oneWay': '150ft', 'size': '6 AWG'},
      {'amps': '15A', 'oneWay': '50ft', 'size': '8 AWG'},
      {'amps': '15A', 'oneWay': '100ft', 'size': '6 AWG'},
      {'amps': '20A', 'oneWay': '50ft', 'size': '6 AWG'},
      {'amps': '20A', 'oneWay': '100ft', 'size': '4 AWG'},
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
              Icon(LucideIcons.plug, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'DC Wire Sizing (2% Drop)',
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
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('Current', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('Distance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('Wire Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                ),
                ...wireSizes.map((ws) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(ws['amps']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      Expanded(child: Text(ws['oneWay']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      Expanded(child: Text(ws['size']!, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Use PV Wire (USE-2 or PV Wire) rated for 90°C minimum. All DC wiring must be sunlight resistant if exposed.',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    final issues = [
      {
        'problem': 'Low Production',
        'causes': ['Shading on array', 'Dirty panels', 'String voltage mismatch', 'Inverter clipping'],
        'icon': LucideIcons.trendingDown,
      },
      {
        'problem': 'Ground Fault Error',
        'causes': ['Damaged wire insulation', 'Water intrusion', 'Faulty connector', 'Panel frame issue'],
        'icon': LucideIcons.alertCircle,
      },
      {
        'problem': 'Arc Fault Trip',
        'causes': ['Loose connection', 'Damaged conductor', 'Corroded terminal', 'Rodent damage'],
        'icon': LucideIcons.zap,
      },
      {
        'problem': 'Inverter Not Starting',
        'causes': ['Low string voltage', 'DC disconnect open', 'Grid outage (anti-island)', 'Inverter fault'],
        'icon': LucideIcons.powerOff,
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
              Icon(LucideIcons.wrench, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Troubleshooting',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...issues.map((issue) => _buildTroubleshootItem(
            colors,
            issue['problem'] as String,
            issue['causes'] as List<String>,
            issue['icon'] as IconData,
          )),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(ZaftoColors colors, String problem, List<String> causes, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Text(
                problem,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: causes.map((cause) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cause,
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
