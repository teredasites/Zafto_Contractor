import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Humidity Calculator - Design System v2.6
///
/// Calculates humidity requirements and humidifier/dehumidifier sizing.
/// Covers heating and cooling season humidity control.
///
/// References: ASHRAE Handbook, Manufacturer Guidelines
class HumidityScreen extends ConsumerStatefulWidget {
  const HumidityScreen({super.key});
  @override
  ConsumerState<HumidityScreen> createState() => _HumidityScreenState();
}

class _HumidityScreenState extends ConsumerState<HumidityScreen> {
  // Mode
  String _mode = 'humidify';

  // Square footage
  double _sqft = 2000;

  // Current humidity (%)
  double _currentHumidity = 25;

  // Target humidity (%)
  double _targetHumidity = 45;

  // Building tightness
  String _tightness = 'average';

  static const Map<String, ({String desc, double factor})> _tightnessLevels = {
    'tight': (desc: 'Tight (New)', factor: 0.7),
    'average': (desc: 'Average', factor: 1.0),
    'loose': (desc: 'Loose (Older)', factor: 1.5),
  };

  // Humidity difference
  double get _humidityDiff => (_targetHumidity - _currentHumidity).abs();

  // Humidifier capacity (gallons/day)
  double get _humidifierCapacity {
    final factor = _tightnessLevels[_tightness]?.factor ?? 1.0;
    // Rule of thumb: ~0.1 gallon per 100 sq ft per 10% RH increase per day
    return (_sqft / 100) * (_humidityDiff / 10) * 0.1 * factor;
  }

  // Dehumidifier capacity (pints/day)
  double get _dehumidifierCapacity {
    final factor = _tightnessLevels[_tightness]?.factor ?? 1.0;
    // Rule of thumb: 10 pints per 500 sq ft base + adjustment for humidity
    final base = (_sqft / 500) * 10;
    return base * (_humidityDiff / 20) * factor;
  }

  // Recommended unit size
  String get _recommendedSize {
    if (_mode == 'humidify') {
      final cap = _humidifierCapacity;
      if (cap <= 2) return '2 gallon/day';
      if (cap <= 4) return '4 gallon/day';
      if (cap <= 8) return '8 gallon/day';
      if (cap <= 12) return '12 gallon/day';
      return '12+ gallon/day';
    } else {
      final cap = _dehumidifierCapacity;
      if (cap <= 20) return '20 pint';
      if (cap <= 30) return '30 pint';
      if (cap <= 50) return '50 pint';
      if (cap <= 70) return '70 pint';
      return '70+ pint';
    }
  }

  // Comfort status
  String get _comfortStatus {
    if (_targetHumidity < 30) return 'Too dry - risk of static, irritation';
    if (_targetHumidity <= 50) return 'Optimal comfort range';
    if (_targetHumidity <= 60) return 'Acceptable';
    return 'Too humid - risk of mold, condensation';
  }

  bool get _inComfortZone => _targetHumidity >= 30 && _targetHumidity <= 50;

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
          'Humidity Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildModeCard(colors),
          const SizedBox(height: 16),
          _buildSqftCard(colors),
          const SizedBox(height: 16),
          _buildHumidityCard(colors),
          const SizedBox(height: 16),
          _buildTightnessCard(colors),
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
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _mode == 'humidify' ? 'Humidifier Size' : 'Dehumidifier Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _inComfortZone
                  ? colors.accentPrimary.withValues(alpha: 0.1)
                  : colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _comfortStatus,
              style: TextStyle(
                color: _inComfortZone ? colors.accentPrimary : colors.accentWarning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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
                _buildResultRow(colors, 'Current RH', '${_currentHumidity.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Target RH', '${_targetHumidity.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Change Needed', '${_humidityDiff.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Capacity', _mode == 'humidify'
                    ? '${_humidifierCapacity.toStringAsFixed(1)} gal/day'
                    : '${_dehumidifierCapacity.toStringAsFixed(0)} pints/day'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(ZaftoColors colors) {
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
            'MODE',
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
                    setState(() => _mode = 'humidify');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _mode == 'humidify' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.droplets,
                          color: _mode == 'humidify'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Humidify',
                          style: TextStyle(
                            color: _mode == 'humidify'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                    setState(() => _mode = 'dehumidify');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _mode == 'dehumidify' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.droplet,
                          color: _mode == 'dehumidify'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dehumidify',
                          style: TextStyle(
                            color: _mode == 'dehumidify'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

  Widget _buildSqftCard(ZaftoColors colors) {
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
            'CONDITIONED AREA',
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
              Text('Square Footage', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_sqft.toStringAsFixed(0)} sq ft',
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
              value: _sqft,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _sqft = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard(ZaftoColors colors) {
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
            'HUMIDITY LEVELS',
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
              Text('Current Humidity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_currentHumidity.toStringAsFixed(0)}%',
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
              value: _currentHumidity,
              min: 10,
              max: 80,
              divisions: 70,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _currentHumidity = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Humidity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_targetHumidity.toStringAsFixed(0)}%',
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
              value: _targetHumidity,
              min: 20,
              max: 70,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _targetHumidity = v);
              },
            ),
          ),
          Text(
            'Ideal range: 30-50% RH',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTightnessCard(ZaftoColors colors) {
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
            'BUILDING TIGHTNESS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _tightnessLevels.entries.map((entry) {
              final isSelected = _tightness == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _tightness = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.droplets, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Humidity Guidelines',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Ideal indoor: 30-50% RH\n'
            '• Below 30%: Static, dry skin\n'
            '• Above 60%: Mold risk\n'
            '• Winter: May need humidifier\n'
            '• Summer: May need dehumidifier\n'
            '• Watch for window condensation',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
