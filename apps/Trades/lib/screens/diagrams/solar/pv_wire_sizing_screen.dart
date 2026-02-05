import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PvWireSizingScreen extends ConsumerWidget {
  const PvWireSizingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'PV Wire Sizing',
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
            _buildWireTypes(colors),
            const SizedBox(height: 24),
            _buildAmpacityTable(colors),
            const SizedBox(height: 24),
            _buildVoltageDropCalc(colors),
            const SizedBox(height: 24),
            _buildQuickReference(colors),
            const SizedBox(height: 24),
            _buildConduitFill(colors),
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
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'PV Wire Sizing Overview',
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
            'Proper wire sizing ensures safe operation and maximum efficiency. Wire must be sized for both ampacity (current carrying capacity) and voltage drop (power loss).',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildPrincipleRow(colors, 'Ampacity', 'Wire can safely carry the current without overheating'),
          _buildPrincipleRow(colors, 'Voltage Drop', 'Limit power loss to 2-3% for efficiency'),
          _buildPrincipleRow(colors, 'Temperature', 'Derate for high ambient or conduit fill'),
          _buildPrincipleRow(colors, 'Sunlight', 'USE-2 or PV Wire required for exposed DC'),
        ],
      ),
    );
  }

  Widget _buildPrincipleRow(ZaftoColors colors, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildWireTypes(ZaftoColors colors) {
    final types = [
      {
        'type': 'PV Wire',
        'rating': '90°C wet/dry, 2000V',
        'use': 'Exposed DC circuits, module interconnects',
        'notes': 'Sunlight resistant, flexible',
        'color': colors.accentSuccess,
      },
      {
        'type': 'USE-2',
        'rating': '90°C wet, 600V',
        'use': 'Underground, exposed DC',
        'notes': 'Sunlight resistant when marked',
        'color': colors.accentInfo,
      },
      {
        'type': 'THWN-2',
        'rating': '90°C wet, 600V',
        'use': 'In conduit only',
        'notes': 'NOT sunlight resistant',
        'color': colors.accentWarning,
      },
      {
        'type': 'XHHW-2',
        'rating': '90°C wet, 600V',
        'use': 'In conduit, some exposed OK',
        'notes': 'Check marking for sunlight',
        'color': colors.accentPrimary,
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
              Icon(LucideIcons.layers, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wire Types for PV Systems',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildWireTypeCard(colors, t)),
        ],
      ),
    );
  }

  Widget _buildWireTypeCard(ZaftoColors colors, Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (type['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: type['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type['type'] as String,
                  style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(type['rating'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(type['use'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(type['notes'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildAmpacityTable(ZaftoColors colors) {
    final data = [
      {'awg': '14', 'amp60': '15', 'amp75': '20', 'amp90': '25'},
      {'awg': '12', 'amp60': '20', 'amp75': '25', 'amp90': '30'},
      {'awg': '10', 'amp60': '30', 'amp75': '35', 'amp90': '40'},
      {'awg': '8', 'amp60': '40', 'amp75': '50', 'amp90': '55'},
      {'awg': '6', 'amp60': '55', 'amp75': '65', 'amp90': '75'},
      {'awg': '4', 'amp60': '70', 'amp75': '85', 'amp90': '95'},
      {'awg': '3', 'amp60': '85', 'amp75': '100', 'amp90': '115'},
      {'awg': '2', 'amp60': '95', 'amp75': '115', 'amp90': '130'},
      {'awg': '1', 'amp60': '110', 'amp75': '130', 'amp90': '145'},
      {'awg': '1/0', 'amp60': '125', 'amp75': '150', 'amp90': '170'},
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
              Icon(LucideIcons.table, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Copper Ampacity (NEC 310.16)',
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('AWG', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('60°C', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('75°C', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('90°C', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ...data.map((row) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(row['awg']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('${row['amp60']}A', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      Expanded(child: Text('${row['amp75']}A', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      Expanded(child: Text('${row['amp90']}A', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Values for ≤3 current-carrying conductors in raceway. Apply derating for more conductors or high ambient temperature.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageDropCalc(ZaftoColors colors) {
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
              Icon(LucideIcons.calculator, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voltage Drop Calculation',
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
VOLTAGE DROP FORMULA (DC Circuits)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vdrop = (2 × L × I × R) / 1000

Where:
  L = One-way length (feet)
  I = Current (amps)
  R = Resistance (ohms per 1000ft)

Wire Resistance (Copper @ 75°C):
  14 AWG = 3.14 Ω/kft
  12 AWG = 1.98 Ω/kft
  10 AWG = 1.24 Ω/kft
   8 AWG = 0.778 Ω/kft
   6 AWG = 0.491 Ω/kft
   4 AWG = 0.308 Ω/kft

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXAMPLE:
  Distance: 100 ft one-way
  Current: 10A
  Voltage: 300V DC
  Target: ≤2% drop (6V max)

  Using 10 AWG:
  Vdrop = (2 × 100 × 10 × 1.24) / 1000
        = 2.48V (0.83%) ✓ GOOD

  Using 12 AWG:
  Vdrop = (2 × 100 × 10 × 1.98) / 1000
        = 3.96V (1.32%) ✓ OK

  Using 14 AWG:
  Vdrop = (2 × 100 × 10 × 3.14) / 1000
        = 6.28V (2.1%) ✗ TOO HIGH''',
              style: TextStyle(
                color: colors.accentWarning,
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
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target ≤2% for DC circuits, ≤3% for AC circuits. Lower is better for system efficiency.',
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

  Widget _buildQuickReference(ZaftoColors colors) {
    final data = [
      {'amps': '10A', 'd50': '14', 'd100': '12', 'd150': '10', 'd200': '10'},
      {'amps': '15A', 'd50': '12', 'd100': '10', 'd150': '8', 'd200': '8'},
      {'amps': '20A', 'd50': '10', 'd100': '8', 'd150': '6', 'd200': '6'},
      {'amps': '30A', 'd50': '8', 'd100': '6', 'd150': '4', 'd200': '4'},
      {'amps': '40A', 'd50': '6', 'd100': '4', 'd150': '3', 'd200': '2'},
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
              Icon(LucideIcons.zap, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Wire Size Reference (2% Drop)',
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
            'For 300V DC string voltage - AWG copper',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('Current', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('50ft', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('100ft', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('150ft', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text('200ft', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ...data.map((row) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(row['amps']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('#${row['d50']}', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
                      Expanded(child: Text('#${row['d100']}', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
                      Expanded(child: Text('#${row['d150']}', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
                      Expanded(child: Text('#${row['d200']}', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConduitFill(ZaftoColors colors) {
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
              Icon(LucideIcons.circleDot, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conduit Fill & Derating',
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
              Expanded(child: _buildDeratingCard(colors, 'Conductors', '4-6: 80%\n7-9: 70%\n10-20: 50%', LucideIcons.plug)),
              const SizedBox(width: 12),
              Expanded(child: _buildDeratingCard(colors, 'Conduit Fill', '1 wire: 53%\n2 wires: 31%\n3+ wires: 40%', LucideIcons.circle)),
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
                Text('Temperature Correction (30°C base):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTempRow(colors, '31-35°C', '0.96'),
                _buildTempRow(colors, '36-40°C', '0.91'),
                _buildTempRow(colors, '41-45°C', '0.87'),
                _buildTempRow(colors, '46-50°C', '0.82'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeratingCard(ZaftoColors colors, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTempRow(ZaftoColors colors, String temp, String factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(temp, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('×$factor', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
