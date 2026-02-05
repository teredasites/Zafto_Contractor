import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Floor Drain Sizing Calculator - Design System v2.6
///
/// Sizes floor drains based on anticipated flow rate.
/// Considers area, slope, and application type.
///
/// References: IPC 2024 Section 412, ASME A112.6.3
class FloorDrainScreen extends ConsumerStatefulWidget {
  const FloorDrainScreen({super.key});
  @override
  ConsumerState<FloorDrainScreen> createState() => _FloorDrainScreenState();
}

class _FloorDrainScreenState extends ConsumerState<FloorDrainScreen> {
  // Drainage area (sq ft)
  double _area = 200;

  // Application type
  String _application = 'general';

  // Floor slope to drain
  String _floorSlope = '1/8';

  // Is trench drain?
  bool _isTrench = false;

  // Flow rate factor by application
  static const Map<String, ({double factor, String desc})> _applications = {
    'general': (factor: 0.05, desc: 'General floor area, light use'),
    'commercial': (factor: 0.075, desc: 'Commercial, moderate use'),
    'kitchen': (factor: 0.10, desc: 'Commercial kitchen'),
    'laundry': (factor: 0.10, desc: 'Laundry room'),
    'mechanical': (factor: 0.05, desc: 'Mechanical room'),
    'carwash': (factor: 0.15, desc: 'Car wash bay'),
    'warehouse': (factor: 0.05, desc: 'Warehouse/storage'),
  };

  // Drain capacities by size (GPM)
  static const Map<String, int> _drainCapacity = {
    '2': 15,
    '3': 30,
    '4': 75,
    '6': 150,
    '8': 300,
  };

  // Trench drain per linear foot
  static const Map<String, int> _trenchCapacity = {
    '4': 10, // GPM per linear foot
    '6': 20,
    '8': 35,
    '12': 75,
  };

  double get _flowRate {
    // Simple calculation: area × factor × slope multiplier
    final factor = _applications[_application]?.factor ?? 0.05;
    final slopeMultiplier = _floorSlope == '1/4' ? 1.2 : _floorSlope == '1/2' ? 1.4 : 1.0;
    return _area * factor * slopeMultiplier;
  }

  String _calculateDrainSize() {
    final gpm = _flowRate;

    if (_isTrench) {
      for (final entry in _trenchCapacity.entries) {
        if (entry.value * 4 >= gpm) { // Assume 4 ft min length
          return '${entry.key}" trench';
        }
      }
      return '12"+ trench';
    }

    for (final entry in _drainCapacity.entries) {
      if (entry.value >= gpm) {
        return '${entry.key}"';
      }
    }

    return 'Multiple drains';
  }

  int get _drainsRequired {
    if (_isTrench) return 1;
    final gpm = _flowRate;
    final size = _calculateDrainSize().replaceAll('"', '').replaceAll(' trench', '');
    final capacity = _drainCapacity[size] ?? 75;
    return (gpm / capacity).ceil().clamp(1, 10);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final recommendedSize = _calculateDrainSize();

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
          'Floor Drain Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, recommendedSize),
          const SizedBox(height: 16),
          _buildAreaCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildSlopeCard(colors),
          const SizedBox(height: 16),
          _buildDrainTypeCard(colors),
          const SizedBox(height: 16),
          _buildCapacityTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, String recommendedSize) {
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
            recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Drain Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_drainsRequired > 1 && !_isTrench) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_drainsRequired drains may be needed',
                style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w500),
              ),
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
                _buildResultRow(colors, 'Drainage Area', '${_area.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Application', _applications[_application]?.desc.split(',')[0] ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Floor Slope', '$_floorSlope"/ft'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Est. Flow Rate', '${_flowRate.toStringAsFixed(1)} GPM', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Type', _isTrench ? 'Trench Drain' : 'Point Drain'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard(ZaftoColors colors) {
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
            'DRAINAGE AREA (SQ FT)',
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
                '${_area.toStringAsFixed(0)} sq ft',
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
                    value: _area,
                    min: 50,
                    max: 2000,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _area = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Floor area draining to this drain',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
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
            'APPLICATION TYPE',
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
            children: _applications.entries.map((entry) {
              final isSelected = _application == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _application = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc.split(',')[0],
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

  Widget _buildSlopeCard(ZaftoColors colors) {
    final slopes = ['1/8', '1/4', '1/2'];

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
            'FLOOR SLOPE TO DRAIN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: slopes.map((slope) {
              final isSelected = _floorSlope == slope;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _floorSlope = slope);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$slope"/ft',
                          style: TextStyle(
                            color: isSelected
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

  Widget _buildDrainTypeCard(ZaftoColors colors) {
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
            'DRAIN TYPE',
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
                    setState(() => _isTrench = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isTrench ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.circle,
                          color: !_isTrench
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Point Drain',
                          style: TextStyle(
                            color: !_isTrench
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
                    setState(() => _isTrench = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isTrench ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.minus,
                          color: _isTrench
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trench Drain',
                          style: TextStyle(
                            color: _isTrench
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

  Widget _buildCapacityTable(ZaftoColors colors) {
    final capacity = _isTrench ? _trenchCapacity : _drainCapacity;
    final recommendedSize = _calculateDrainSize()
        .replaceAll('"', '')
        .replaceAll(' trench', '');

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
            _isTrench ? 'TRENCH DRAIN CAPACITY (GPM/FT)' : 'POINT DRAIN CAPACITY (GPM)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...capacity.entries.map((entry) {
            final isRecommended = entry.key == recommendedSize;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${entry.key}"',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isTrench ? '${entry.value} GPM/ft' : '${entry.value} GPM',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                  if (isRecommended)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
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
                'IPC 2024 Section 412',
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
            '• Min 2" drain for floor drains\n'
            '• Trap primer required if not regularly used\n'
            '• Floor slope: 1/8" to 1/4"/ft typical\n'
            '• ASME A112.6.3 for drain standards\n'
            '• Strainer required on all floor drains\n'
            '• Consider cleanout access',
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
