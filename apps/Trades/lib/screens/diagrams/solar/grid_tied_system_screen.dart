import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class GridTiedSystemScreen extends ConsumerWidget {
  const GridTiedSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Grid-Tied PV System',
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
            _buildSystemDiagram(colors),
            const SizedBox(height: 24),
            _buildComponentsSection(colors),
            const SizedBox(height: 24),
            _buildCodeRequirements(colors),
            const SizedBox(height: 24),
            _buildNetMeteringSection(colors),
            const SizedBox(height: 24),
            _buildSizingGuide(colors),
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
              Icon(LucideIcons.sun, color: colors.accentWarning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Grid-Tied System Overview',
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
            'Grid-tied (grid-connected) solar systems are the most common type of residential and commercial PV installations. They operate in parallel with the utility grid, allowing excess power to be exported and grid power to be used when solar production is insufficient.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(colors, LucideIcons.zap, 'No battery storage required'),
          _buildInfoRow(colors, LucideIcons.dollarSign, 'Net metering credits available'),
          _buildInfoRow(colors, LucideIcons.shieldOff, 'Does not provide backup power'),
          _buildInfoRow(colors, LucideIcons.percent, 'Highest efficiency (95-98%)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSystemDiagram(ZaftoColors colors) {
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
            'Grid-Tied System Architecture',
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
┌─────────────────────────────────────────────────────────┐
│                    SOLAR ARRAY                          │
│    ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐              │
│    │ Panel│──│ Panel│──│ Panel│──│ Panel│   STRING 1   │
│    └──────┘  └──────┘  └──────┘  └──────┘              │
│         │                              │                │
│    ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐              │
│    │ Panel│──│ Panel│──│ Panel│──│ Panel│   STRING 2   │
│    └──────┘  └──────┘  └──────┘  └──────┘              │
└────────────────────┬────────────────────────────────────┘
                     │ DC (+/-)
                     ▼
            ┌────────────────┐
            │  DC DISCONNECT │ ◄── NEC 690.15
            │   (Optional)   │
            └───────┬────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │    STRING INVERTER    │
        │  ┌─────────────────┐  │
        │  │ DC → AC (240V)  │  │
        │  │ MPPT Tracking   │  │
        │  │ Grid Sync       │  │
        │  └─────────────────┘  │
        │    97-99% Efficient   │
        └───────────┬───────────┘
                    │ AC (240V)
                    ▼
            ┌────────────────┐
            │ AC DISCONNECT  │ ◄── NEC 690.13
            │  (Required)    │
            └───────┬────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   PRODUCTION METER    │
        │   (PV Generation)     │
        └───────────┬───────────┘
                    │
                    ▼
    ┌───────────────────────────────┐
    │       MAIN SERVICE PANEL      │
    │  ┌─────────────────────────┐  │
    │  │ Main Breaker   200A     │  │
    │  ├─────────────────────────┤  │
    │  │ Solar Breaker  ≤40A     │  │ ◄── 120% Rule
    │  │ Branch Circuits         │  │
    │  │ (Home Loads)            │  │
    │  └─────────────────────────┘  │
    └───────────────┬───────────────┘
                    │
                    ▼
            ┌────────────────┐
            │  UTILITY METER │
            │ (Net Metering) │
            └───────┬────────┘
                    │
                    ▼
            ┌────────────────┐
            │  UTILITY GRID  │
            │    (120/240V)  │
            └────────────────┘''',
              style: TextStyle(
                color: colors.accentPrimary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsSection(ZaftoColors colors) {
    final components = [
      {
        'name': 'Solar Panels (Modules)',
        'icon': LucideIcons.sun,
        'specs': [
          'Monocrystalline: 20-23% efficiency',
          'Polycrystalline: 15-17% efficiency',
          'Typical: 400-450W per panel',
          'Voc: 40-50V, Isc: 10-12A typical',
        ],
      },
      {
        'name': 'String Inverter',
        'icon': LucideIcons.zap,
        'specs': [
          'Converts DC to 240V AC',
          'MPPT for max power extraction',
          'Grid-sync with anti-islanding',
          'Typical sizes: 5-12 kW residential',
        ],
      },
      {
        'name': 'Racking System',
        'icon': LucideIcons.layers,
        'specs': [
          'Roof-mount or ground-mount',
          'Tilt angle: latitude ± 15°',
          'Wind/snow load rated',
          'Grounding integrated',
        ],
      },
      {
        'name': 'Monitoring System',
        'icon': LucideIcons.monitor,
        'specs': [
          'Real-time production data',
          'String-level or panel-level',
          'Mobile app connectivity',
          'Alert notifications',
        ],
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
          Text(
            'System Components',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...components.map((comp) => _buildComponentCard(
            colors,
            comp['name'] as String,
            comp['icon'] as IconData,
            comp['specs'] as List<String>,
          )),
        ],
      ),
    );
  }

  Widget _buildComponentCard(ZaftoColors colors, String name, IconData icon, List<String> specs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...specs.map((spec) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: colors.accentPrimary)),
                Expanded(
                  child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
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
              Icon(LucideIcons.fileText, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'NEC 690 Requirements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeItem(colors, '690.12', 'Rapid Shutdown',
            'Systems on buildings must have rapid shutdown capability. Controlled conductors >1ft from array must be reduced to ≤30V within 30 seconds.'),
          _buildCodeItem(colors, '690.13', 'AC Disconnect',
            'Required disconnect means for AC output of inverter. Must be accessible and lockable.'),
          _buildCodeItem(colors, '690.15', 'DC Disconnects',
            'Disconnects required for PV source circuits and output circuits. May be integral to inverter.'),
          _buildCodeItem(colors, '690.41', 'System Grounding',
            'One conductor of two-wire system with >50V shall be grounded. Ungrounded systems must have GFP.'),
          _buildCodeItem(colors, '690.64', '120% Rule',
            'Sum of PV breaker + main breaker cannot exceed 120% of busbar rating. Or use supply-side connection.'),
        ],
      ),
    );
  }

  Widget _buildCodeItem(ZaftoColors colors, String code, String title, String description) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentError.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: colors.accentError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildNetMeteringSection(ZaftoColors colors) {
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
              Icon(LucideIcons.arrowLeftRight, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Net Metering',
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
Day (Solar Production)        Night (Grid Power)
─────────────────────         ─────────────────────

  Sun → Panels → Home           Grid → Home
           │
           ▼                   Meter runs FORWARD
    Excess → Grid              (using credits)

  Meter runs BACKWARD
  (earning credits)''',
              style: TextStyle(
                color: colors.accentSuccess,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Net metering policies vary by state and utility. Common arrangements:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(colors, LucideIcons.check, 'Full retail credit (1:1)'),
          _buildInfoRow(colors, LucideIcons.check, 'Wholesale rate credit'),
          _buildInfoRow(colors, LucideIcons.check, 'Time-of-use rates'),
          _buildInfoRow(colors, LucideIcons.check, 'Annual true-up billing'),
        ],
      ),
    );
  }

  Widget _buildSizingGuide(ZaftoColors colors) {
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
                'System Sizing Guide',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSizingStep(colors, '1', 'Annual Usage',
            'Get 12 months of utility bills. Average home: 10,000-12,000 kWh/year'),
          _buildSizingStep(colors, '2', 'Sun Hours',
            'Peak sun hours vary by location. US average: 4-6 hours/day'),
          _buildSizingStep(colors, '3', 'System Size',
            'kWh/year ÷ 365 ÷ sun hours ÷ 0.8 (derating) = kW needed'),
          _buildSizingStep(colors, '4', 'Panel Count',
            'System kW × 1000 ÷ panel watts = number of panels'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Example: 10,000 kWh ÷ 365 ÷ 5 hrs ÷ 0.8 = 6.85 kW system\n6,850W ÷ 400W panels = 17-18 panels',
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

  Widget _buildSizingStep(ZaftoColors colors, String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentInfo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: colors.bgBase,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                Text(
                  description,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
