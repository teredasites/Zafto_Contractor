import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class GroundingBondingScreen extends ConsumerWidget {
  const GroundingBondingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'PV Grounding & Bonding',
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
            _buildGroundingDiagram(colors),
            const SizedBox(height: 24),
            _buildGroundingTypes(colors),
            const SizedBox(height: 24),
            _buildBondingMethods(colors),
            const SizedBox(height: 24),
            _buildWireSizing(colors),
            const SizedBox(height: 24),
            _buildGFPRequirements(colors),
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
              Icon(LucideIcons.anchor, color: colors.accentSuccess, size: 24),
              const SizedBox(width: 12),
              Text(
                'Grounding & Bonding Overview',
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
            'Proper grounding and bonding protects against electrical shock, equipment damage, and fire hazards. NEC Article 690 Part V covers PV system grounding requirements.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildDefinitionRow(colors, 'Grounding', 'Connecting current-carrying conductors to earth'),
          _buildDefinitionRow(colors, 'Bonding', 'Connecting non-current-carrying metal parts together'),
          _buildDefinitionRow(colors, 'GEC', 'Grounding Electrode Conductor - connects to earth'),
          _buildDefinitionRow(colors, 'EGC', 'Equipment Grounding Conductor - fault current path'),
        ],
      ),
    );
  }

  Widget _buildDefinitionRow(ZaftoColors colors, String term, String definition) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              term,
              style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(definition, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingDiagram(ZaftoColors colors) {
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
            'PV System Grounding Diagram',
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
┌────────────────────────────────────────────────────────┐
│                    PV ARRAY                            │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│   │  Module  │  │  Module  │  │  Module  │            │
│   │  Frame   │  │  Frame   │  │  Frame   │            │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│        │             │             │                   │
│        └─────────────┼─────────────┘                   │
│                      │ EGC (Equipment Bonding)         │
│   ┌──────────────────┴──────────────────────┐         │
│   │            RACKING SYSTEM               │         │
│   │     (Bonded with WEEB or Lug)           │         │
│   └──────────────────┬──────────────────────┘         │
└──────────────────────┼─────────────────────────────────┘
                       │ EGC to Inverter
                       ▼
           ┌───────────────────────┐
           │      INVERTER         │
           │  ┌─────────────────┐  │
           │  │ DC+ ──┬── AC L1 │  │
           │  │       │         │  │
           │  │ DC- ──┴── AC L2 │  │
           │  │       │         │  │
           │  │ GND ──┴── AC N  │  │
           │  └─────────────────┘  │
           │    Grounding Point    │
           └───────────┬───────────┘
                       │ EGC
                       ▼
           ┌───────────────────────┐
           │    MAIN PANEL         │
           │  ┌─────────────────┐  │
           │  │ Main Bonding    │  │
           │  │ Jumper (MBJ)    │  │
           │  │                 │  │
           │  │ Neutral Bar ────┼──┼── To Utility
           │  │      │          │  │
           │  │ Ground Bar ─────┼──┼── EGC from Inverter
           │  └─────────────────┘  │
           └───────────┬───────────┘
                       │ GEC
                       ▼
           ┌───────────────────────┐
           │  GROUNDING ELECTRODE  │
           │  ┌─────────────────┐  │
           │  │ Ground Rod(s)  │  │
           │  │ 8ft min depth   │  │
           │  │ ≤25Ω resistance │  │
           │  └─────────────────┘  │
           └───────────────────────┘''',
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

  Widget _buildGroundingTypes(ZaftoColors colors) {
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
              Icon(LucideIcons.gitBranch, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'System Grounding Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGroundingTypeCard(
            colors,
            'Grounded Systems',
            'One conductor (usually negative) connected to ground',
            ['Traditional string inverters', 'Requires GFDI protection', 'NEC 690.41(A)'],
            colors.accentSuccess,
          ),
          const SizedBox(height: 12),
          _buildGroundingTypeCard(
            colors,
            'Ungrounded Systems',
            'Neither DC conductor connected to ground (floating)',
            ['Most modern inverters', 'Requires GFP per 690.41(B)', 'Safer for firefighters'],
            colors.accentInfo,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentWarning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Most residential inverters today use ungrounded (transformerless) topology for higher efficiency.',
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

  Widget _buildGroundingTypeCard(ZaftoColors colors, String title, String description, List<String> points, Color accentColor) {
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
          Text(description, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(LucideIcons.check, color: accentColor, size: 14),
                const SizedBox(width: 8),
                Text(p, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBondingMethods(ZaftoColors colors) {
    final methods = [
      {
        'name': 'WEEB (Washer Equipment Bonding)',
        'description': 'Self-grounding washer under module bolt pierces anodized coating',
        'pros': ['Quick installation', 'UL listed', 'Most common method'],
        'icon': LucideIcons.circle,
      },
      {
        'name': 'Lay-In Lugs',
        'description': 'Compression lug attached to frame with drilled hole',
        'pros': ['Reliable connection', 'Inspectable', 'Works with any frame'],
        'icon': LucideIcons.link,
      },
      {
        'name': 'Grounding Clips',
        'description': 'Spring clips that bite into rail/frame edge',
        'pros': ['No drilling required', 'Fast installation', 'Rail-specific'],
        'icon': LucideIcons.paperclip,
      },
      {
        'name': 'Bonding Jumpers',
        'description': 'Braided copper straps between components',
        'pros': ['Flexible', 'Visible bond', 'For expansion joints'],
        'icon': LucideIcons.plug,
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
              Icon(LucideIcons.link2, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Module Bonding Methods',
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(method['icon'] as IconData, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Text(
                method['name'] as String,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(method['description'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (method['pros'] as List<String>).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p, style: TextStyle(color: colors.accentSuccess, fontSize: 10)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWireSizing(ZaftoColors colors) {
    final sizes = [
      {'system': '≤2 kW', 'egc': '14 AWG', 'gec': '8 AWG'},
      {'system': '2-4 kW', 'egc': '12 AWG', 'gec': '8 AWG'},
      {'system': '4-7 kW', 'egc': '10 AWG', 'gec': '6 AWG'},
      {'system': '7-10 kW', 'egc': '8 AWG', 'gec': '6 AWG'},
      {'system': '10-15 kW', 'egc': '6 AWG', 'gec': '4 AWG'},
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
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Grounding Conductor Sizing',
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
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('System Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('EGC Min', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text('GEC Min', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                ),
                ...sizes.map((s) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(s['system']!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      Expanded(child: Text(s['egc']!, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(child: Text(s['gec']!, style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Per NEC 250.122 (EGC) and 250.166 (GEC). Use copper conductors. Increase size for long runs.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildGFPRequirements(ZaftoColors colors) {
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
              Icon(LucideIcons.shieldAlert, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ground Fault Protection (NEC 690.41)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGFPItem(colors, 'GFDI (Ground Fault Detector/Interrupter)',
            'Required for grounded systems. Detects current flow to ground and disconnects.', 'Grounded Systems'),
          _buildGFPItem(colors, 'GFP (Ground Fault Protection)',
            'Required for ungrounded systems. Monitors for ground faults and indicates/disconnects.', 'Ungrounded Systems'),
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
                Text('When GFP Trips:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTroubleshootStep(colors, '1', 'Check for water intrusion in junction boxes'),
                _buildTroubleshootStep(colors, '2', 'Inspect conductor insulation for damage'),
                _buildTroubleshootStep(colors, '3', 'Verify no conductor contact with frames'),
                _buildTroubleshootStep(colors, '4', 'Test insulation resistance with megger'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGFPItem(ZaftoColors colors, String title, String description, String applies) {
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
              Icon(LucideIcons.shield, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(applies, style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootStep(ZaftoColors colors, String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.accentInfo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step, style: TextStyle(color: colors.bgBase, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
