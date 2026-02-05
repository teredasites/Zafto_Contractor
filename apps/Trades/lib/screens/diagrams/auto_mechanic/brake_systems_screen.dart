import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class BrakeSystemsScreen extends ConsumerWidget {
  const BrakeSystemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Brake Systems',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHydraulicSystem(colors),
            const SizedBox(height: 24),
            _buildDiscBrakes(colors),
            const SizedBox(height: 24),
            _buildDrumBrakes(colors),
            const SizedBox(height: 24),
            _buildBrakeSpecs(colors),
            const SizedBox(height: 24),
            _buildTroubleshooting(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHydraulicSystem(ZaftoColors colors) {
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
              Icon(LucideIcons.circle, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Hydraulic Brake System',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
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
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''BRAKE HYDRAULIC LAYOUT

              MASTER CYLINDER
    ┌─────────────┴─────────────┐
    │    ┌───────────────┐      │
    │    │ BRAKE BOOSTER │      │
    │    └───────┬───────┘      │
    │            │              │
    │      ┌─────┴─────┐        │
    │      │  MASTER   │        │
    │      │ CYLINDER  │        │
    │      └─────┬─────┘        │
    │    ────────┼────────      │
    │   │        │        │     │
    │   ▼        ▼        ▼     │
    │ ┌───┐   ┌───┐   ┌───┐     │
    │ │ LF│   │ RF│   │REAR│    │
    └─┴───┴───┴───┴───┴───┴─────┘

Dual diagonal system:
• LF + RR on one circuit
• RF + LR on other circuit
• If one fails, other still works''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSystemNote(colors, 'Brake fluid', 'DOT 3, 4, or 5.1 (not DOT 5)'),
          _buildSystemNote(colors, 'Boiling point', 'DOT 3: 401°F, DOT 4: 446°F'),
          _buildSystemNote(colors, 'Change interval', 'Every 2-3 years (hygroscopic)'),
        ],
      ),
    );
  }

  Widget _buildSystemNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscBrakes(ZaftoColors colors) {
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
              Icon(LucideIcons.disc, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Disc Brake Components',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''DISC BRAKE ASSEMBLY (Top View)

         ←── Wheel rotation
    ┌─────────────────────────┐
    │                         │
    │    ┌───────────────┐    │
    │    │   CALIPER     │    │
    │    │   ┌─────┐     │    │
    │    │   │PADS │     │    │ ← Piston pushes
    │ ══════════════════════  │   pads against
    │    │   │PADS │     │    │   rotor
    │    │   └─────┘     │    │
    │    │   (inner)     │    │
    │    └───────────────┘    │
    │                         │
    │         ROTOR           │
    │   (spins with wheel)    │
    └─────────────────────────┘

CALIPER TYPES:
• Floating: Single piston, slides
• Fixed: Pistons both sides''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDiscComponent(colors, 'Rotor', 'Min thickness stamped on rotor'),
          _buildDiscComponent(colors, 'Pads', 'Replace at 2-3mm remaining'),
          _buildDiscComponent(colors, 'Caliper', 'Inspect for leaks, seized pistons'),
          _buildDiscComponent(colors, 'Slide pins', 'Clean and lube with silicone'),
          _buildDiscComponent(colors, 'Hardware', 'Replace clips, shims each service'),
        ],
      ),
    );
  }

  Widget _buildDiscComponent(ZaftoColors colors, String part, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(part, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrumBrakes(ZaftoColors colors) {
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
              Icon(LucideIcons.circle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Drum Brake Components',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''DRUM BRAKE ASSEMBLY (Inside View)

    ┌─────────────────────────────┐
    │        WHEEL CYLINDER       │
    │         ┌─────┐             │
    │        ╱│     │╲            │
    │       ╱ └─────┘ ╲           │
    │      ╱           ╲          │
    │    ┌┘             └┐        │
    │    │ PRIMARY SHOE │         │
    │    │   (front)    │         │
    │    │              │ SECONDARY
    │    │              │  SHOE   │
    │    └┐             ┌┘(rear)  │
    │     ╲    ★       ╱          │
    │      ╲ adjuster ╱           │
    │       ╲       ╱             │
    │        └─────┘              │
    │    ANCHOR     SPRINGS       │
    └─────────────────────────────┘

★ = Self-adjuster (backing up)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Drum shoes: Leading (front) does more work, trailing (rear) for parking brake. Replace as a set.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrakeSpecs(ZaftoColors colors) {
    final specs = [
      {'item': 'Pad friction material', 'min': '2mm (1/16")', 'replace': 'At wear indicator'},
      {'item': 'Rotor thickness', 'min': 'Stamped on rotor', 'replace': 'Below min or scored'},
      {'item': 'Rotor runout', 'min': '0.001-0.003"', 'replace': 'If exceeds spec'},
      {'item': 'Drum diameter', 'min': 'Stamped on drum', 'replace': 'If exceeds max'},
      {'item': 'Shoe lining', 'min': '1/16" (1.5mm)', 'replace': 'At rivets/backing'},
      {'item': 'Brake hose', 'min': 'No cracks', 'replace': 'If swollen or cracked'},
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
              Icon(LucideIcons.ruler, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Service Specifications',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...specs.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(s['item']!, style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                ),
                Expanded(
                  child: Text(s['min']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                Expanded(
                  child: Text(s['replace']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
    final issues = [
      {'symptom': 'Spongy pedal', 'cause': 'Air in lines, worn master', 'fix': 'Bleed brakes, inspect'},
      {'symptom': 'Pulls to side', 'cause': 'Stuck caliper, uneven pads', 'fix': 'Free caliper, replace pads'},
      {'symptom': 'Pulsating pedal', 'cause': 'Warped rotor', 'fix': 'Machine or replace rotor'},
      {'symptom': 'Grinding noise', 'cause': 'Worn pads (metal on metal)', 'fix': 'Replace pads and rotors'},
      {'symptom': 'Squealing', 'cause': 'Wear indicator, glazed pads', 'fix': 'Inspect/replace pads'},
      {'symptom': 'Hard pedal', 'cause': 'Booster failure, vacuum leak', 'fix': 'Check booster/vacuum'},
      {'symptom': 'Low pedal', 'cause': 'Worn pads, leak, adjustment', 'fix': 'Inspect system'},
    ];

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
              Icon(LucideIcons.alertCircle, color: colors.accentError, size: 20),
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
          ...issues.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['symptom']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.helpCircle, color: colors.textTertiary, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(i['cause']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
                Row(
                  children: [
                    Icon(LucideIcons.wrench, color: colors.accentSuccess, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(i['fix']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
