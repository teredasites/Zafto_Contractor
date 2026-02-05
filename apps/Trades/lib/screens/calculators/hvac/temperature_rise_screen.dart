import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Temperature Rise Calculator - Design System v2.6
///
/// Calculates temperature rise across a furnace heat exchanger.
/// Essential for verifying proper airflow and heat exchanger condition.
///
/// References: Manufacturer Specifications, NATE
class TemperatureRiseScreen extends ConsumerStatefulWidget {
  const TemperatureRiseScreen({super.key});
  @override
  ConsumerState<TemperatureRiseScreen> createState() => _TemperatureRiseScreenState();
}

class _TemperatureRiseScreenState extends ConsumerState<TemperatureRiseScreen> {
  // Return air temperature (°F)
  double _returnTemp = 70;

  // Supply air temperature (°F)
  double _supplyTemp = 125;

  // Furnace BTU input
  double _btuInput = 80000;

  // Target rise range
  double _targetLow = 35;
  double _targetHigh = 65;

  // Actual temperature rise
  double get _tempRise => _supplyTemp - _returnTemp;

  // Status
  String get _status {
    if (_tempRise < _targetLow) return 'Low - Too much airflow or firing issue';
    if (_tempRise > _targetHigh) return 'High - Restricted airflow';
    return 'Normal - Within acceptable range';
  }

  bool get _inRange => _tempRise >= _targetLow && _tempRise <= _targetHigh;

  // Estimated CFM (using sensible heat formula)
  // BTU = 1.08 × CFM × ΔT
  // CFM = BTU / (1.08 × ΔT)
  double get _estimatedCfm {
    if (_tempRise == 0) return 0;
    // Using output BTU (80% efficiency typical)
    return (_btuInput * 0.8) / (1.08 * _tempRise);
  }

  // CFM per ton
  double get _cfmPerTon => _estimatedCfm / (_btuInput / 12000 / 3.5);

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
          'Temperature Rise',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildTempCard(colors),
          const SizedBox(height: 16),
          _buildTargetCard(colors),
          const SizedBox(height: 16),
          _buildBtuCard(colors),
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
            '${_tempRise.toStringAsFixed(1)}°F',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Temperature Rise',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _inRange
                  ? colors.accentPrimary.withValues(alpha: 0.1)
                  : colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _status,
              style: TextStyle(
                color: _inRange ? colors.accentPrimary : colors.accentWarning,
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
                _buildResultRow(colors, 'Return Temp', '${_returnTemp.toStringAsFixed(1)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Temp', '${_supplyTemp.toStringAsFixed(1)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Target Range', '${_targetLow.toStringAsFixed(0)}-${_targetHigh.toStringAsFixed(0)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Est. CFM', '${_estimatedCfm.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'CFM/ton', '${_cfmPerTon.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempCard(ZaftoColors colors) {
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
            'MEASURED TEMPERATURES',
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
              Text('Return Air', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_returnTemp.toStringAsFixed(1)}°F',
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
              value: _returnTemp,
              min: 50,
              max: 85,
              divisions: 70,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _returnTemp = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Supply Air', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_supplyTemp.toStringAsFixed(1)}°F',
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
              value: _supplyTemp,
              min: 90,
              max: 170,
              divisions: 80,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _supplyTemp = v);
              },
            ),
          ),
          Text(
            'Measure in center of duct, 10\" from unit',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(ZaftoColors colors) {
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
            'TARGET RANGE (FROM DATA PLATE)',
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
              Text('Minimum Rise', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_targetLow.toStringAsFixed(0)}°F',
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
              value: _targetLow,
              min: 20,
              max: 50,
              divisions: 30,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _targetLow = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maximum Rise', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_targetHigh.toStringAsFixed(0)}°F',
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
              value: _targetHigh,
              min: 45,
              max: 80,
              divisions: 35,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _targetHigh = v);
              },
            ),
          ),
          Text(
            'Common ranges: 35-65°F, 40-70°F',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBtuCard(ZaftoColors colors) {
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
            'FURNACE INPUT',
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
              Text('BTU Input', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${(_btuInput / 1000).toStringAsFixed(0)}K',
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
              value: _btuInput,
              min: 40000,
              max: 140000,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _btuInput = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [60, 80, 100, 120].map((btu) {
              final value = btu * 1000;
              final isSelected = (_btuInput - value).abs() < 5000;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _btuInput = value.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${btu}K',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
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
              Icon(LucideIcons.thermometer, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Temperature Rise Testing',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Low rise = excessive airflow\n'
            '• High rise = restricted airflow\n'
            '• Check filter and ductwork\n'
            '• Verify gas pressure\n'
            '• Allow 10 min operation\n'
            '• Check data plate for specs',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
