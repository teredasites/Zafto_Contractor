import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// RPZ Sizing Calculator - Design System v2.6
///
/// Sizes Reduced Pressure Zone backflow preventers.
/// Calculates pressure loss and installation requirements.
///
/// References: IPC 2024 Section 608, ASSE 1013
class RpzSizingScreen extends ConsumerStatefulWidget {
  const RpzSizingScreen({super.key});
  @override
  ConsumerState<RpzSizingScreen> createState() => _RpzSizingScreenState();
}

class _RpzSizingScreenState extends ConsumerState<RpzSizingScreen> {
  // Flow rate (GPM)
  double _flowRate = 50;

  // Supply pressure (PSI)
  double _supplyPressure = 60;

  // Required downstream pressure (PSI)
  double _requiredPressure = 40;

  // Installation location
  String _installLocation = 'indoor';

  static const Map<String, ({String desc, int minHeight, int maxHeight})> _installLocations = {
    'indoor': (desc: 'Indoor - Heated', minHeight: 12, maxHeight: 60),
    'outdoor': (desc: 'Outdoor - Enclosure', minHeight: 12, maxHeight: 60),
    'pit': (desc: 'Below Grade Vault', minHeight: 12, maxHeight: 48),
  };

  // RPZ sizes and capacities
  static const Map<String, ({int size, double maxGpm, double pressureLoss})> _rpzSizes = {
    '0.75': (size: 75, maxGpm: 25, pressureLoss: 12),
    '1.0': (size: 100, maxGpm: 50, pressureLoss: 10),
    '1.25': (size: 125, maxGpm: 75, pressureLoss: 9),
    '1.5': (size: 150, maxGpm: 100, pressureLoss: 8),
    '2.0': (size: 200, maxGpm: 160, pressureLoss: 7),
    '2.5': (size: 250, maxGpm: 250, pressureLoss: 6),
    '3.0': (size: 300, maxGpm: 400, pressureLoss: 5),
    '4.0': (size: 400, maxGpm: 640, pressureLoss: 5),
    '6.0': (size: 600, maxGpm: 1400, pressureLoss: 4),
  };

  // Recommended RPZ size
  String get _recommendedSize {
    for (final entry in _rpzSizes.entries) {
      if (entry.value.maxGpm >= _flowRate) {
        return '${entry.key}\"';
      }
    }
    return '6\"+ (Consult engineer)';
  }

  // Pressure loss
  double get _pressureLoss {
    for (final entry in _rpzSizes.entries) {
      if (entry.value.maxGpm >= _flowRate) {
        return entry.value.pressureLoss.toDouble();
      }
    }
    return 15;
  }

  // Downstream pressure
  double get _downstreamPressure => _supplyPressure - _pressureLoss;

  // Pressure adequate
  bool get _pressureAdequate => _downstreamPressure >= _requiredPressure;

  // Relief valve discharge (GPM at full failure)
  double get _reliefDischarge => _flowRate * 0.3;

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
          'RPZ Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final location = _installLocations[_installLocation];

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
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'RPZ Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!_pressureAdequate) ...[
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
                    'Insufficient downstream pressure',
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
                _buildResultRow(colors, 'Flow Rate', '${_flowRate.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pressure Loss', '${_pressureLoss.toStringAsFixed(0)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Downstream Pressure', '${_downstreamPressure.toStringAsFixed(0)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Relief Discharge', '${_reliefDischarge.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Install Height', '${location?.minHeight ?? 12}\"-${location?.maxHeight ?? 60}\" AFF'),
              ],
            ),
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
            'FLOW RATE',
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
              Text('Design Flow', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_flowRate.toStringAsFixed(0)} GPM',
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
              value: _flowRate,
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _flowRate = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [25, 50, 100, 200, 400].map((flow) {
              final isSelected = (_flowRate - flow).abs() < 10;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _flowRate = flow.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$flow GPM',
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
            'PRESSURE',
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
              Text('Supply Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_supplyPressure.toStringAsFixed(0)} PSI',
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
              value: _supplyPressure,
              min: 30,
              max: 100,
              divisions: 70,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _supplyPressure = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Required Downstream', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_requiredPressure.toStringAsFixed(0)} PSI',
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
              value: _requiredPressure,
              min: 20,
              max: 80,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _requiredPressure = v);
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
          ..._installLocations.entries.map((entry) {
            final isSelected = _installLocation == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _installLocation = entry.key);
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
                        '${entry.value.minHeight}-${entry.value.maxHeight}\"',
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
              Icon(LucideIcons.shieldCheck, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 / ASSE 1013',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Install 12-60\" AFF (indoor)\n'
            '• Provide adequate drainage\n'
            '• Annual test required\n'
            '• Accessible for maintenance\n'
            '• Freeze protection if outdoor\n'
            '• No valve downstream of relief',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
