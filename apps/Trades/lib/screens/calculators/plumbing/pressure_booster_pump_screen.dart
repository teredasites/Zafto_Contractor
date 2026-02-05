import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pressure Booster Pump Calculator - Design System v2.6
///
/// Sizes booster pump for buildings with low water pressure.
/// Calculates GPM, required pressure boost, and motor HP.
///
/// References: IPC 2024 Section 606, ASPE standards
class PressureBoosterPumpScreen extends ConsumerStatefulWidget {
  const PressureBoosterPumpScreen({super.key});
  @override
  ConsumerState<PressureBoosterPumpScreen> createState() => _PressureBoosterPumpScreenState();
}

class _PressureBoosterPumpScreenState extends ConsumerState<PressureBoosterPumpScreen> {
  // Incoming pressure (PSI)
  double _inletPressure = 25;

  // Required outlet pressure (PSI)
  double _requiredPressure = 60;

  // Peak demand (GPM)
  double _peakGpm = 30;

  // Number of floors
  int _floors = 3;

  // Building type
  String _buildingType = 'residential';

  static const List<({String value, String label, double factor})> _buildingTypes = [
    (value: 'residential', label: 'Residential', factor: 1.0),
    (value: 'commercial', label: 'Commercial', factor: 1.1),
    (value: 'hospital', label: 'Hospital/Medical', factor: 1.25),
    (value: 'industrial', label: 'Industrial', factor: 1.15),
  ];

  // Elevation head (0.433 psi per foot of elevation)
  double get _elevationHead => _floors * 10 * 0.433; // 10 ft per floor typical

  // Friction loss estimate (15% of elevation head typical)
  double get _frictionLoss => _elevationHead * 0.15;

  // Total pressure boost needed
  double get _pressureBoost {
    final boost = _requiredPressure - _inletPressure + _elevationHead + _frictionLoss;
    return boost > 0 ? boost : 0;
  }

  // Pump HP calculation
  // HP = (GPM × Head in feet × SG) / (3960 × efficiency)
  // Head in feet = PSI × 2.31
  double get _pumpHp {
    final headFeet = _pressureBoost * 2.31;
    final factor = _buildingTypes.firstWhere((b) => b.value == _buildingType).factor;
    // Assume 60% pump efficiency
    return (_peakGpm * headFeet * factor) / (3960 * 0.60);
  }

  String get _recommendedHp {
    final hp = _pumpHp;
    if (hp <= 0.33) return '1/3 HP';
    if (hp <= 0.5) return '1/2 HP';
    if (hp <= 0.75) return '3/4 HP';
    if (hp <= 1.0) return '1 HP';
    if (hp <= 1.5) return '1-1/2 HP';
    if (hp <= 2.0) return '2 HP';
    if (hp <= 3.0) return '3 HP';
    if (hp <= 5.0) return '5 HP';
    if (hp <= 7.5) return '7-1/2 HP';
    if (hp <= 10.0) return '10 HP';
    if (hp <= 15.0) return '15 HP';
    if (hp <= 20.0) return '20 HP';
    return '${hp.ceil()} HP';
  }

  String get _systemRecommendation {
    if (_pressureBoost <= 0) return 'No boost needed';
    if (_pressureBoost <= 20 && _peakGpm <= 15) return 'Point-of-use booster';
    if (_pressureBoost <= 40 && _peakGpm <= 40) return 'Single pump system';
    if (_peakGpm <= 100) return 'Duplex system (lead/lag)';
    return 'Triplex system with VFD';
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
          'Pressure Booster Pump',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
          const SizedBox(height: 16),
          _buildBreakdownCard(colors),
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
            _recommendedHp,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Motor Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _systemRecommendation,
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                _buildResultRow(colors, 'Pressure Boost', '${_pressureBoost.toStringAsFixed(1)} PSI', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow Rate', '${_peakGpm.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Calculated HP', _pumpHp.toStringAsFixed(2)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Head (feet)', '${(_pressureBoost * 2.31).toStringAsFixed(1)} ft'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureCard(ZaftoColors colors) {
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
            'PRESSURE SETTINGS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Inlet:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                '${_inletPressure.toStringAsFixed(0)} PSI',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
            ),
            child: Slider(
              value: _inletPressure,
              min: 10,
              max: 60,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _inletPressure = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Required:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                '${_requiredPressure.toStringAsFixed(0)} PSI',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
            ),
            child: Slider(
              value: _requiredPressure,
              min: 40,
              max: 100,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _requiredPressure = v);
              },
            ),
          ),
          Text(
            'IPC requires min 15 PSI at fixtures',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(ZaftoColors colors) {
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
            'PEAK DEMAND (GPM)',
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
                '${_peakGpm.toStringAsFixed(0)} GPM',
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
                    value: _peakGpm,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _peakGpm = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'From WSFU calculation or meter size',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(ZaftoColors colors) {
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
            'BUILDING PARAMETERS',
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
              Text('Floors:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(width: 16),
              ...List.generate(6, (i) {
                final floor = i + 1;
                final isSelected = _floors == floor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _floors = floor);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$floor',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'BUILDING TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildingTypes.map((type) {
              final isSelected = _buildingType == type.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _buildingType = type.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.label,
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

  Widget _buildBreakdownCard(ZaftoColors colors) {
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
            'PRESSURE BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(colors, 'Inlet Pressure', '-${_inletPressure.toStringAsFixed(1)} PSI'),
          _buildBreakdownRow(colors, 'Required Pressure', '+${_requiredPressure.toStringAsFixed(1)} PSI'),
          _buildBreakdownRow(colors, 'Elevation Head', '+${_elevationHead.toStringAsFixed(1)} PSI'),
          _buildBreakdownRow(colors, 'Est. Friction Loss', '+${_frictionLoss.toStringAsFixed(1)} PSI'),
          Divider(color: colors.borderSubtle, height: 20),
          _buildBreakdownRow(colors, 'Total Boost Required', '${_pressureBoost.toStringAsFixed(1)} PSI', isBold: true),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(ZaftoColors colors, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBold ? colors.accentPrimary : colors.textPrimary,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
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
                'IPC 2024 Section 606',
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
            '• Min fixture pressure: 15 PSI (8 for some)\n'
            '• Max static: 80 PSI (PRV required)\n'
            '• 0.433 PSI loss per foot elevation\n'
            '• Include friction losses in long runs\n'
            '• Duplex systems for redundancy\n'
            '• VFD maintains constant pressure',
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
