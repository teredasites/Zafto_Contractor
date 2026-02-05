import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class RapidShutdownScreen extends ConsumerWidget {
  const RapidShutdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Rapid Shutdown (NEC 690.12)',
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
            _buildRequirementsDiagram(colors),
            const SizedBox(height: 24),
            _buildVoltageLimits(colors),
            const SizedBox(height: 24),
            _buildComplianceMethods(colors),
            const SizedBox(height: 24),
            _buildLabelingRequirements(colors),
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
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.power, color: colors.accentError, size: 24),
              const SizedBox(width: 12),
              Text(
                'Rapid Shutdown Overview',
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
            'NEC 690.12 requires PV systems on buildings to reduce conductor voltage within 30 seconds of rapid shutdown initiation. This protects firefighters and first responders from electrical hazards.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Required for all PV systems on or penetrating buildings (NEC 2017+)',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsDiagram(ZaftoColors colors) {
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
            'Array Boundary & Control Zones',
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
│              ARRAY BOUNDARY (1ft from edge)             │
│  ┌───────────────────────────────────────────────────┐  │
│  │                                                   │  │
│  │    ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐        │  │
│  │    │ PV   │  │ PV   │  │ PV   │  │ PV   │        │  │
│  │    │ +RSD │  │ +RSD │  │ +RSD │  │ +RSD │        │  │
│  │    └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘        │  │
│  │       │         │         │         │            │  │
│  │    ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐        │  │
│  │    │ PV   │  │ PV   │  │ PV   │  │ PV   │        │  │
│  │    │ +RSD │  │ +RSD │  │ +RSD │  │ +RSD │        │  │
│  │    └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘        │  │
│  │       └─────────┴────┬────┴─────────┘            │  │
│  │                      │                           │  │
│  │   INSIDE BOUNDARY: ≤80V within 30 sec            │  │
│  └──────────────────────┼───────────────────────────┘  │
│                         │                              │
│   OUTSIDE BOUNDARY: ≤30V within 30 sec                 │
│                         │                              │
└─────────────────────────┼──────────────────────────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │  RAPID SHUT   │
                  │  DOWN SWITCH  │◄── Initiator
                  │  (at service) │
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │   INVERTER    │
                  └───────────────┘''',
              style: TextStyle(
                color: colors.accentError,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageLimits(ZaftoColors colors) {
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
              Icon(LucideIcons.zap, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voltage Requirements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVoltageCard(colors, 'Outside Array Boundary', '>1ft from array edge',
            '≤30V DC', '≤240VA', 'Within 30 seconds', colors.accentError),
          const SizedBox(height: 12),
          _buildVoltageCard(colors, 'Inside Array Boundary', 'Within 1ft of array',
            '≤80V DC', 'N/A', 'Within 30 seconds', colors.accentWarning),
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
                Text('NEC Code Timeline:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildCodeVersion(colors, 'NEC 2014', 'First RSD requirement (outside boundary only)'),
                _buildCodeVersion(colors, 'NEC 2017', 'Added module-level (inside boundary) requirement'),
                _buildCodeVersion(colors, 'NEC 2020', 'Clarified initiation methods'),
                _buildCodeVersion(colors, 'NEC 2023', 'Current requirements'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageCard(ZaftoColors colors, String title, String location,
      String voltage, String power, String time, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(location, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLimitChip(colors, 'Voltage', voltage, accentColor),
              const SizedBox(width: 8),
              if (power != 'N/A') _buildLimitChip(colors, 'Power', power, accentColor),
              const SizedBox(width: 8),
              _buildLimitChip(colors, 'Time', time, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          Text(value, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCodeVersion(ZaftoColors colors, String version, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(version, style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildComplianceMethods(ZaftoColors colors) {
    final methods = [
      {
        'name': 'Microinverters',
        'description': 'Inherent compliance - only AC on roof. De-energizes when grid lost.',
        'examples': 'Enphase IQ8+, APsystems',
        'icon': LucideIcons.cpu,
        'color': colors.accentSuccess,
      },
      {
        'name': 'DC Optimizers',
        'description': 'Module-level electronics reduce to 1V/optimizer when signal lost.',
        'examples': 'SolarEdge, Tigo',
        'icon': LucideIcons.maximize2,
        'color': colors.accentInfo,
      },
      {
        'name': 'RSD Transmitter/Receiver',
        'description': 'Add-on devices for string inverter systems. PLC or wireless signal.',
        'examples': 'Tigo TS4-R-F, SMA',
        'icon': LucideIcons.radio,
        'color': colors.accentWarning,
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
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Compliance Methods',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...methods.map((m) => _buildMethodCard(colors, m)),
        ],
      ),
    );
  }

  Widget _buildMethodCard(ZaftoColors colors, Map<String, dynamic> method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (method['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(method['icon'] as IconData, color: method['color'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(method['description'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Examples: ${method['examples']}', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelingRequirements(ZaftoColors colors) {
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
              Icon(LucideIcons.tag, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Required Labels (NEC 690.56)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabelExample(colors, 'At RSD Initiator',
            'PHOTOVOLTAIC SYSTEM\nRAPID SHUTDOWN SWITCH', colors.accentError),
          _buildLabelExample(colors, 'At Service Panel',
            'PHOTOVOLTAIC SYSTEM EQUIPPED\nWITH RAPID SHUTDOWN', colors.accentWarning),
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
                Text('Label Specifications:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildLabelSpec(colors, 'Red background with white text'),
                _buildLabelSpec(colors, 'Reflective material'),
                _buildLabelSpec(colors, 'Minimum 3/8" characters'),
                _buildLabelSpec(colors, 'Weather/UV resistant'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelExample(ZaftoColors colors, String location, String text, Color labelColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(location, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelSpec(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
