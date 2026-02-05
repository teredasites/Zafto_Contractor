import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class OffGridSystemScreen extends ConsumerWidget {
  const OffGridSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Off-Grid Battery System',
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
            _buildBatteryTypes(colors),
            const SizedBox(height: 24),
            _buildSizingCalculations(colors),
            const SizedBox(height: 24),
            _buildChargeControllers(colors),
            const SizedBox(height: 24),
            _buildSafetyRequirements(colors),
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
              Icon(LucideIcons.batteryCharging, color: colors.accentSuccess, size: 24),
              const SizedBox(width: 12),
              Text(
                'Off-Grid System Overview',
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
            'Off-grid systems operate independently from the utility grid, using battery storage to provide power when solar production is unavailable. These systems require careful sizing to ensure reliable power supply.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(colors, LucideIcons.battery, 'Battery storage required', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.wifiOff, 'Complete energy independence', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.shield, 'Backup power always available', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.dollarSign, 'Higher upfront cost', colors.accentWarning),
          _buildFeatureRow(colors, LucideIcons.settings, 'More maintenance required', colors.accentWarning),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ZaftoColors colors, IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
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
            'Off-Grid System Architecture',
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
┌───────────────────────────────────────────────────────┐
│                    SOLAR ARRAY                        │
│         ┌──────┐  ┌──────┐  ┌──────┐                 │
│         │ 400W │──│ 400W │──│ 400W │  String 1       │
│         └──────┘  └──────┘  └──────┘                 │
│         ┌──────┐  ┌──────┐  ┌──────┐                 │
│         │ 400W │──│ 400W │──│ 400W │  String 2       │
│         └──────┘  └──────┘  └──────┘                 │
└────────────────────┬──────────────────────────────────┘
                     │ DC (Voc × panels)
                     ▼
        ┌───────────────────────────┐
        │    CHARGE CONTROLLER      │
        │  ┌─────────────────────┐  │
        │  │ MPPT or PWM         │  │
        │  │ Battery charging    │  │
        │  │ Voltage regulation  │  │
        │  │ Overcharge protect  │  │
        │  └─────────────────────┘  │
        └─────────────┬─────────────┘
                      │
      ┌───────────────┼───────────────┐
      │               │               │
      ▼               ▼               ▼
┌───────────┐  ┌───────────┐  ┌───────────┐
│  Battery  │──│  Battery  │──│  Battery  │
│   48V     │  │   48V     │  │   48V     │
│  100Ah    │  │  100Ah    │  │  100Ah    │
└───────────┘  └───────────┘  └───────────┘
      │               │               │
      └───────────────┼───────────────┘
                      │ 48V DC Bus
                      ▼
            ┌───────────────────┐
            │  DC DISCONNECT    │
            │   w/ Fusing       │
            └─────────┬─────────┘
                      │
                      ▼
        ┌───────────────────────────┐
        │    OFF-GRID INVERTER      │
        │  ┌─────────────────────┐  │
        │  │ DC → AC (120/240V)  │  │
        │  │ Pure sine wave      │  │
        │  │ Load management     │  │
        │  │ Generator input     │◄─┼─── BACKUP GEN
        │  └─────────────────────┘  │    (Optional)
        └─────────────┬─────────────┘
                      │ AC 120/240V
                      ▼
            ┌───────────────────┐
            │   LOAD CENTER     │
            │  (Sub-Panel)      │
            │ ┌───────────────┐ │
            │ │ Critical Loads│ │
            │ │ Refrigerator  │ │
            │ │ Lights        │ │
            │ │ Well Pump     │ │
            │ └───────────────┘ │
            └───────────────────┘''',
              style: TextStyle(
                color: colors.accentSuccess,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryTypes(ZaftoColors colors) {
    final batteries = [
      {
        'type': 'Lithium Iron Phosphate (LiFePO4)',
        'pros': ['4000+ cycles', '100% DoD safe', 'No maintenance', 'Lightweight'],
        'cons': ['Higher cost', 'BMS required', 'Cold temp limitations'],
        'voltage': '48V nominal',
        'lifespan': '10-15 years',
        'color': colors.accentSuccess,
      },
      {
        'type': 'Lead-Acid (FLA)',
        'pros': ['Low cost', 'Proven technology', 'Easy recycling'],
        'cons': ['50% DoD max', 'Maintenance required', 'Shorter life', 'Heavy'],
        'voltage': '48V (4×12V)',
        'lifespan': '3-5 years',
        'color': colors.accentWarning,
      },
      {
        'type': 'AGM/Gel (VRLA)',
        'pros': ['Sealed/maintenance-free', 'No gassing', 'Position flexible'],
        'cons': ['50% DoD', 'Sensitive to overcharge', 'Higher cost than FLA'],
        'voltage': '48V (4×12V)',
        'lifespan': '5-7 years',
        'color': colors.accentInfo,
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
              Icon(LucideIcons.battery, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Battery Technologies',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...batteries.map((bat) => _buildBatteryCard(colors, bat)),
        ],
      ),
    );
  }

  Widget _buildBatteryCard(ZaftoColors colors, Map<String, dynamic> battery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (battery['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: battery['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  battery['type'] as String,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBatterySpec(colors, 'Voltage', battery['voltage'] as String),
              const SizedBox(width: 16),
              _buildBatterySpec(colors, 'Lifespan', battery['lifespan'] as String),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pros', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600)),
                    ...(battery['pros'] as List<String>).map((p) =>
                      Text('• $p', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cons', style: TextStyle(color: colors.accentError, fontSize: 12, fontWeight: FontWeight.w600)),
                    ...(battery['cons'] as List<String>).map((c) =>
                      Text('• $c', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatterySpec(ZaftoColors colors, String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSizingCalculations(ZaftoColors colors) {
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
                'Battery Bank Sizing',
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
                  'Sizing Formula:',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '''
Battery Capacity (Ah) =
  Daily Load (Wh) × Days of Autonomy
  ────────────────────────────────────
  Battery Voltage × DoD × Efficiency

Example:
  Daily Load: 5,000 Wh
  Days of Autonomy: 2
  Battery Voltage: 48V
  DoD (LiFePO4): 80%
  Efficiency: 85%

  Capacity = (5000 × 2) ÷ (48 × 0.8 × 0.85)
           = 10,000 ÷ 32.64
           = 306 Ah @ 48V''',
                  style: TextStyle(
                    color: colors.accentInfo,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSizingTip(colors, 'Days of Autonomy', '2-3 days typical, 5-7 for critical loads'),
          _buildSizingTip(colors, 'Depth of Discharge', 'LiFePO4: 80-100%, Lead-acid: 50%'),
          _buildSizingTip(colors, 'Temperature Derating', 'Add 20-25% for cold climates'),
          _buildSizingTip(colors, 'Future Expansion', 'Size for 20-30% growth'),
        ],
      ),
    );
  }

  Widget _buildSizingTip(ZaftoColors colors, String label, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  TextSpan(
                    text: tip,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeControllers(ZaftoColors colors) {
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
                'Charge Controller Selection',
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
              Expanded(child: _buildControllerType(colors, 'PWM', false)),
              const SizedBox(width: 12),
              Expanded(child: _buildControllerType(colors, 'MPPT', true)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.thumbsUp, color: colors.accentSuccess, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MPPT recommended for systems >200W. Provides 15-30% more harvest vs PWM.',
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

  Widget _buildControllerType(ZaftoColors colors, String type, bool recommended) {
    final isPWM = type == 'PWM';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommended ? colors.accentSuccess.withValues(alpha: 0.5) : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                type,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BEST',
                    style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPWM ? 'Pulse Width Modulation' : 'Maximum Power Point Tracking',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            isPWM
              ? '• 75-80% efficient\n• Panel V ≈ Battery V\n• Lower cost\n• Simple operation'
              : '• 95-99% efficient\n• Panel V > Battery V OK\n• More power harvest\n• Better in low light',
            style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRequirements(ZaftoColors colors) {
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
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Safety Requirements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSafetyItem(colors, 'Ventilation', 'Lead-acid batteries produce hydrogen gas. Provide adequate ventilation per NEC 480.'),
          _buildSafetyItem(colors, 'Fusing', 'Battery bank fusing required within 18" of battery terminals. Size for 125% of max current.'),
          _buildSafetyItem(colors, 'Disconnects', 'DC disconnect required between batteries and inverter. Must be rated for DC voltage.'),
          _buildSafetyItem(colors, 'Overcurrent', 'Class T or ANL fuses for high-current DC circuits. Breakers must be DC-rated.'),
          _buildSafetyItem(colors, 'Grounding', 'Battery enclosure and all metal must be grounded. GFP required per NEC 690.41.'),
          _buildSafetyItem(colors, 'Signage', 'Warning labels required: voltage, current ratings, emergency shutdown procedure.'),
        ],
      ),
    );
  }

  Widget _buildSafetyItem(ZaftoColors colors, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, color: colors.accentError, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
