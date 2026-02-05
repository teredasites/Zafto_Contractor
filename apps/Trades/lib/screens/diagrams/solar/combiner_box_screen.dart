import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class CombinerBoxScreen extends ConsumerWidget {
  const CombinerBoxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'DC Combiner Box',
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
            _buildComponents(colors),
            const SizedBox(height: 24),
            _buildFuseSizing(colors),
            const SizedBox(height: 24),
            _buildInstallationTips(colors),
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
              Icon(LucideIcons.box, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Combiner Box Overview',
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
            'A DC combiner box consolidates multiple PV strings into a single output circuit feeding the inverter. It provides overcurrent protection, disconnect capability, and a convenient wiring junction point.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '2-24', 'String Inputs', LucideIcons.gitMerge)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, '600V', 'Max DC Voltage', LucideIcons.zap)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, 'NEMA 4X', 'Outdoor Rating', LucideIcons.shield)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String value, String label, IconData icon) {
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
          Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10), textAlign: TextAlign.center),
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
            'Combiner Box Internal Wiring',
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
FROM PV STRINGS
     │
     ▼
┌────────────────────────────────────────────────────┐
│              DC COMBINER BOX                       │
│                                                    │
│  STRING INPUTS (+ Side)                            │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │
│  │ S1+ │ │ S2+ │ │ S3+ │ │ S4+ │ │ S5+ │  (+)    │
│  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘         │
│     │      │      │      │      │               │
│  ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐         │
│  │FUSE │ │FUSE │ │FUSE │ │FUSE │ │FUSE │ 15A     │
│  │ 15A │ │ 15A │ │ 15A │ │ 15A │ │ 15A │ Touch   │
│  └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ Safe    │
│     │      │      │      │      │               │
│     └──────┴──────┴──┬───┴──────┴───┘            │
│                      │                           │
│              ┌───────┴───────┐                   │
│              │  POSITIVE     │                   │
│              │  BUS BAR      │                   │
│              └───────┬───────┘                   │
│                      │                           │
│  ┌───────────────────┼───────────────────────┐   │
│  │           DC DISCONNECT                   │   │
│  │        (Integral or External)             │   │
│  │              ┌─────┐                      │   │
│  │     (+) ─────┤     ├───── (+) OUT         │   │
│  │              │     │                      │   │
│  │     (-) ─────┤     ├───── (-) OUT         │   │
│  │              └─────┘                      │   │
│  └───────────────────────────────────────────┘   │
│                      │                           │
│              ┌───────┴───────┐                   │
│              │  NEGATIVE     │                   │
│              │  BUS BAR      │                   │
│              └───────┬───────┘                   │
│     ┌────────────────┼────────────────┐          │
│     │      │      │      │      │               │
│  ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐         │
│  │ S1- │ │ S2- │ │ S3- │ │ S4- │ │ S5- │  (-)    │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘         │
│                                                    │
│  ┌──────────────────────────────────────────┐     │
│  │  GROUND BAR (EGC from all strings)       │     │
│  │  ══════════════════════════════════      │     │
│  └──────────────────────────────────────────┘     │
│                      │                           │
│               SPD (Optional)                      │
│            Surge Protection                       │
│                                                    │
└────────────────────────────────────────────────────┘
     │
     ▼
TO INVERTER''',
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

  Widget _buildComponents(ZaftoColors colors) {
    final components = [
      {
        'name': 'String Fuses',
        'description': 'Overcurrent protection for each string. Prevents backfeed from parallel strings during fault.',
        'spec': '15A typical, 600V DC rated',
        'icon': LucideIcons.shield,
      },
      {
        'name': 'Bus Bars',
        'description': 'Copper bars that combine all positive and negative conductors respectively.',
        'spec': 'Sized for total combined current',
        'icon': LucideIcons.minus,
      },
      {
        'name': 'DC Disconnect',
        'description': 'Allows isolation of array from inverter. May be integral or external.',
        'spec': 'Load-break rated for DC',
        'icon': LucideIcons.toggleLeft,
      },
      {
        'name': 'Ground Bar',
        'description': 'Bonding point for all equipment grounding conductors from strings.',
        'spec': 'Copper, isolated from enclosure',
        'icon': LucideIcons.anchor,
      },
      {
        'name': 'Surge Protection (SPD)',
        'description': 'Protects against lightning-induced surges. Type 2 SPD common.',
        'spec': 'DC rated, MOV type',
        'icon': LucideIcons.zap,
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
                'Key Components',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...components.map((c) => _buildComponentCard(colors, c)),
        ],
      ),
    );
  }

  Widget _buildComponentCard(ZaftoColors colors, Map<String, dynamic> comp) {
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
          Icon(comp['icon'] as IconData, color: colors.accentSuccess, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(comp['description'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(comp['spec'] as String, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuseSizing(ZaftoColors colors) {
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
                'String Fuse Sizing (NEC 690.9)',
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
FUSE SIZING CALCULATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Maximum Series Fuse Rating
  Fuse ≤ Module Series Fuse Rating
  (From module spec sheet, typically 15-20A)

Step 2: Minimum Fuse Rating
  Fuse ≥ 1.56 × Isc (Short Circuit Current)

  Why 1.56?
  • 1.25 for continuous current (NEC 690.8)
  • × 1.25 for additional margin
  • = 1.56 total multiplier

Example:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Module Isc = 10.5A
  Module Max Series Fuse = 20A

  Min Fuse = 10.5 × 1.56 = 16.4A

  Select: 20A fuse (≥16.4A, ≤20A)

When Fuses NOT Required:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • Single string systems
  • Two strings if Isc ≤ Module Iocpd''',
              style: TextStyle(
                color: colors.accentWarning,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
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
                    'Fuses must be DC-rated for system voltage. Standard AC fuses will NOT safely interrupt DC arcs.',
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

  Widget _buildInstallationTips(ZaftoColors colors) {
    final tips = [
      {'tip': 'Mount in accessible location for maintenance', 'icon': LucideIcons.mapPin},
      {'tip': 'Use strain relief on all cable entries', 'icon': LucideIcons.grip},
      {'tip': 'Label all string inputs clearly', 'icon': LucideIcons.tag},
      {'tip': 'Torque all terminals to spec', 'icon': LucideIcons.wrench},
      {'tip': 'Verify polarity before energizing', 'icon': LucideIcons.plusCircle},
      {'tip': 'Install with disconnect in OFF position', 'icon': LucideIcons.powerOff},
      {'tip': 'Seal unused knockouts for NEMA rating', 'icon': LucideIcons.circle},
      {'tip': 'Provide clearance per NEC 110.26', 'icon': LucideIcons.ruler},
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
              Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 20),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tips.map((t) => Container(
              width: MediaQuery.of(colors as BuildContext? ?? WidgetsBinding.instance.rootElement!.findRenderObject()!.paintBounds.size as BuildContext).size.width / 2 - 28,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t['icon'] as IconData, color: colors.accentInfo, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t['tip'] as String,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
