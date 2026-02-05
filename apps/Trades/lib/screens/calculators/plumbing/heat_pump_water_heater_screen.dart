import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Heat Pump Water Heater Sizing Calculator - Design System v2.6
///
/// Sizes hybrid heat pump water heaters for residential applications.
/// Compares efficiency vs standard electric heaters.
///
/// References: ENERGY STAR, DOE
class HeatPumpWaterHeaterScreen extends ConsumerStatefulWidget {
  const HeatPumpWaterHeaterScreen({super.key});
  @override
  ConsumerState<HeatPumpWaterHeaterScreen> createState() => _HeatPumpWaterHeaterScreenState();
}

class _HeatPumpWaterHeaterScreenState extends ConsumerState<HeatPumpWaterHeaterScreen> {
  // Number of occupants
  int _occupants = 4;

  // Daily hot water usage per person
  double _gallonsPerPerson = 20;

  // Installation location
  String _location = 'garage';

  // Ambient temperature
  double _ambientTemp = 70;

  // Current water heater type (for comparison)
  String _currentType = 'electric';

  static const Map<String, ({String desc, double minTemp, bool heated})> _locations = {
    'garage': (desc: 'Garage (Unconditioned)', minTemp: 40, heated: false),
    'basement': (desc: 'Basement (Unconditioned)', minTemp: 50, heated: false),
    'utility_room': (desc: 'Utility Room (Conditioned)', minTemp: 60, heated: true),
    'mechanical': (desc: 'Mechanical Room', minTemp: 55, heated: false),
  };

  static const Map<String, ({double uef, String desc})> _currentTypes = {
    'electric': (uef: 0.92, desc: 'Standard Electric'),
    'gas': (uef: 0.65, desc: 'Gas Storage'),
    'old_electric': (uef: 0.80, desc: 'Older Electric (10+ yrs)'),
  };

  static const Map<int, ({int firstHour, double uef})> _hpwhSizes = {
    50: (firstHour: 66, uef: 3.5),
    65: (firstHour: 78, uef: 3.45),
    80: (firstHour: 84, uef: 3.35),
  };

  double get _dailyDemand => _occupants * _gallonsPerPerson;

  int get _recommendedSize {
    if (_dailyDemand <= 50) return 50;
    if (_dailyDemand <= 65) return 65;
    return 80;
  }

  double get _hpwhUef => _hpwhSizes[_recommendedSize]?.uef ?? 3.5;
  int get _firstHourRating => _hpwhSizes[_recommendedSize]?.firstHour ?? 66;

  // Operating efficiency varies with ambient temp
  double get _adjustedUef {
    if (_ambientTemp < 45) return _hpwhUef * 0.8; // Lower efficiency in cold
    if (_ambientTemp < 55) return _hpwhUef * 0.9;
    return _hpwhUef;
  }

  // Annual energy use (kWh) = (Daily demand × 365 × 8.33 × 70) / (3412 × UEF)
  double get _annualKwhHpwh => (_dailyDemand * 365 * 8.33 * 70) / (3412 * _adjustedUef);
  double get _annualKwhStandard => (_dailyDemand * 365 * 8.33 * 70) / (3412 * (_currentTypes[_currentType]?.uef ?? 0.92));
  double get _annualSavingsKwh => _annualKwhStandard - _annualKwhHpwh;

  // Assuming $0.15/kWh
  double get _annualSavingsDollars => _annualSavingsKwh * 0.15;

  bool get _tempOk => _ambientTemp >= 40;

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
          'Heat Pump Water Heater',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildComparisonCard(colors),
          const SizedBox(height: 16),
          _buildRequirementsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = _tempOk ? colors.accentSuccess : colors.accentWarning;

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
            '$_recommendedSize',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallon HPWH',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _tempOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _tempOk ? 'Good for Heat Pump' : 'Too Cold for HPWH',
                  style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
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
                _buildResultRow(colors, 'Daily Demand', '${_dailyDemand.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'First Hour Rating', '$_firstHourRating gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'UEF Rating', '${_adjustedUef.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Annual Savings', '\$${_annualSavingsDollars.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(ZaftoColors colors) {
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
            'HOUSEHOLD',
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
              Text('Occupants', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_occupants',
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
              value: _occupants.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupants = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gallons/Person/Day', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_gallonsPerPerson.toStringAsFixed(0)}',
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
              value: _gallonsPerPerson,
              min: 10,
              max: 30,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _gallonsPerPerson = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ZaftoColors colors) {
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
            'INSTALLATION LOCATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._locations.entries.map((entry) {
            final isSelected = _location == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _location = entry.key;
                    if (entry.value.heated) {
                      _ambientTemp = 70;
                    } else {
                      _ambientTemp = entry.value.minTemp + 10;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(ZaftoColors colors) {
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
            'AMBIENT TEMPERATURE',
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
              Text('Minimum Expected Temp', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_ambientTemp.toStringAsFixed(0)}°F',
                style: TextStyle(
                  color: _tempOk ? colors.accentPrimary : colors.accentWarning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _tempOk ? colors.accentPrimary : colors.accentWarning,
              inactiveTrackColor: colors.bgBase,
              thumbColor: _tempOk ? colors.accentPrimary : colors.accentWarning,
              trackHeight: 4,
            ),
            child: Slider(
              value: _ambientTemp,
              min: 30,
              max: 90,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ambientTemp = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tempOk
                ? 'HPWH operates optimally at 40-90°F'
                : 'Below 40°F, unit switches to resistance heating',
            style: TextStyle(
              color: _tempOk ? colors.textTertiary : colors.accentWarning,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(ZaftoColors colors) {
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
            'COMPARE TO CURRENT HEATER',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._currentTypes.entries.map((entry) {
            final isSelected = _currentType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'UEF ${entry.value.uef}',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Divider(color: colors.borderSubtle, height: 20),
          _buildDimRow(colors, 'Current Annual Use', '${_annualKwhStandard.toStringAsFixed(0)} kWh'),
          _buildDimRow(colors, 'HPWH Annual Use', '${_annualKwhHpwh.toStringAsFixed(0)} kWh'),
          _buildDimRow(colors, 'Annual Savings', '${_annualSavingsKwh.toStringAsFixed(0)} kWh'),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(ZaftoColors colors) {
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
            'INSTALLATION REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Space', '700 cu ft min (10×10×7)'),
          _buildDimRow(colors, 'Clearance', '6" all sides'),
          _buildDimRow(colors, 'Electrical', '240V 30A dedicated'),
          _buildDimRow(colors, 'Condensate Drain', 'Required'),
          _buildDimRow(colors, 'Noise Level', '~50 dB (refrigerator)'),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
              Icon(LucideIcons.leaf, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ENERGY STAR',
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
            '• UEF 3.0+ = ENERGY STAR certified\n'
            '• 3-4× more efficient than electric\n'
            '• Federal tax credit available\n'
            '• Cools & dehumidifies space\n'
            '• 10-15 year lifespan typical\n'
            '• Best in warm/humid climates',
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
