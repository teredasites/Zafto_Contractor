import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class WaterChemistryScreen extends ConsumerWidget {
  const WaterChemistryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Water Chemistry',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChemicalBalance(colors),
            const SizedBox(height: 24),
            _buildSanitizers(colors),
            const SizedBox(height: 24),
            _buildChemicalAdjustments(colors),
            const SizedBox(height: 24),
            _buildTroubleshooting(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalBalance(ZaftoColors colors) {
    final parameters = [
      {'param': 'Free Chlorine', 'pool': '1-3 ppm', 'spa': '3-5 ppm', 'status': 'critical'},
      {'param': 'pH', 'pool': '7.2-7.6', 'spa': '7.2-7.6', 'status': 'critical'},
      {'param': 'Total Alkalinity', 'pool': '80-120 ppm', 'spa': '80-120 ppm', 'status': 'important'},
      {'param': 'Calcium Hardness', 'pool': '200-400 ppm', 'spa': '150-250 ppm', 'status': 'important'},
      {'param': 'Cyanuric Acid', 'pool': '30-50 ppm', 'spa': '30-50 ppm', 'status': 'normal'},
      {'param': 'Total Dissolved Solids', 'pool': '<1500 ppm', 'spa': '<1500 ppm', 'status': 'normal'},
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
              Icon(LucideIcons.flaskConical, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Chemical Balance Ranges',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: Text('Parameter', style: TextStyle(color: colors.textTertiary, fontSize: 10))),
              Expanded(flex: 2, child: Text('Pool', style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Spa', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          ...parameters.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
              border: p['status'] == 'critical'
                  ? Border.all(color: colors.accentError.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      if (p['status'] == 'critical')
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(LucideIcons.alertCircle, color: colors.accentError, size: 12),
                        ),
                      Expanded(
                        child: Text(p['param']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(p['pool']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                Expanded(flex: 2, child: Text(p['spa']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
              ],
            ),
          )),
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
                    'Test water 2-3x weekly. Chlorine and pH are most critical for safety.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanitizers(ZaftoColors colors) {
    final sanitizers = [
      {
        'type': 'Liquid Chlorine',
        'strength': '10-12.5%',
        'pros': 'Fast acting, no CYA',
        'cons': 'Short shelf life, raises pH',
      },
      {
        'type': 'Cal-Hypo (granular)',
        'strength': '65-73%',
        'pros': 'Strong, stable',
        'cons': 'Adds calcium, cloudy initially',
      },
      {
        'type': 'Dichlor (granular)',
        'strength': '56-62%',
        'pros': 'pH neutral, dissolves fast',
        'cons': 'Adds CYA, more expensive',
      },
      {
        'type': 'Trichlor (tablets)',
        'strength': '90%',
        'pros': 'Slow release, convenient',
        'cons': 'Adds CYA, very acidic',
      },
      {
        'type': 'Salt Chlorinator',
        'strength': 'Generates Cl',
        'pros': 'Consistent, soft water',
        'cons': 'High upfront cost, cell replacement',
      },
      {
        'type': 'Bromine',
        'strength': '61%',
        'pros': 'Best for spas, stable at high temps',
        'cons': 'More expensive, slower acting',
      },
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
              Icon(LucideIcons.shield, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sanitizer Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sanitizers.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['type']!, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentInfo.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s['strength']!, style: TextStyle(color: colors.accentInfo, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.plus, color: colors.accentSuccess, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['pros']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.minus, color: colors.accentError, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(s['cons']!, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChemicalAdjustments(ZaftoColors colors) {
    final adjustments = [
      {'issue': 'Raise pH', 'chemical': 'Soda Ash', 'dose': '6 oz per 10,000 gal raises 0.2'},
      {'issue': 'Lower pH', 'chemical': 'Muriatic Acid', 'dose': '1 qt per 10,000 gal lowers 0.2'},
      {'issue': 'Raise Alkalinity', 'chemical': 'Baking Soda', 'dose': '1.5 lb per 10,000 gal raises 10 ppm'},
      {'issue': 'Lower Alkalinity', 'chemical': 'Muriatic Acid', 'dose': 'Aerate after to raise pH back'},
      {'issue': 'Raise Calcium', 'chemical': 'Calcium Chloride', 'dose': '1.25 lb per 10,000 gal raises 10 ppm'},
      {'issue': 'Raise CYA', 'chemical': 'Stabilizer', 'dose': '13 oz per 10,000 gal raises 10 ppm'},
      {'issue': 'Shock Treatment', 'chemical': 'Cal-Hypo', 'dose': '1 lb per 10,000 gal = 10 ppm FC'},
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
              Icon(LucideIcons.settings, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chemical Adjustments',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...adjustments.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 85,
                  child: Text(a['issue']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 80,
                  child: Text(a['chemical']!, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
                Expanded(
                  child: Text(a['dose']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
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
      {
        'problem': 'Green/Cloudy Water',
        'cause': 'Algae growth, low chlorine',
        'fix': 'Shock to 30 ppm, brush, filter 24hr',
      },
      {
        'problem': 'Burning Eyes',
        'cause': 'Combined chlorine (chloramines)',
        'fix': 'Shock to breakpoint (10x CC)',
      },
      {
        'problem': 'Scale Buildup',
        'cause': 'High calcium, high pH',
        'fix': 'Lower pH, add sequestrant',
      },
      {
        'problem': 'Staining',
        'cause': 'Metals (iron, copper)',
        'fix': 'Add metal sequestrant, filter',
      },
      {
        'problem': 'Foaming (Spa)',
        'cause': 'Body oils, detergents',
        'fix': 'Add defoamer, drain if persistent',
      },
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
              Icon(LucideIcons.wrench, color: colors.accentSuccess, size: 20),
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
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['problem']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.helpCircle, color: colors.textTertiary, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(i['cause']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 12),
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
