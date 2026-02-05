import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PoolElectricalScreen extends ConsumerWidget {
  const PoolElectricalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Pool Electrical',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNecRequirements(colors),
            const SizedBox(height: 24),
            _buildBondingDiagram(colors),
            const SizedBox(height: 24),
            _buildEquipmentLoads(colors),
            const SizedBox(height: 24),
            _buildSafetyDistances(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNecRequirements(ZaftoColors colors) {
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
                'NEC Article 680 Requirements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeItem(colors, '680.21', 'Motors', 'Branch circuit sized per motor nameplate'),
          _buildCodeItem(colors, '680.22', 'Lighting', 'GFCI protected, min 12V underwater'),
          _buildCodeItem(colors, '680.23', 'Underwater', 'Max 150V, transformer required'),
          _buildCodeItem(colors, '680.25', 'Feeders', 'Equipment grounding conductor required'),
          _buildCodeItem(colors, '680.26', 'Bonding', 'All metal parts bonded together'),
          _buildCodeItem(colors, '680.42', 'Spas', 'All outlets GFCI, 50A 240V typical'),
          _buildCodeItem(colors, '680.44', 'Bonding (Spa)', '#8 AWG solid copper minimum'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ALL pool/spa circuits must be GFCI protected. No exceptions.',
                    style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeItem(ZaftoColors colors, String section, String topic, String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(section, style: TextStyle(color: colors.accentPrimary, fontSize: 9, fontFamily: 'monospace'), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(topic, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(requirement, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildBondingDiagram(ZaftoColors colors) {
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
              Icon(LucideIcons.link, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Equipotential Bonding',
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
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''POOL BONDING DIAGRAM (NEC 680.26)

                    TO PANEL
                       │
                       │ #8 AWG Cu
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
    │    BONDING GRID  │                  │
    │    ════════════════════════         │
    │         │    │    │    │            │
    │    ┌────┴────┴────┴────┴────┐       │
    │    │                        │       │
    │    │      POOL SHELL        │       │
    │    │   ┌────────────────┐   │       │
    │    │   │ REBAR GRID     │   │       │
    │    │   │ (tied together)│   │       │
    │    │   └───────┬────────┘   │       │
    │    │           │            │       │
    │    └───────────│────────────┘       │
    │                │                    │
    └────────────────┼────────────────────┘
                     │
    BOND THESE ITEMS:│
    ─────────────────┼─────────────────────
    │    │    │      │     │    │    │
    ▼    ▼    ▼      ▼     ▼    ▼    ▼
   PUMP HEATER LIGHT LADDER RAILS METAL DECK
   MOTOR              HANDRAILS   WITHIN 5'

ALL connections: #8 AWG solid copper
Listed pressure connectors only''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildBondingNote(colors, 'Purpose', 'Equalize voltage potential, prevent shock'),
          _buildBondingNote(colors, 'Wire', '#8 AWG solid copper, insulated or bare'),
          _buildBondingNote(colors, 'Rebar', 'Tie all together, 1 connection to grid'),
          _buildBondingNote(colors, 'Perimeter', 'Within 18" of water, around entire pool'),
        ],
      ),
    );
  }

  Widget _buildBondingNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 6),
          SizedBox(
            width: 65,
            child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentLoads(ZaftoColors colors) {
    final loads = [
      {'equipment': 'Pool Pump (1.5 HP)', 'voltage': '240V', 'amps': '10A', 'breaker': '20A', 'wire': '#12'},
      {'equipment': 'Pool Pump (2 HP)', 'voltage': '240V', 'amps': '12A', 'breaker': '20A', 'wire': '#12'},
      {'equipment': 'Variable Speed Pump', 'voltage': '240V', 'amps': '8-15A', 'breaker': '20A', 'wire': '#12'},
      {'equipment': 'Gas Heater', 'voltage': '120V', 'amps': '3A', 'breaker': '15A', 'wire': '#14'},
      {'equipment': 'Heat Pump', 'voltage': '240V', 'amps': '20-30A', 'breaker': '40A', 'wire': '#8'},
      {'equipment': 'Salt Cell', 'voltage': '240V', 'amps': '5A', 'breaker': '20A', 'wire': '#12'},
      {'equipment': 'Pool Light', 'voltage': '12V', 'amps': '5A', 'breaker': '15A', 'wire': '#14'},
      {'equipment': 'Spa Pack', 'voltage': '240V', 'amps': '40-50A', 'breaker': '50-60A', 'wire': '#6'},
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
              Icon(LucideIcons.plug, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Equipment Electrical Loads',
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
              Expanded(flex: 3, child: Text('Equipment', style: TextStyle(color: colors.textTertiary, fontSize: 9))),
              Expanded(child: Text('Volts', style: TextStyle(color: colors.textTertiary, fontSize: 9))),
              Expanded(child: Text('Amps', style: TextStyle(color: colors.textTertiary, fontSize: 9))),
              Expanded(child: Text('Brkr', style: TextStyle(color: colors.textTertiary, fontSize: 9))),
              Expanded(child: Text('Wire', style: TextStyle(color: colors.textTertiary, fontSize: 9))),
            ],
          ),
          const SizedBox(height: 8),
          ...loads.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(l['equipment']!, style: TextStyle(color: colors.textPrimary, fontSize: 9))),
                Expanded(child: Text(l['voltage']!, style: TextStyle(color: colors.accentInfo, fontSize: 9))),
                Expanded(child: Text(l['amps']!, style: TextStyle(color: colors.textSecondary, fontSize: 9))),
                Expanded(child: Text(l['breaker']!, style: TextStyle(color: colors.accentWarning, fontSize: 9))),
                Expanded(child: Text(l['wire']!, style: TextStyle(color: colors.textTertiary, fontSize: 9))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'All circuits require GFCI protection. Equipment grounding conductor required in all conduits. Use wet-rated wire (THWN) or liquid-tight conduit.',
              style: TextStyle(color: colors.textSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDistances(ZaftoColors colors) {
    final distances = [
      {'item': 'Receptacles (pool)', 'distance': '6-20 ft from water', 'note': 'GFCI required'},
      {'item': 'Receptacles (spa)', 'distance': '6-10 ft from water', 'note': 'GFCI required'},
      {'item': 'Light switch', 'distance': '5 ft minimum', 'note': 'From water edge'},
      {'item': 'Overhead wires', 'distance': '22.5 ft above water', 'note': 'Horizontal clearance'},
      {'item': 'Equipment', 'distance': '5 ft from water', 'note': 'Unless separated by barrier'},
      {'item': 'Underground wiring', 'distance': '5 ft from pool', 'note': 'In rigid conduit'},
      {'item': 'Junction boxes', 'distance': '4 ft from water', 'note': '8" above water level'},
      {'item': 'Underwater lights', 'distance': '18" below water', 'note': 'Minimum depth'},
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
              Icon(LucideIcons.ruler, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Safety Clearances (NEC)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...distances.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(d['item']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(d['distance']!, style: TextStyle(color: colors.accentSuccess, fontSize: 9), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(d['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
