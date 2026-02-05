import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class WeldingProcessesScreen extends ConsumerWidget {
  const WeldingProcessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Welding Processes',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMigWelding(colors),
            const SizedBox(height: 24),
            _buildTigWelding(colors),
            const SizedBox(height: 24),
            _buildStickWelding(colors),
            const SizedBox(height: 24),
            _buildProcessComparison(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildMigWelding(ZaftoColors colors) {
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
                'MIG (GMAW)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gas Metal Arc Welding',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
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
              '''MIG TORCH CROSS-SECTION

        GAS NOZZLE
         ┌─────┐
         │     │ ← Shielding gas
         │  ○  │   (Ar/CO2 mix)
         │  │  │
         │  │  │ ← Contact tip
         │  ◯  │   (consumable wire)
         │╱ │ ╲│
         ▼  ▼  ▼
      ════════════
         WELD POOL
      ════════════
        WORKPIECE

Wire feed: Continuous
Shielding: External gas
Polarity: DCEP (usually)
Deposition: High''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildProcessNote(colors, 'Best for', 'Mild steel, aluminum, stainless'),
          _buildProcessNote(colors, 'Thickness', '24 ga to unlimited'),
          _buildProcessNote(colors, 'Position', 'All positions with proper settings'),
          _buildProcessNote(colors, 'Skill level', 'Easiest to learn'),
        ],
      ),
    );
  }

  Widget _buildTigWelding(ZaftoColors colors) {
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
              Icon(LucideIcons.sparkles, color: colors.accentInfo, size: 24),
              const SizedBox(width: 12),
              Text(
                'TIG (GTAW)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gas Tungsten Arc Welding',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
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
              '''TIG TORCH SETUP

      TORCH BODY
        ┌───┐
        │   │ ← Argon gas
        │   │
       ┌┴───┴┐
       │     │ ← Ceramic cup
       │  │  │
       │  │  │ ← Tungsten electrode
       │  ▼  │   (non-consumable)
       └──●──┘
          ★ ← Arc
      ════════════
          ↗ Filler rod
            (added by hand)
      ════════════
        WORKPIECE

Foot pedal: Amp control
Shielding: 100% Argon
Filler: Added separately''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildProcessNote(colors, 'Best for', 'Thin materials, precision work'),
          _buildProcessNote(colors, 'Thickness', '0.005" to 1/4" typical'),
          _buildProcessNote(colors, 'Metals', 'All weldable metals'),
          _buildProcessNote(colors, 'Skill level', 'Highest skill required'),
        ],
      ),
    );
  }

  Widget _buildStickWelding(ZaftoColors colors) {
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
              Icon(LucideIcons.flame, color: colors.accentWarning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Stick (SMAW)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Shielded Metal Arc Welding',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
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
              '''STICK ELECTRODE

     ELECTRODE HOLDER
          ┌───┐
          │   │
          └─┬─┘
            │
      ╔═════╪═════╗
      ║  FLUX     ║ ← Coating creates
      ║  COATING  ║   shielding gas
      ║     │     ║   and slag
      ║     │     ║
      ║     │     ║ ← Metal core
      ║     │     ║   (consumable)
      ╚═════╪═════╝
            ★ ← Arc
        ░░░░░░░░░░░ ← Slag (remove)
      ════════════════
          WELD METAL
      ════════════════
         WORKPIECE''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildProcessNote(colors, 'Best for', 'Outdoor, dirty/rusty metal'),
          _buildProcessNote(colors, 'Thickness', '1/8" and up'),
          _buildProcessNote(colors, 'Position', 'All positions'),
          _buildProcessNote(colors, 'Skill level', 'Moderate'),
        ],
      ),
    );
  }

  Widget _buildProcessNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessComparison(ZaftoColors colors) {
    final comparison = [
      {'factor': 'Speed', 'mig': 'Fast', 'tig': 'Slow', 'stick': 'Medium'},
      {'factor': 'Clean up', 'mig': 'Minimal', 'tig': 'None', 'stick': 'Slag removal'},
      {'factor': 'Outdoor use', 'mig': 'Poor', 'tig': 'Poor', 'stick': 'Excellent'},
      {'factor': 'Appearance', 'mig': 'Good', 'tig': 'Best', 'stick': 'Fair'},
      {'factor': 'Thin metal', 'mig': 'Good', 'tig': 'Best', 'stick': 'Poor'},
      {'factor': 'Thick metal', 'mig': 'Good', 'tig': 'Fair', 'stick': 'Best'},
      {'factor': 'Cost', 'mig': 'Medium', 'tig': 'High', 'stick': 'Low'},
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
              Icon(LucideIcons.gitCompare, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Process Comparison',
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
              Expanded(flex: 2, child: Text('Factor', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(child: Text('MIG', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('TIG', style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('Stick', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          ...comparison.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(c['factor']!, style: TextStyle(color: colors.textPrimary, fontSize: 10))),
                Expanded(child: Text(c['mig']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(child: Text(c['tig']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(child: Text(c['stick']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
