import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Drain Field (Leach Field) Calculator - Design System v2.6
///
/// Sizes septic drain fields based on percolation rate and daily flow.
/// Critical for proper wastewater dispersal.
///
/// References: EPA Onsite Wastewater Treatment Manual, Local health codes
class DrainFieldScreen extends ConsumerStatefulWidget {
  const DrainFieldScreen({super.key});
  @override
  ConsumerState<DrainFieldScreen> createState() => _DrainFieldScreenState();
}

class _DrainFieldScreenState extends ConsumerState<DrainFieldScreen> {
  // Bedrooms (primary sizing method)
  int _bedrooms = 3;

  // Percolation rate (minutes per inch)
  double _percRate = 30.0;

  // System type
  String _systemType = 'conventional';

  // Soil type (determines perc rate range)
  String _soilType = 'loam';

  // System types with descriptions
  static const Map<String, ({String name, double factor, String desc})> _systemTypes = {
    'conventional': (name: 'Conventional Trench', factor: 1.0, desc: 'Standard gravel/pipe trenches'),
    'chamber': (name: 'Chamber System', factor: 0.85, desc: 'Plastic chambers, less area'),
    'mound': (name: 'Mound System', factor: 1.5, desc: 'High water table, poor soil'),
    'drip': (name: 'Drip Disposal', factor: 0.6, desc: 'Pressure-dosed, smallest footprint'),
    'sandFilter': (name: 'Sand Filter', factor: 0.7, desc: 'Pre-treatment reduces field size'),
  };

  // Soil types with typical perc rates
  static const Map<String, ({double minPerc, double maxPerc, String desc})> _soilTypes = {
    'gravel': (minPerc: 1, maxPerc: 5, desc: 'Too fast - may need modification'),
    'sand': (minPerc: 3, maxPerc: 15, desc: 'Excellent drainage'),
    'loam': (minPerc: 15, maxPerc: 45, desc: 'Good - most common'),
    'clay-loam': (minPerc: 30, maxPerc: 60, desc: 'Marginal - needs larger field'),
    'clay': (minPerc: 60, maxPerc: 120, desc: 'Often unsuitable - alt system'),
  };

  // Application rates based on perc rate (sq ft per GPD)
  double get _applicationRate {
    // EPA guidelines - gallons per day per square foot
    // Slower perc = lower application rate = larger field
    if (_percRate < 1) return 1.2; // Too fast
    if (_percRate <= 5) return 1.0;
    if (_percRate <= 10) return 0.8;
    if (_percRate <= 15) return 0.7;
    if (_percRate <= 30) return 0.6;
    if (_percRate <= 45) return 0.5;
    if (_percRate <= 60) return 0.4;
    return 0.3; // Very slow
  }

  // Daily flow based on bedrooms (GPD)
  int get _dailyFlow {
    // EPA/local standard: 110-150 GPD per bedroom
    return _bedrooms * 120;
  }

  // Required absorption area (sq ft)
  double get _absorptionArea {
    final baseArea = _dailyFlow / _applicationRate;
    final factor = _systemTypes[_systemType]?.factor ?? 1.0;
    return baseArea * factor;
  }

  // Trench sizing (for conventional)
  double get _trenchLength {
    // Typical trench width: 3 ft, so length = area / 3
    return _absorptionArea / 3;
  }

  int get _numberOfTrenches {
    // Max trench length typically 100 ft
    return (_trenchLength / 100).ceil();
  }

  double get _eachTrenchLength {
    if (_numberOfTrenches <= 0) return 0;
    return _trenchLength / _numberOfTrenches;
  }

  String get _percAssessment {
    if (_percRate < 1) return 'TOO FAST - Groundwater contamination risk';
    if (_percRate > 60) return 'TOO SLOW - Alternative system needed';
    if (_percRate > 45) return 'MARGINAL - Larger field required';
    return 'ACCEPTABLE - Standard system OK';
  }

