import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Gas Pressure Drop Calculator - Design System v2.6
///
/// Calculates pressure drop in gas piping systems.
/// Verifies adequate pressure at appliance connections.
///
/// References: IFGC 2024, NFPA 54, Natural Fuel Gas Code
class GasPressureDropScreen extends ConsumerStatefulWidget {
  const GasPressureDropScreen({super.key});
  @override
  ConsumerState<GasPressureDropScreen> createState() => _GasPressureDropScreenState();
}

class _GasPressureDropScreenState extends ConsumerState<GasPressureDropScreen> {
  // Inlet pressure (inches WC)
  double _inletPressure = 7.0;

  // Flow rate (CFH)
  double _cfh = 200;

  // Pipe size (inches)
  String _pipeSize = '3/4';

  // Pipe length (feet)
  double _pipeLength = 50;

  // Number of fittings (equivalent length added)
  int _fittings = 5;

  // Pipe material
  String _material = 'black_iron';

  // Gas type
  String _gasType = 'natural';

  // Pipe sizes and friction factors (simplified)
  static const List<String> _pipeSizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2'];

  // Approximate capacity at 0.5" drop per 100' (CFH) - simplified
  static const Map<String, int> _pipeCapacity = {
    '1/2': 80,
    '3/4': 175,
    '1': 360,
    '1-1/4': 750,
    '1-1/2': 1150,
    '2': 2100,
  };

  static const Map<String, String> _materials = {
    'black_iron': 'Black Iron (Schedule 40)',
    'copper': 'Copper (Type K/L)',
    'csst': 'CSST (Corrugated SS)',
    'pe': 'PE Plastic (outdoor)',
  };

  // Equivalent length per fitting (feet)
  static const Map<String, double> _fittingLength = {
    '1/2': 1.5,
    '3/4': 2.0,
    '1': 2.5,
    '1-1/4': 3.0,
    '1-1/2': 4.0,
    '2': 5.0,
  };

  double get _totalEquivalentLength {
    final fittingEq = (_fittingLength[_pipeSize] ?? 2.0) * _fittings;
    return _pipeLength + fittingEq;
  }

  // Simplified pressure drop calculation
  // Based on capacity tables - actual calc is complex
  double get _pressureDrop {
    final capacity = _pipeCapacity[_pipeSize] ?? 175;
    // Pressure drop varies with square of flow
    final flowRatio = _cfh / capacity;
    // Base drop is 0.5" WC per 100' at rated capacity
    final baseDrop = 0.5 * (flowRatio * flowRatio);
    return baseDrop * (_totalEquivalentLength / 100);
  }

  double get _deliveredPressure {
    return _inletPressure - _pressureDrop;
  }

  String get _pressureStatus {
    if (_deliveredPressure < 3.5) return 'TOO LOW - Increase pipe size';
    if (_deliveredPressure < 5.0) return 'MARGINAL - Consider larger pipe';
    if (_deliveredPressure > 14.0) return 'HIGH - Check regulator';
    return 'ADEQUATE';
  }

  Color _getStatusColor(ZaftoColors colors) {
    if (_deliveredPressure < 3.5) return colors.accentError;
    if (_deliveredPressure < 5.0) return colors.accentWarning;
    return colors.accentSuccess;
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
          'Gas Pressure Drop',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildInletPressureCard(colors),
          const SizedBox(height: 16),
          _buildFlowRateCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildPipeLengthCard(colors),
          const SizedBox(height: 16),
          _buildFittingsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = _getStatusColor(colors);

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
            '${_deliveredPressure.toStringAsFixed(2)}" WC',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Delivered Pressure',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _pressureStatus,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
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
                _buildResultRow(colors, 'Inlet Pressure', '${_inletPressure.toStringAsFixed(1)}" WC'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pressure Drop', '-${_pressureDrop.toStringAsFixed(2)}" WC'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Delivered', '${_deliveredPressure.toStringAsFixed(2)}" WC', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Length', '${_totalEquivalentLength.toStringAsFixed(0)} ft (equiv.)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInletPressureCard(ZaftoColors colors) {
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
            'INLET PRESSURE (INCHES WC)',
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
                '${_inletPressure.toStringAsFixed(1)}" WC',
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
                    value: _inletPressure,
                    min: 3.5,
                    max: 14,
                    divisions: 21,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _inletPressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '7" WC typical residential (after regulator)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRateCard(ZaftoColors colors) {
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
            'FLOW RATE (CFH)',
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
                '${_cfh.toStringAsFixed(0)} CFH',
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
                    value: _cfh,
                    min: 20,
                    max: 500,
                    divisions: 48,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _cfh = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'BTU ÷ 1000 = CFH for natural gas',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
            'PIPE SIZE',
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
            children: _pipeSizes.map((size) {
              final isSelected = _pipeSize == size;
              final capacity = _pipeCapacity[size] ?? 0;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$size"',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$capacity CFH',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeLengthCard(ZaftoColors colors) {
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
            'PIPE LENGTH (FEET)',
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
                '${_pipeLength.toStringAsFixed(0)} ft',
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
                    value: _pipeLength,
                    min: 10,
                    max: 200,
                    divisions: 38,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _pipeLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Measured pipe run (fittings added automatically)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFittingsCard(ZaftoColors colors) {
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
            'NUMBER OF FITTINGS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(8, (i) {
              final count = i;
              final isSelected = _fittings == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _fittings = count);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Equiv. length: ${(_fittingLength[_pipeSize] ?? 2.0) * _fittings} ft added',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
                'IFGC 2024 / NFPA 54',
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
            '• Max drop: 0.5" WC per 100 ft typical\n'
            '• Min delivered pressure: 3.5" WC\n'
            '• 7" WC standard residential delivery\n'
            '• Add fittings as equivalent length\n'
            '• Use IFGC tables for exact sizing\n'
            '• Verify with manometer test',
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
