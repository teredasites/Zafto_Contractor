import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Static Pressure Calculator - Design System v2.6
///
/// Calculates total external static pressure for HVAC systems.
/// Helps size equipment and diagnose airflow issues.
///
/// References: ACCA Manual D, Equipment Specifications
class StaticPressureScreen extends ConsumerStatefulWidget {
  const StaticPressureScreen({super.key});
  @override
  ConsumerState<StaticPressureScreen> createState() => _StaticPressureScreenState();
}

class _StaticPressureScreenState extends ConsumerState<StaticPressureScreen> {
  // Supply static (in. w.c.)
  double _supplyStatic = 0.5;

  // Return static (in. w.c.)
  double _returnStatic = 0.3;

  // Filter pressure drop
  double _filterDrop = 0.1;

  // Coil pressure drop
  double _coilDrop = 0.25;

  // Equipment rated static
  double _ratedStatic = 0.5;

  // Total external static pressure
  double get _totalEsp => _supplyStatic + _returnStatic;

  // Total system pressure
  double get _totalSystem => _totalEsp + _filterDrop + _coilDrop;

  // Available static (equipment rated - components)
  double get _availableStatic => _ratedStatic - _filterDrop - _coilDrop;

  // System status
  String get _systemStatus {
    if (_totalEsp <= _availableStatic * 0.8) return 'Excellent';
    if (_totalEsp <= _availableStatic) return 'Good';
    if (_totalEsp <= _availableStatic * 1.2) return 'Marginal';
    return 'Restricted';
  }

  bool get _isRestricted => _totalEsp > _availableStatic;

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
          'Static Pressure',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSupplyCard(colors),
          const SizedBox(height: 16),
          _buildReturnCard(colors),
          const SizedBox(height: 16),
          _buildComponentsCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
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
            '${_totalEsp.toStringAsFixed(2)}\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total External Static',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isRestricted
                  ? colors.accentWarning.withValues(alpha: 0.1)
                  : colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _systemStatus,
              style: TextStyle(
                color: _isRestricted ? colors.accentWarning : colors.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isRestricted) ...[
            const SizedBox(height: 8),
            Text(
              'Airflow may be restricted - check ducts/filter',
              style: TextStyle(color: colors.accentWarning, fontSize: 11),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Supply Static', '${_supplyStatic.toStringAsFixed(2)}\" w.c.'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Return Static', '${_returnStatic.toStringAsFixed(2)}\" w.c.'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Filter Drop', '${_filterDrop.toStringAsFixed(2)}\" w.c.'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Coil Drop', '${_coilDrop.toStringAsFixed(2)}\" w.c.'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Available', '${_availableStatic.toStringAsFixed(2)}\" w.c.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyCard(ZaftoColors colors) {
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
            'SUPPLY STATIC',
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
              Text('Supply Side', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_supplyStatic.toStringAsFixed(2)}\" w.c.',
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
              value: _supplyStatic,
              min: 0,
              max: 1.0,
              divisions: 100,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _supplyStatic = v);
              },
            ),
          ),
          Text(
            'Measure at supply plenum',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(ZaftoColors colors) {
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
            'RETURN STATIC',
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
              Text('Return Side', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_returnStatic.toStringAsFixed(2)}\" w.c.',
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
              value: _returnStatic,
              min: 0,
              max: 0.8,
              divisions: 80,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _returnStatic = v);
              },
            ),
          ),
          Text(
            'Measure at return drop (negative pressure)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsCard(ZaftoColors colors) {
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
            'COMPONENT PRESSURE DROPS',
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
              Text('Filter', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_filterDrop.toStringAsFixed(2)}\" w.c.',
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
              value: _filterDrop,
              min: 0.05,
              max: 0.5,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _filterDrop = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coil', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_coilDrop.toStringAsFixed(2)}\" w.c.',
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
              value: _coilDrop,
              min: 0.1,
              max: 0.5,
              divisions: 40,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _coilDrop = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
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
            'EQUIPMENT RATING',
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
              Text('Rated ESP', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_ratedStatic.toStringAsFixed(2)}\" w.c.',
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
              value: _ratedStatic,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ratedStatic = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.3, 0.5, 0.8].map((esp) {
              final isSelected = (_ratedStatic - esp).abs() < 0.05;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _ratedStatic = esp);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${esp}\" w.c.',
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
              Icon(LucideIcons.gauge, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Static Pressure Testing',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Test at design airflow\n'
            '• Clean filter for baseline\n'
            '• Supply = positive pressure\n'
            '• Return = negative pressure\n'
            '• High ESP = restricted airflow\n'
            '• Check duct connections',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
