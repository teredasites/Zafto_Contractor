import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Meter Sizing - Design System v2.6
///
/// Sizes water meters based on demand and pressure loss limits.
/// Critical for proper water service design.
///
/// References: AWWA M22, IPC Appendix E
class WaterMeterSizingScreen extends ConsumerStatefulWidget {
  const WaterMeterSizingScreen({super.key});
  @override
  ConsumerState<WaterMeterSizingScreen> createState() => _WaterMeterSizingScreenState();
}

class _WaterMeterSizingScreenState extends ConsumerState<WaterMeterSizingScreen> {
  // Peak demand (GPM)
  double _peakDemand = 25.0;

  // WSFU total (for reference)
  double _totalWSFU = 40.0;

  // Meter type
  String _meterType = 'displacement';

  // Building type
  String _buildingType = 'residential';

  // Meter types with characteristics
  static const Map<String, ({String name, String desc, double accuracy})> _meterTypes = {
    'displacement': (name: 'Displacement', desc: 'Residential, low flow accuracy', accuracy: 0.5),
    'compound': (name: 'Compound', desc: 'Variable flow, commercial', accuracy: 1.5),
    'turbine': (name: 'Turbine', desc: 'High flow, low loss', accuracy: 2.0),
    'electromagnetic': (name: 'Electromagnetic', desc: 'No moving parts, industrial', accuracy: 0.5),
  };

  // Meter sizing table (size, safe max GPM, pressure loss at max)
  static const List<({String size, double maxGPM, double pressureLoss, String typical})> _meterSizes = [
    (size: '5/8"', maxGPM: 20, pressureLoss: 7, typical: 'Small residence'),
    (size: '5/8" x 3/4"', maxGPM: 30, pressureLoss: 8, typical: 'Standard residence'),
    (size: '3/4"', maxGPM: 50, pressureLoss: 9, typical: 'Large residence'),
    (size: '1"', maxGPM: 75, pressureLoss: 11, typical: 'Multi-family, small commercial'),
    (size: '1-1/2"', maxGPM: 160, pressureLoss: 14, typical: 'Commercial'),
    (size: '2"', maxGPM: 320, pressureLoss: 15, typical: 'Large commercial'),
    (size: '3"', maxGPM: 640, pressureLoss: 10, typical: 'Industrial'),
    (size: '4"', maxGPM: 1000, pressureLoss: 8, typical: 'Large industrial'),
  ];

  // Building types with demand factors
  static const Map<String, ({String name, double factor})> _buildingTypes = {
    'residential': (name: 'Residential', factor: 1.0),
    'apartment': (name: 'Apartment', factor: 0.8),
    'office': (name: 'Office', factor: 0.6),
    'restaurant': (name: 'Restaurant', factor: 1.2),
    'hospital': (name: 'Hospital', factor: 1.3),
    'school': (name: 'School', factor: 0.7),
    'hotel': (name: 'Hotel', factor: 0.9),
  };

  // Convert WSFU to GPM (Hunter's curve approximation)
  double get _estimatedGPM {
    final wsfu = _totalWSFU;
    if (wsfu <= 6) return wsfu * 1.5;
    if (wsfu <= 20) return 9 + (wsfu - 6) * 0.7;
    if (wsfu <= 50) return 19 + (wsfu - 20) * 0.5;
    if (wsfu <= 100) return 34 + (wsfu - 50) * 0.35;
    return 52 + (wsfu - 100) * 0.25;
  }

  // Design demand with building factor
  double get _designDemand {
    final factor = _buildingTypes[_buildingType]?.factor ?? 1.0;
    return _peakDemand * factor;
  }

  // Recommended meter size
  String get _recommendedSize {
    final demand = _designDemand;
    for (final meter in _meterSizes) {
      // Size for 80% of max capacity for safety margin
      if (demand <= meter.maxGPM * 0.8) {
        return meter.size;
      }
    }
    return '4" or larger';
  }

  // Get pressure loss for recommended size
  double get _pressureLoss {
    final size = _recommendedSize;
    for (final meter in _meterSizes) {
      if (meter.size == size) {
        // Proportional pressure loss
        final ratio = _designDemand / meter.maxGPM;
        return meter.pressureLoss * ratio * ratio; // Squared relationship
      }
    }
    return 10.0;
  }

  // Capacity usage percentage
  double get _capacityUsed {
    final size = _recommendedSize;
    for (final meter in _meterSizes) {
      if (meter.size == size) {
        return (_designDemand / meter.maxGPM) * 100;
      }
    }
    return 80;
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
          'Water Meter Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildDemandCard(colors),
          const SizedBox(height: 16),
          _buildWSFUCard(colors),
          const SizedBox(height: 16),
          _buildBuildingTypeCard(colors),
          const SizedBox(height: 16),
          _buildMeterTypeCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
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
          Text(
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Recommended Meter Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
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
                _buildResultRow(colors, 'Peak Demand', '${_peakDemand.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Design Demand', '${_designDemand.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Est. Pressure Loss', '${_pressureLoss.toStringAsFixed(1)} psi'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Capacity Used', '${_capacityUsed.toStringAsFixed(0)}%', highlight: true),
              ],
            ),
          ),
          if (_capacityUsed > 80) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consider next size up for future expansion',
                      style: TextStyle(color: colors.accentWarning, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemandCard(ZaftoColors colors) {
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
                '${_peakDemand.toStringAsFixed(0)} GPM',
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
                    value: _peakDemand,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _peakDemand = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'From water service sizing or fixture count',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildWSFUCard(ZaftoColors colors) {
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
            'WSFU (OPTIONAL)',
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
                '${_totalWSFU.toStringAsFixed(0)} WSFU',
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
                    value: _totalWSFU,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _totalWSFU = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated GPM from WSFU:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('${_estimatedGPM.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.name,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Factor: ${((_buildingTypes[_buildingType]?.factor ?? 1.0) * 100).toStringAsFixed(0)}% of peak',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterTypeCard(ZaftoColors colors) {
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
            'METER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._meterTypes.entries.map((entry) {
            final isSelected = _meterType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _meterType = entry.key);
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
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'METER SIZING TABLE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._meterSizes.map((meter) {
            final isRecommended = meter.size == _recommendedSize;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      meter.size,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${meter.maxGPM.toInt()} GPM',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meter.typical,
                      style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      textAlign: TextAlign.right,
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
                'AWWA M22 / IPC Appendix E',
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
            '• Size for 80% of max capacity\n'
            '• Pressure loss increases with flow\n'
            '• Verify with utility requirements\n'
            '• Displacement: best low-flow accuracy\n'
            '• Compound: wide flow range\n'
            '• Consider future expansion',
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
