import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Demand Calculator - Design System v2.6
///
/// Calculates total building water demand based on fixture count.
/// Determines peak demand and service sizing requirements.
///
/// References: IPC 2024 Appendix E, Hunter's Curve
class WaterDemandScreen extends ConsumerStatefulWidget {
  const WaterDemandScreen({super.key});
  @override
  ConsumerState<WaterDemandScreen> createState() => _WaterDemandScreenState();
}

class _WaterDemandScreenState extends ConsumerState<WaterDemandScreen> {
  // Fixture counts
  Map<String, int> _fixtures = {
    'wc_flush_tank': 2,
    'wc_flush_valve': 0,
    'urinal': 0,
    'lavatory': 2,
    'kitchen_sink': 1,
    'shower': 2,
    'bathtub': 1,
    'dishwasher': 1,
    'washing_machine': 1,
    'hose_bib': 1,
  };

  // Building type affects demand factor
  String _buildingType = 'residential';

  // Fixture unit values and GPM per IPC
  static const Map<String, ({double wsfu, double gpm, String desc})> _fixtureData = {
    'wc_flush_tank': (wsfu: 2.2, gpm: 3.0, desc: 'Toilet (Tank)'),
    'wc_flush_valve': (wsfu: 10.0, gpm: 25.0, desc: 'Toilet (Flush Valve)'),
    'urinal': (wsfu: 5.0, gpm: 15.0, desc: 'Urinal (Flush Valve)'),
    'lavatory': (wsfu: 1.0, gpm: 2.0, desc: 'Bathroom Sink'),
    'kitchen_sink': (wsfu: 1.5, gpm: 2.5, desc: 'Kitchen Sink'),
    'shower': (wsfu: 2.0, gpm: 2.5, desc: 'Shower'),
    'bathtub': (wsfu: 2.0, gpm: 4.0, desc: 'Bathtub'),
    'dishwasher': (wsfu: 1.5, gpm: 2.0, desc: 'Dishwasher'),
    'washing_machine': (wsfu: 2.0, gpm: 4.0, desc: 'Washing Machine'),
    'hose_bib': (wsfu: 2.5, gpm: 5.0, desc: 'Hose Bib'),
  };

  static const Map<String, ({String desc, double factor})> _buildingTypes = {
    'residential': (desc: 'Residential', factor: 1.0),
    'office': (desc: 'Office', factor: 0.85),
    'retail': (desc: 'Retail', factor: 0.90),
    'restaurant': (desc: 'Restaurant', factor: 1.2),
    'hotel': (desc: 'Hotel', factor: 0.95),
    'hospital': (desc: 'Hospital', factor: 1.1),
  };

  double get _totalWsfu {
    double total = 0;
    _fixtures.forEach((key, count) {
      total += (_fixtureData[key]?.wsfu ?? 0) * count;
    });
    return total * (_buildingTypes[_buildingType]?.factor ?? 1.0);
  }

  // Hunter's curve approximation for GPM
  double get _peakGpm {
    final wsfu = _totalWsfu;
    if (wsfu <= 10) return wsfu * 1.0;
    if (wsfu <= 30) return 10 + (wsfu - 10) * 0.8;
    if (wsfu <= 100) return 26 + (wsfu - 30) * 0.5;
    if (wsfu <= 300) return 61 + (wsfu - 100) * 0.35;
    return 131 + (wsfu - 300) * 0.25;
  }

  String get _recommendedService {
    final gpm = _peakGpm;
    if (gpm <= 10) return '¾"';
    if (gpm <= 20) return '1"';
    if (gpm <= 35) return '1¼"';
    if (gpm <= 55) return '1½"';
    if (gpm <= 85) return '2"';
    return '2½"+';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Water Demand',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBuildingTypeCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${_peakGpm.toStringAsFixed(1)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'GPM Peak Demand',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total WSFU', _totalWsfu.toStringAsFixed(1)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Building Type', _buildingTypes[_buildingType]?.desc ?? 'Residential'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Service Size', _recommendedService, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUILDING TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildingTypes.entries.map((entry) {
              final isSelected = _buildingType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _buildingType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fixtureData.entries.map((entry) {
            final count = _fixtures[entry.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.desc,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        ),
                        Text(
                          '${entry.value.wsfu} WSFU each',
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (count > 0) {
                            setState(() => _fixtures[entry.key] = count - 1);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: count > 0 ? colors.bgBase : colors.bgBase.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.minus, color: count > 0 ? colors.textPrimary : colors.textTertiary, size: 16),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fixtures[entry.key] = count + 1);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.accentPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Appendix E',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Uses Hunter\'s Curve method\n'
            '• WSFU = Water Supply Fixture Units\n'
            '• Probability-based demand\n'
            '• Verify with local requirements\n'
            '• Consider future expansion\n'
            '• Pressure losses affect sizing',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
