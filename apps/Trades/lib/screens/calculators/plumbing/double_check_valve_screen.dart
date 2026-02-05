import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Double Check Valve Assembly Calculator - Design System v2.6
///
/// Sizes DCVA backflow preventers for low-hazard applications.
/// Calculates pressure loss and flow capacity.
///
/// References: IPC 2024 Section 608, ASSE 1015
class DoubleCheckValveScreen extends ConsumerStatefulWidget {
  const DoubleCheckValveScreen({super.key});
  @override
  ConsumerState<DoubleCheckValveScreen> createState() => _DoubleCheckValveScreenState();
}

class _DoubleCheckValveScreenState extends ConsumerState<DoubleCheckValveScreen> {
  // Flow rate (GPM)
  double _flowRate = 50;

  // Supply line size (inches)
  String _lineSize = '2.0';

  // Installation type
  String _installType = 'inline';

  static const Map<String, ({String desc, double factor})> _installTypes = {
    'inline': (desc: 'Inline Installation', factor: 1.0),
    'bypass': (desc: 'With Bypass', factor: 0.9),
    'strainer': (desc: 'With Strainer', factor: 1.2),
  };

  // DCVA sizes and capacities
  static const Map<String, ({double maxGpm, double pressureLoss, double cv})> _dcvaSizes = {
    '0.75': (maxGpm: 30, pressureLoss: 5, cv: 14),
    '1.0': (maxGpm: 50, pressureLoss: 4, cv: 25),
    '1.25': (maxGpm: 80, pressureLoss: 4, cv: 40),
    '1.5': (maxGpm: 115, pressureLoss: 3, cv: 65),
    '2.0': (maxGpm: 185, pressureLoss: 3, cv: 115),
    '2.5': (maxGpm: 285, pressureLoss: 2, cv: 180),
    '3.0': (maxGpm: 450, pressureLoss: 2, cv: 280),
    '4.0': (maxGpm: 750, pressureLoss: 2, cv: 500),
    '6.0': (maxGpm: 1600, pressureLoss: 1.5, cv: 1100),
  };

  // Recommended DCVA size
  String get _recommendedSize {
    for (final entry in _dcvaSizes.entries) {
      if (entry.value.maxGpm >= _flowRate) {
        return '${entry.key}\"';
      }
    }
    return '6\"+ (Consult engineer)';
  }

  // Pressure loss at design flow
  double get _pressureLoss {
    final dcva = _dcvaSizes[_lineSize];
    if (dcva == null) return 5;

    // Calculate using Cv: ΔP = (GPM/Cv)²
    final factor = _installTypes[_installType]?.factor ?? 1.0;
    return ((_flowRate / dcva.cv) * (_flowRate / dcva.cv)) * factor;
  }

  // Flow velocity (ft/s)
  double get _velocity {
    final diameter = double.tryParse(_lineSize) ?? 2.0;
    final area = 3.14159 * (diameter / 2) * (diameter / 2) / 144; // sq ft
    return (_flowRate / 7.48) / 60 / area;
  }

  // Velocity acceptable (< 10 ft/s)
  bool get _velocityOk => _velocity <= 10;

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
          'Double Check Valve',
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
          _buildLineSizeCard(colors),
          const SizedBox(height: 16),
          _buildInstallCard(colors),
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
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'DCVA Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!_velocityOk) ...[
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
                    'Velocity exceeds 10 ft/s - upsize',
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
                _buildResultRow(colors, 'Pressure Loss', '${_pressureLoss.toStringAsFixed(1)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Velocity', '${_velocity.toStringAsFixed(1)} ft/s'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Cv Rating', '${_dcvaSizes[_lineSize]?.cv ?? 115}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hazard Type', 'Low (Pollutant)'),
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
            children: [30, 50, 100, 200, 400].map((flow) {
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

  Widget _buildLineSizeCard(ZaftoColors colors) {
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
            'LINE SIZE',
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
            children: _dcvaSizes.keys.map((size) {
              final isSelected = _lineSize == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _lineSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size\"',
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

  Widget _buildInstallCard(ZaftoColors colors) {
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
            'INSTALLATION TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._installTypes.entries.map((entry) {
            final isSelected = _installType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _installType = entry.key);
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
              Icon(LucideIcons.checkCheck, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 / ASSE 1015',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Low hazard applications only\n'
            '• Annual test required\n'
            '• Install accessible location\n'
            '• No high-hazard connections\n'
            '• Fire sprinkler (no antifreeze)\n'
            '• Maintain test cock access',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