  Color _percStatusColor(ZaftoColors colors) {
    if (_percRate < 1 || _percRate > 60) return colors.accentError;
    if (_percRate > 45) return colors.accentWarning;
    return colors.accentSuccess;
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
          'Drain Field Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildBedroomCard(colors),
          const SizedBox(height: 16),
          _buildPercCard(colors),
          const SizedBox(height: 16),
          _buildSoilTypeCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeCard(colors),
          const SizedBox(height: 16),
          _buildTrenchDetails(colors),
          const SizedBox(height: 16),
          _buildPercTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _absorptionArea.toStringAsFixed(0),
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' sq ft',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Required Absorption Area',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _percStatusColor(colors).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _percAssessment,
              style: TextStyle(
                color: _percStatusColor(colors),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Daily Flow', '$_dailyFlow GPD'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Perc Rate', '${_percRate.toStringAsFixed(0)} min/inch'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Application Rate', '${_applicationRate.toStringAsFixed(2)} GPD/sq ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'System', _systemTypes[_systemType]?.name ?? 'Standard'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'System Factor', '${((_systemTypes[_systemType]?.factor ?? 1.0) * 100).toStringAsFixed(0)}%', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedroomCard(ZaftoColors colors) {
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
            'NUMBER OF BEDROOMS',
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
            children: [1, 2, 3, 4, 5, 6].map((beds) {
              final isSelected = _bedrooms == beds;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _bedrooms = beds);
                },
                child: Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    beds.toString(),
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on 120 GPD per bedroom',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPercCard(ZaftoColors colors) {
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
            'PERCOLATION RATE',
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
                '${_percRate.toStringAsFixed(0)} min/in',
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
                    value: _percRate,
                    min: 1,
                    max: 120,
                    divisions: 119,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _percRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Time for water to drop 1 inch in test hole',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilTypeCard(ZaftoColors colors) {
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
            'SOIL TYPE (REFERENCE)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._soilTypes.entries.map((entry) {
            final isSelected = _soilType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _soilType = entry.key;
                  // Set perc rate to midpoint of range
                  _percRate = (entry.value.minPerc + entry.value.maxPerc) / 2;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key[0].toUpperCase() + entry.key.substring(1),
                        style: TextStyle(
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.value.minPerc.toInt()}-${entry.value.maxPerc.toInt()} min/in',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.desc,
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSystemTypeCard(ZaftoColors colors) {
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
            'SYSTEM TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._systemTypes.entries.map((entry) {
            final isSelected = _systemType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _systemType = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.name,
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value.desc,
                            style: TextStyle(color: colors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(entry.value.factor * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrenchDetails(ZaftoColors colors) {
    if (_systemType != 'conventional') {
      return const SizedBox.shrink();
    }

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
            'TRENCH LAYOUT (3 FT WIDE)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Total Trench Length', '${_trenchLength.toStringAsFixed(0)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Number of Trenches', _numberOfTrenches.toString(), highlight: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Each Trench', '${_eachTrenchLength.toStringAsFixed(0)} ft'),
          const SizedBox(height: 12),
          Text(
            'Trenches spaced 6 ft center-to-center minimum',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPercTable(ZaftoColors colors) {
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
            'APPLICATION RATE TABLE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            ('1-5', '1.0'),
            ('6-10', '0.8'),
            ('11-15', '0.7'),
            ('16-30', '0.6'),
            ('31-45', '0.5'),
            ('46-60', '0.4'),
            ('>60', '0.3'),
          ].map((row) {
            final isInRange = _isPercInRange(row.$1);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isInRange ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${row.$1} min/in',
                      style: TextStyle(
                        color: isInRange ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${row.$2} GPD/sq ft',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isPercInRange(String range) {
    if (range.startsWith('>')) {
      return _percRate > 60;
    }
    final parts = range.split('-');
    if (parts.length != 2) return false;
    final min = int.tryParse(parts[0]) ?? 0;
    final max = int.tryParse(parts[1]) ?? 0;
    return _percRate >= min && _percRate <= max;
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
                'EPA & Local Health Codes',
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
            '• Perc test required by health department\n'
            '• Site evaluation determines system type\n'
            '• Min setbacks: 100 ft from well, 10 ft from property line\n'
            '• Replacement area often required (100%)\n'
            '• High groundwater may require mound system\n'
            '• Local codes may be more restrictive',
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
