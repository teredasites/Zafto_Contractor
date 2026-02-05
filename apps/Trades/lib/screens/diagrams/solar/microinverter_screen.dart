import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class MicroinverterScreen extends ConsumerWidget {
  const MicroinverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Microinverter Systems',
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
            _buildComparisonSection(colors),
            const SizedBox(height: 24),
            _buildWiringDetails(colors),
            const SizedBox(height: 24),
            _buildInstallationTips(colors),
            const SizedBox(height: 24),
            _buildMonitoringSection(colors),
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
              Icon(LucideIcons.cpu, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Microinverter Overview',
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
            'Microinverters convert DC to AC at each individual panel, eliminating high-voltage DC on the roof. Each panel operates independently with its own MPPT, maximizing production even with partial shading.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatBox(colors, '97%', 'Peak Efficiency', colors.accentSuccess)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(colors, '25yr', 'Warranty', colors.accentInfo)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(colors, '240V', 'AC Output', colors.accentWarning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
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
            'Microinverter System Architecture',
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
┌──────────────────────────────────────────────────────┐
│                    ROOF ARRAY                        │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │  Panel   │  │  Panel   │  │  Panel   │           │
│  │  400W    │  │  400W    │  │  400W    │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │DC           │DC           │DC                │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐           │
│  │  Micro   │  │  Micro   │  │  Micro   │           │
│  │ Inverter │  │ Inverter │  │ Inverter │           │
│  │  IQ8+    │  │  IQ8+    │  │  IQ8+    │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │AC           │AC           │AC                │
│       └─────────────┴─────────────┘                  │
│                     │                                │
│            AC Trunk Cable (240V)                     │
│       ┌─────────────┴─────────────┐                  │
│       │                           │                  │
│  ┌────┴─────┐  ┌──────────┐  ┌────┴─────┐           │
│  │  Panel   │  │  Panel   │  │  Panel   │           │
│  │  400W    │  │  400W    │  │  400W    │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │DC           │DC           │DC                │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐           │
│  │  Micro   │  │  Micro   │  │  Micro   │           │
│  │ Inverter │  │ Inverter │  │ Inverter │           │
│  └────┬─────┘  └────┴─────┘  └────┬─────┘           │
│       └─────────────┬─────────────┘                  │
└─────────────────────┼────────────────────────────────┘
                      │ AC Branch (240V)
                      ▼
              ┌───────────────┐
              │  Junction Box │
              │  w/ Connector │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ AC DISCONNECT │
              └───────┬───────┘
                      │
                      ▼
        ┌─────────────────────────┐
        │    ENVOY GATEWAY        │
        │  ┌───────────────────┐  │
        │  │ Communication hub │  │
        │  │ Production monitor│  │
        │  │ Grid sync control │  │
        │  └───────────────────┘  │
        └────────────┬────────────┘
                     │
                     ▼
              ┌───────────────┐
              │  MAIN PANEL   │
              │   (Load-side) │
              └───────────────┘''',
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

  Widget _buildComparisonSection(ZaftoColors colors) {
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
              Icon(LucideIcons.gitCompare, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Microinverter vs String Inverter',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(colors, 'Shade Tolerance', 'Excellent', 'Poor', true),
          _buildComparisonRow(colors, 'Panel-Level MPPT', 'Yes', 'No', true),
          _buildComparisonRow(colors, 'Monitoring', 'Per-panel', 'System only', true),
          _buildComparisonRow(colors, 'DC Voltage on Roof', 'None (AC)', 'High (300-600V)', true),
          _buildComparisonRow(colors, 'System Expansion', 'Easy', 'Limited', true),
          _buildComparisonRow(colors, 'Initial Cost', 'Higher', 'Lower', false),
          _buildComparisonRow(colors, 'Peak Efficiency', '97%', '99%', false),
          _buildComparisonRow(colors, 'Points of Failure', 'Multiple', 'Single', false),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(ZaftoColors colors, String feature, String micro, String string, bool microWins) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: microWins ? colors.accentSuccess.withValues(alpha: 0.1) : colors.bgInset,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                micro,
                style: TextStyle(
                  color: microWins ? colors.accentSuccess : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: microWins ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: !microWins ? colors.accentSuccess.withValues(alpha: 0.1) : colors.bgInset,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                string,
                style: TextStyle(
                  color: !microWins ? colors.accentSuccess : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: !microWins ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWiringDetails(ZaftoColors colors) {
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
              Icon(LucideIcons.plug, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'AC Branch Circuit Requirements',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enphase IQ8+ Branch Circuit Sizing',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '''
Per NEC 690.8 & Manufacturer Guidelines:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

20A Branch Circuit (10 AWG):
  Max Microinverters: 13 units
  Max AC Output: 3,120W (240V)
  Breaker: 20A, 2-pole

30A Branch Circuit (10 AWG):
  Max Microinverters: 17 units
  Max AC Output: 4,080W (240V)
  Breaker: 30A, 2-pole

40A Branch Circuit (8 AWG):
  Max Microinverters: 21 units
  Max AC Output: 5,040W (240V)
  Breaker: 40A, 2-pole

Multiple branches can feed combiner
for larger systems.''',
                  style: TextStyle(
                    color: colors.accentWarning,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildWiringNote(colors, LucideIcons.info, 'Use listed Q-cable or equivalent trunk cable'),
          _buildWiringNote(colors, LucideIcons.info, 'Seal unused connectors with weatherproof caps'),
          _buildWiringNote(colors, LucideIcons.info, 'Trunk cable supports daisy-chain connection'),
        ],
      ),
    );
  }

  Widget _buildWiringNote(ZaftoColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accentInfo, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationTips(ZaftoColors colors) {
    final tips = [
      {
        'title': 'Panel Pairing',
        'description': 'Match microinverter capacity to panel output. IQ8+ (290VA) pairs with 290-460W panels.',
        'icon': LucideIcons.link,
      },
      {
        'title': 'Connector Security',
        'description': 'Listen for click when connecting. Tug test all connections. Use torque wrench on terminals.',
        'icon': LucideIcons.lock,
      },
      {
        'title': 'Grounding',
        'description': 'Each microinverter grounds through AC cable. Verify continuity to main ground.',
        'icon': LucideIcons.anchor,
      },
      {
        'title': 'Serial Numbers',
        'description': 'Record position of each microinverter serial number for monitoring setup.',
        'icon': LucideIcons.hash,
      },
      {
        'title': 'Temperature Rating',
        'description': 'Microinverters derate above 113°F (45°C). Ensure adequate ventilation under panels.',
        'icon': LucideIcons.thermometer,
      },
      {
        'title': 'Rapid Shutdown',
        'description': 'IQ8 series is module-level rapid shutdown compliant. Verify initiator at AC disconnect.',
        'icon': LucideIcons.power,
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
              Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Best Practices',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => _buildTipCard(
            colors,
            tip['title'] as String,
            tip['description'] as String,
            tip['icon'] as IconData,
          )),
        ],
      ),
    );
  }

  Widget _buildTipCard(ZaftoColors colors, String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.accentSuccess, size: 16),
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
                const SizedBox(height: 4),
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

  Widget _buildMonitoringSection(ZaftoColors colors) {
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
              Icon(LucideIcons.monitor, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Monitoring & Commissioning',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envoy Gateway Setup',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildSetupStep(colors, '1', 'Install Envoy near main panel with internet access'),
                _buildSetupStep(colors, '2', 'Connect to home network via WiFi or Ethernet'),
                _buildSetupStep(colors, '3', 'Scan microinverter serial numbers with app'),
                _buildSetupStep(colors, '4', 'Map panel positions in monitoring software'),
                _buildSetupStep(colors, '5', 'Verify all units reporting before final inspection'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.eye, color: colors.accentInfo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel-Level Monitoring',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each microinverter reports individual production, allowing identification of underperforming panels, shading issues, or equipment failures.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(ZaftoColors colors, String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.accentInfo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: colors.bgBase,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
