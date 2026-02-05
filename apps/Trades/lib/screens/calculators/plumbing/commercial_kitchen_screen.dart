import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Commercial Kitchen Plumbing Calculator - Design System v2.6
///
/// Sizes plumbing for commercial kitchen facilities.
/// Calculates grease interceptor, hot water, and drainage requirements.
///
/// References: IPC 2024, UPC, NSF Standards
class CommercialKitchenScreen extends ConsumerStatefulWidget {
  const CommercialKitchenScreen({super.key});
  @override
  ConsumerState<CommercialKitchenScreen> createState() => _CommercialKitchenScreenState();
}

class _CommercialKitchenScreenState extends ConsumerState<CommercialKitchenScreen> {
  // Number of seats
  int _seats = 50;

  // Meals per day
  int _mealsPerDay = 150;

  // Kitchen fixtures
  Map<String, int> _fixtures = {
    '3_comp_sink': 1,
    'prep_sink': 2,
    'hand_sink': 2,
    'mop_sink': 1,
    'dishwasher': 1,
    'ice_maker': 1,
    'floor_drain': 3,
  };

  static const Map<String, ({String desc, int dfu, double hotGpm})> _fixtureData = {
    '3_comp_sink': (desc: '3-Compartment Sink', dfu: 4, hotGpm: 3.0),
    'prep_sink': (desc: 'Prep Sink', dfu: 2, hotGpm: 1.5),
    'hand_sink': (desc: 'Hand Sink', dfu: 1, hotGpm: 0.5),
    'mop_sink': (desc: 'Mop Sink', dfu: 3, hotGpm: 2.0),
    'dishwasher': (desc: 'Commercial Dishwasher', dfu: 4, hotGpm: 5.0),
    'ice_maker': (desc: 'Ice Machine', dfu: 1, hotGpm: 0.0),
    'floor_drain': (desc: 'Floor Drain', dfu: 2, hotGpm: 0.0),
  };

  int get _totalDfu {
    int total = 0;
    _fixtures.forEach((key, count) {
      total += (_fixtureData[key]?.dfu ?? 0) * count;
    });
    return total;
  }

  double get _peakHotWaterGpm {
    double total = 0;
    _fixtures.forEach((key, count) {
      total += (_fixtureData[key]?.hotGpm ?? 0) * count;
    });
    return total * 0.7; // 70% diversity
  }

  // Grease interceptor sizing (GPM)
  // Based on IPC formula: (fixture DFU × 7.5) / 60 + dishwasher flow
  int get _greaseInterceptorGpm {
    final baseDfu = _totalDfu - ((_fixtures['floor_drain'] ?? 0) * 2);
    final dishwasherFlow = (_fixtures['dishwasher'] ?? 0) * 15;
    return ((baseDfu * 7.5 / 60) + dishwasherFlow / 60).ceil().clamp(20, 100);
  }

  // Grease interceptor size (gallons)
  int get _greaseInterceptorGallons {
    final gpm = _greaseInterceptorGpm;
    if (gpm <= 20) return 30;
    if (gpm <= 35) return 50;
    if (gpm <= 50) return 75;
    return 100;
  }

  // Hot water demand (gallons per hour)
  int get _hotWaterDemandGph {
    // Quick service: 1 gallon per meal
    // Full service: 2 gallons per meal
    final gallonsPerMeal = _seats > 30 ? 2.0 : 1.5;
    return ((_mealsPerDay / 8) * gallonsPerMeal).ceil(); // 8 hour peak
  }

  // Drain line size
  String get _drainLineSize {
    if (_totalDfu <= 20) return '3\"';
    if (_totalDfu <= 160) return '4\"';
    return '6\"';
  }

  // Water heater size
  String get _waterHeaterSize {
    final gph = _hotWaterDemandGph;
    if (gph <= 30) return '50 gallon';
    if (gph <= 50) return '75 gallon';
    if (gph <= 80) return '100 gallon';
    return '100+ gallon or tankless';
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
          'Commercial Kitchen',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSeatingCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildGreaseCard(colors),
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
            '$_greaseInterceptorGallons gal',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Grease Interceptor',
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
                _buildResultRow(colors, 'Total DFU', '$_totalDfu'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Interceptor Flow', '$_greaseInterceptorGpm GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Main Drain', _drainLineSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hot Water Demand', '$_hotWaterDemandGph GPH'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Water Heater', _waterHeaterSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatingCard(ZaftoColors colors) {
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
            'RESTAURANT SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seating Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_seats seats',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _seats.toDouble(),
              min: 10,
              max: 200,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _seats = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meals per Day', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_mealsPerDay',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _mealsPerDay.toDouble(),
              min: 50,
              max: 500,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _mealsPerDay = v.round());
              },
            ),
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
            'KITCHEN FIXTURES',
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
                          '${entry.value.dfu} DFU each',
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
                        child: Text('$count', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildGreaseCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
              const SizedBox(width: 8),
              Text(
                'Grease Interceptor Requirements',
                style: TextStyle(color: colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGreaseRow(colors, 'Required by', 'IPC 1003.1'),
          _buildGreaseRow(colors, 'Pump-out', 'Every 30-90 days'),
          _buildGreaseRow(colors, 'Location', 'Outside building preferred'),
          _buildGreaseRow(colors, 'Access', 'Minimum 24\" clearance'),
          const SizedBox(height: 8),
          Text(
            'Check local FOG ordinance for specific requirements',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGreaseRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.dot, color: colors.accentWarning, size: 14),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.chefHat, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 / NSF Standards',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• NSF 3 for food equipment\n'
            '• Indirect waste from dishwashers\n'
            '• Floor drains within 6\' of equipment\n'
            '• Hand sinks at each work station\n'
            '• 140°F sanitizing water available\n'
            '• Backflow protection required',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
