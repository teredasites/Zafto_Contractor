import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ElectrodeSelectionScreen extends ConsumerWidget {
  const ElectrodeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Electrode Selection',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStickElectrodes(colors),
            const SizedBox(height: 24),
            _buildMigWire(colors),
            const SizedBox(height: 24),
            _buildTigTungsten(colors),
            const SizedBox(height: 24),
            _buildFillerRods(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStickElectrodes(ZaftoColors colors) {
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Stick Electrode Codes (AWS)',
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
              '''ELECTRODE NUMBER SYSTEM

      E 70 1 8
      │  │  │ │
      │  │  │ └── Coating/Current type
      │  │  │     0 = DCEP only
      │  │  │     1 = All positions, DCEP
      │  │  │     2 = Flat/horizontal
      │  │  │     3 = Flat only
      │  │  │     4 = Iron powder
      │  │  │     5 = Low hydrogen, DCEP
      │  │  │     6 = Low hydrogen, AC/DCEP
      │  │  │     8 = Low hydrogen, iron powder
      │  │  │
      │  │  └──── Position capability
      │  │        1 = All positions
      │  │        2 = Flat & horizontal
      │  │        4 = Flat, horizontal, vertical down
      │  │
      │  └─────── Tensile strength (×1000 psi)
      │           60 = 60,000 psi
      │           70 = 70,000 psi
      │
      └────────── Electrode designation''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildElectrodeRow(colors, 'E6010', 'Deep penetration, all positions', 'DCEP'),
          _buildElectrodeRow(colors, 'E6011', 'Similar to 6010, AC capable', 'AC/DCEP'),
          _buildElectrodeRow(colors, 'E6013', 'Easy arc, light penetration', 'AC/DC'),
          _buildElectrodeRow(colors, 'E7018', 'Low hydrogen, smooth arc', 'AC/DCEP'),
          _buildElectrodeRow(colors, 'E7024', 'High deposition, flat/horiz', 'AC/DC'),
        ],
      ),
    );
  }

  Widget _buildElectrodeRow(ZaftoColors colors, String code, String use, String polarity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontFamily: 'monospace'), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(polarity, style: TextStyle(color: colors.accentInfo, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildMigWire(ZaftoColors colors) {
    final wires = [
      {'class': 'ER70S-3', 'use': 'General purpose, clean steel', 'gas': 'Ar/CO2'},
      {'class': 'ER70S-6', 'use': 'Most popular, dirty steel OK', 'gas': 'Ar/CO2'},
      {'class': 'E71T-1', 'use': 'Flux core, high deposition', 'gas': 'CO2'},
      {'class': 'E71T-11', 'use': 'Self-shielding flux core', 'gas': 'None'},
      {'class': 'ER308L', 'use': 'Stainless steel', 'gas': 'Ar/CO2'},
      {'class': 'ER4043', 'use': 'Aluminum (general)', 'gas': '100% Ar'},
      {'class': 'ER5356', 'use': 'Aluminum (structural)', 'gas': '100% Ar'},
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
              Icon(LucideIcons.plug, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'MIG Wire Classifications',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...wires.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 65,
                  child: Text(w['class']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                ),
                Expanded(
                  child: Text(w['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(w['gas']!, style: TextStyle(color: colors.accentWarning, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTigTungsten(ZaftoColors colors) {
    final tungstens = [
      {'type': 'Pure (Green)', 'use': 'AC aluminum, magnesium', 'material': 'W'},
      {'type': '2% Thoriated (Red)', 'use': 'DC steel, stainless', 'material': 'W+ThO2'},
      {'type': '2% Ceriated (Gray)', 'use': 'DC/AC all metals', 'material': 'W+CeO2'},
      {'type': '2% Lanthanated (Blue)', 'use': 'DC/AC all metals', 'material': 'W+La2O3'},
      {'type': 'Rare Earth (Purple)', 'use': 'DC/AC universal', 'material': 'Mixed'},
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
              Icon(LucideIcons.pencil, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'TIG Tungsten Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tungstens.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(t['type']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(t['use']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
                Text(t['material']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tungsten Sizing:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '1/16": 5-60A  |  3/32": 50-100A  |  1/8": 100-180A',
                  style: TextStyle(color: colors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillerRods(ZaftoColors colors) {
    final rods = [
      {'base': 'Mild Steel', 'filler': 'ER70S-2, ER70S-6', 'notes': 'Match or exceed base'},
      {'base': 'Stainless 304', 'filler': 'ER308L', 'notes': 'L = low carbon'},
      {'base': 'Stainless 316', 'filler': 'ER316L', 'notes': 'L = low carbon'},
      {'base': 'Aluminum 6061', 'filler': 'ER4043, ER5356', 'notes': '4043 softer, 5356 stronger'},
      {'base': 'Chrome-moly', 'filler': 'ER80S-D2', 'notes': 'Preheat required'},
      {'base': 'Cast Iron', 'filler': 'ENi-CI', 'notes': 'Nickel rod, low heat'},
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
              Icon(LucideIcons.gitBranch, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filler Metal Selection',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rods.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['base']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                    Text(r['filler']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
                Text(r['notes']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
