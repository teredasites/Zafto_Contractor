import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Grease Interceptor Sizing Calculator - Design System v2.6
///
/// Sizes grease interceptors for commercial kitchens.
/// Uses flow rate and retention time methods.
///
/// References: IPC 2024 Section 1003, PDI-G101
class GreaseInterceptorScreen extends ConsumerStatefulWidget {
  const GreaseInterceptorScreen({super.key});
  @override
  ConsumerState<GreaseInterceptorScreen> createState() => _GreaseInterceptorScreenState();
}

class _GreaseInterceptorScreenState extends ConsumerState<GreaseInterceptorScreen> {
  // Calculation method
  String _method = 'fixture'; // 'fixture' or 'flow'

  // For fixture method
  int _3compartmentSinks = 1;
  int _prepSinks = 1;
  int _handSinks = 0;
  int _mopSinks = 0;
  int _dishwashers = 0;

  // For flow rate method
  double _flowRate = 50; // GPM

  // Retention time (minutes)
  double _retentionTime = 2.5;

  // Building type
  String _buildingType = 'restaurant';

  static const Map<String, ({double factor, String desc})> _buildingTypes = {
    'restaurant': (factor: 1.0, desc: 'Full service restaurant'),
    'fastFood': (factor: 0.8, desc: 'Fast food / Quick serve'),
    'cafeteria': (factor: 0.9, desc: 'Cafeteria / Buffet'),
    'bakery': (factor: 0.7, desc: 'Bakery'),
    'grocery': (factor: 0.6, desc: 'Grocery deli'),
    'hotel': (factor: 1.1, desc: 'Hotel kitchen'),
  };

  // Fixture flow rates per IPC Table E103.3(3)
  static const Map<String, double> _fixtureGpm = {
    '3compartmentSinks': 20.0,
    'prepSinks': 10.0,
    'handSinks': 2.0,
    'mopSinks': 6.0,
    'dishwashers': 15.0,
  };

  double get _totalGpm {
    if (_method == 'flow') return _flowRate;

    return (_3compartmentSinks * _fixtureGpm['3compartmentSinks']!) +
           (_prepSinks * _fixtureGpm['prepSinks']!) +
           (_handSinks * _fixtureGpm['handSinks']!) +
           (_mopSinks * _fixtureGpm['mopSinks']!) +
           (_dishwashers * _fixtureGpm['dishwashers']!);
  }

  // Grease interceptor sizing per PDI-G101
  // Capacity = Flow Rate × Retention Time × Factor
  double get _interceptorCapacity {
    final factor = _buildingTypes[_buildingType]?.factor ?? 1.0;
    return _totalGpm * _retentionTime * factor;
  }

  String get _recommendedSize {
    final capacity = _interceptorCapacity;

    // Standard sizes (gallons)
    if (capacity <= 20) return '20 gal';
    if (capacity <= 30) return '30 gal';
    if (capacity <= 40) return '40 gal';
    if (capacity <= 50) return '50 gal';
    if (capacity <= 75) return '75 gal';
    if (capacity <= 100) return '100 gal';
    if (capacity <= 150) return '150 gal';
    if (capacity <= 200) return '200 gal';
    if (capacity <= 300) return '300 gal';
    if (capacity <= 500) return '500 gal';
    if (capacity <= 750) return '750 gal';
    if (capacity <= 1000) return '1000 gal';
    if (capacity <= 1500) return '1500 gal';
    if (capacity <= 2000) return '2000 gal';
    return '> 2000 gal';
  }

  String get _interceptorType {
    final capacity = _interceptorCapacity;
    if (capacity <= 50) return 'Under-sink (Hydromechanical)';
    if (capacity <= 100) return 'Floor-mount (Hydromechanical)';
    return 'In-ground (Gravity)';
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
          'Grease Interceptor Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildMethodCard(colors),
          const SizedBox(height: 16),
          if (_method == 'fixture')
            _buildFixtureCard(colors)
          else
            _buildFlowRateCard(colors),
          const SizedBox(height: 16),
          _buildBuildingTypeCard(colors),
          const SizedBox(height: 16),
          _buildRetentionCard(colors),
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
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Grease Interceptor Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _interceptorType,
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                _buildResultRow(colors, 'Flow Rate', '${_totalGpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Retention Time', '${_retentionTime.toStringAsFixed(1)} min'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Building Factor', '${(_buildingTypes[_buildingType]?.factor ?? 1.0).toStringAsFixed(1)}x'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Calculated', '${_interceptorCapacity.toStringAsFixed(1)} gal', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(ZaftoColors colors) {
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
            'SIZING METHOD',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _method = 'fixture');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _method == 'fixture' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.layoutGrid,
                          color: _method == 'fixture'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By Fixtures',
                          style: TextStyle(
                            color: _method == 'fixture'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _method = 'flow');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _method == 'flow' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.gauge,
                          color: _method == 'flow'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By Flow Rate',
                          style: TextStyle(
                            color: _method == 'flow'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureCard(ZaftoColors colors) {
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
          _buildFixtureRow(colors, '3-Compartment Sinks', _3compartmentSinks, (v) => setState(() => _3compartmentSinks = v), gpm: 20),
          _buildFixtureRow(colors, 'Prep Sinks', _prepSinks, (v) => setState(() => _prepSinks = v), gpm: 10),
          _buildFixtureRow(colors, 'Hand Sinks', _handSinks, (v) => setState(() => _handSinks = v), gpm: 2),
          _buildFixtureRow(colors, 'Mop Sinks', _mopSinks, (v) => setState(() => _mopSinks = v), gpm: 6),
          _buildFixtureRow(colors, 'Dishwashers', _dishwashers, (v) => setState(() => _dishwashers = v), gpm: 15),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int count, Function(int) onChanged, {required int gpm}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  '$gpm GPM each',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count > 0) onChanged(count - 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.minus, color: colors.textSecondary, size: 18),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$count',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count < 10) onChanged(count + 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRateCard(ZaftoColors colors) {
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
            'TOTAL FLOW RATE (GPM)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_flowRate.toStringAsFixed(0)} GPM',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _flowRate,
                    min: 10,
                    max: 200,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Combined flow from all fixtures to interceptor',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildRetentionCard(ZaftoColors colors) {
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
            'RETENTION TIME (MINUTES)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_retentionTime.toStringAsFixed(1)} min',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _retentionTime,
                    min: 1.5,
                    max: 5.0,
                    divisions: 7,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _retentionTime = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'PDI-G101 recommends 2.5 min minimum',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
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
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
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
                'IPC 2024 Section 1003',
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
            '• PDI-G101 certified interceptors required\n'
            '• Hydromechanical: indoor, frequent pumping\n'
            '• Gravity: outdoor, less frequent pumping\n'
            '• Flow control device required\n'
            '• Sampling tees for testing\n'
            '• No garbage disposals to interceptor',
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
