import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Air Gap Calculator - Design System v2.6
///
/// Calculates required air gap dimensions for backflow prevention.
/// Covers indirect waste, potable water, and drainage applications.
///
/// References: IPC 2024 Section 608.15, 890
class AirGapScreen extends ConsumerStatefulWidget {
  const AirGapScreen({super.key});
  @override
  ConsumerState<AirGapScreen> createState() => _AirGapScreenState();
}

class _AirGapScreenState extends ConsumerState<AirGapScreen> {
  // Supply pipe diameter (inches)
  double _supplyDiameter = 0.5;

  // Application type
  String _applicationType = 'potable';

  // Distance to wall (inches)
  double _wallDistance = 6;

  static const Map<String, ({String desc, double multiplier})> _applicationTypes = {
    'potable': (desc: 'Potable Water Supply', multiplier: 2.0),
    'indirect': (desc: 'Indirect Waste', multiplier: 2.0),
    'dishwasher': (desc: 'Dishwasher Drain', multiplier: 1.0),
    'food_prep': (desc: 'Food Prep Sink', multiplier: 2.0),
    'ice_machine': (desc: 'Ice Machine', multiplier: 2.0),
    'condensate': (desc: 'Condensate Drain', multiplier: 1.0),
  };

  // Standard pipe sizes
  static const List<double> _pipeSizes = [0.375, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0];

  // Minimum air gap (inches)
  double get _minimumAirGap {
    final multiplier = _applicationTypes[_applicationType]?.multiplier ?? 2.0;
    final calculated = _supplyDiameter * multiplier;

    // Wall effect - if within 3× diameter, increase gap
    if (_wallDistance < (_supplyDiameter * 3)) {
      return calculated * 1.5;
    }

    // Minimum 1" for any application
    return calculated < 1.0 ? 1.0 : calculated;
  }

  // Recommended air gap (with safety factor)
  double get _recommendedAirGap => _minimumAirGap * 1.25;

  // Wall effect warning
  bool get _wallEffect => _wallDistance < (_supplyDiameter * 3);

  // Standard air gap fitting size
  String get _standardFitting {
    if (_supplyDiameter <= 0.5) return '½\" inlet';
    if (_supplyDiameter <= 0.75) return '¾\" inlet';
    if (_supplyDiameter <= 1.0) return '1\" inlet';
    return 'Custom fabricated';
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
          'Air Gap Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildWallDistanceCard(colors),
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
            '${_recommendedAirGap.toStringAsFixed(2)}\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Air Gap',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_wallEffect) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Wall effect - increased gap required',
                    style: TextStyle(color: colors.accentWarning, fontSize: 11),
                  ),
                ],
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
                _buildResultRow(colors, 'Code Minimum', '${_minimumAirGap.toStringAsFixed(2)}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Diameter', '${_supplyDiameter}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Multiplier', '${_applicationTypes[_applicationType]?.multiplier ?? 2.0}×'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Standard Fitting', _standardFitting),
              ],
            ),
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
            'APPLICATION',
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
            children: _applicationTypes.entries.map((entry) {
              final isSelected = _applicationType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _applicationType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
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
        ],
      ),
    );
  }

  Widget _buildPipeSizeCard(ZaftoColors colors) {
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
            'SUPPLY PIPE DIAMETER',
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
              Text('Pipe Size', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_supplyDiameter}\"',
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
              value: _pipeSizes.indexOf(_supplyDiameter).toDouble(),
              min: 0,
              max: (_pipeSizes.length - 1).toDouble(),
              divisions: _pipeSizes.length - 1,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _supplyDiameter = _pipeSizes[v.round()]);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 0.75, 1.0, 1.5, 2.0].map((size) {
              final isSelected = (_supplyDiameter - size).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _supplyDiameter = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$size\"',
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

  Widget _buildWallDistanceCard(ZaftoColors colors) {
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
            'WALL DISTANCE',
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
              Text('Distance to Wall', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_wallDistance.toStringAsFixed(1)}\"',
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
              value: _wallDistance,
              min: 0.5,
              max: 12,
              divisions: 23,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _wallDistance = v);
              },
            ),
          ),
          Text(
            'Wall effect occurs when < ${(_supplyDiameter * 3).toStringAsFixed(1)}\" from wall',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
              Icon(LucideIcons.droplet, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 608.15',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Min air gap = 2× effective opening\n'
            '• 1" absolute minimum\n'
            '• Wall effect increases requirement\n'
            '• No mechanical connection\n'
            '• Visible gap required\n'
            '• Receptor must be open to atmosphere',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
