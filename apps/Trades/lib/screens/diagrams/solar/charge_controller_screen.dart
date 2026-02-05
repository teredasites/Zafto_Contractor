import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ChargeControllerScreen extends ConsumerWidget {
  const ChargeControllerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Charge Controllers',
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
            _buildComparisonDiagram(colors),
            const SizedBox(height: 24),
            _buildMPPTSection(colors),
            const SizedBox(height: 24),
            _buildPWMSection(colors),
            const SizedBox(height: 24),
            _buildSizingGuide(colors),
            const SizedBox(height: 24),
            _buildChargingStages(colors),
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
              Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Charge Controller Overview',
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
            'Charge controllers regulate voltage and current from solar panels to batteries, preventing overcharging and optimizing charging efficiency. They are essential for any off-grid or battery-backup system.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypePreview(colors, 'PWM', 'Budget option', '75-80%', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypePreview(colors, 'MPPT', 'Premium option', '95-99%', colors.accentSuccess),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypePreview(ZaftoColors colors, String type, String desc, String efficiency, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(type, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(efficiency, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          Text('Efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildComparisonDiagram(ZaftoColors colors) {
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
            'MPPT vs PWM Power Conversion',
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
PWM (Pulse Width Modulation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Panel Vmp must ≈ Battery Voltage

  Panel Output          PWM Controller         Battery
  ┌──────────┐         ┌──────────────┐       ┌────────┐
  │ 18V Vmp  │────────►│  Pulses at   │──────►│  12V   │
  │ 5.5A Imp │         │  battery V   │       │ Battery│
  │ = 99W    │         │              │       │        │
  └──────────┘         │ 12V × 5.5A   │       └────────┘
                       │ = 66W output │
                       └──────────────┘

  Efficiency: 66W ÷ 99W = 67% (power lost!)


MPPT (Maximum Power Point Tracking)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Panel Vmp can be HIGHER than Battery Voltage

  Panel Output          MPPT Controller        Battery
  ┌──────────┐         ┌──────────────┐       ┌────────┐
  │ 36V Vmp  │────────►│ DC-DC Buck   │──────►│  12V   │
  │ 5.5A Imp │         │ Converter    │       │ Battery│
  │ = 198W   │         │              │       │        │
  └──────────┘         │ Tracks MPP   │       └────────┘
                       │ 12V × 15.8A  │
                       │ = 190W output│
                       └──────────────┘

  Efficiency: 190W ÷ 198W = 96% (minimal loss!)''',
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

  Widget _buildMPPTSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentSuccess,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('MPPT', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(
                'Maximum Power Point Tracking',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(colors, LucideIcons.check, 'Converts excess voltage to current', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, 'Panel voltage can exceed battery voltage', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, '15-30% more power harvest vs PWM', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, 'Better performance in cold/cloudy conditions', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, 'Allows higher voltage strings (less wire loss)', colors.accentSuccess),
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
                Text('Best For:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('• Systems >200W\n• Cold climates\n• Long wire runs\n• Maximum efficiency needed\n• Higher voltage panels',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPWMSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentWarning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('PWM', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(
                'Pulse Width Modulation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(colors, LucideIcons.check, 'Simple, reliable technology', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, 'Lower cost', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.check, 'Good for small systems', colors.accentSuccess),
          _buildFeatureRow(colors, LucideIcons.x, 'Panel Vmp must match battery voltage', colors.accentError),
          _buildFeatureRow(colors, LucideIcons.x, 'Wastes excess voltage as heat', colors.accentError),
          _buildFeatureRow(colors, LucideIcons.x, 'Less efficient in cold weather', colors.accentError),
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
                Text('Best For:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('• Small systems <200W\n• Budget projects\n• 12V "nominal" panels\n• Warm/hot climates\n• Simple installations',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
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
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
                'Charge Controller Sizing',
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
MPPT SIZING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Check Max Input Voltage:
   Array Voc (cold) < Controller Max Voc
   Apply temp correction for cold climate

2. Check Max Input Current:
   Array Isc × 1.25 < Controller Max Input

3. Check Output Current:
   Array Watts ÷ Battery V ÷ Efficiency
   Must be < Controller Amp Rating

Example: 1200W array, 24V battery
  Output Current = 1200 ÷ 24 ÷ 0.95
                 = 52.6A
  Select: 60A MPPT controller

PWM SIZING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Match Panel Vmp to Battery:
   12V battery → 18V Vmp panel
   24V battery → 36V Vmp panel

2. Size for Current:
   Controller Amps > Array Isc × 1.25''',
              style: TextStyle(
                color: colors.accentInfo,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingStages(ZaftoColors colors) {
    final stages = [
      {
        'name': 'Bulk',
        'voltage': 'Rising',
        'current': 'Maximum',
        'description': 'Full current until battery reaches absorption voltage',
        'percent': '0-80%',
        'color': colors.accentError,
      },
      {
        'name': 'Absorption',
        'voltage': 'Constant',
        'current': 'Decreasing',
        'description': 'Holds voltage while current tapers off',
        'percent': '80-95%',
        'color': colors.accentWarning,
      },
      {
        'name': 'Float',
        'voltage': 'Lower',
        'current': 'Minimal',
        'description': 'Maintains full charge without overcharging',
        'percent': '95-100%',
        'color': colors.accentSuccess,
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
              Icon(LucideIcons.batteryCharging, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                '3-Stage Charging',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stages.map((s) => _buildStageCard(colors, s)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some controllers add Equalization stage for flooded lead-acid batteries to prevent sulfation.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(ZaftoColors colors, Map<String, dynamic> stage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (stage['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: stage['color'] as Color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(stage['name'] as String, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(stage['percent'] as String, style: TextStyle(color: colors.bgBase.withValues(alpha: 0.8), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('V: ${stage['voltage']}', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(width: 12),
                    Text('I: ${stage['current']}', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(stage['description'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
