import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Thrust Block Sizing Calculator - Design System v2.6
///
/// Calculates thrust block dimensions for underground piping.
/// Based on pipe size, pressure, fitting type, and soil conditions.
///
/// References: AWWA M45, DIPRA
class ThrustBlockScreen extends ConsumerStatefulWidget {
  const ThrustBlockScreen({super.key});
  @override
  ConsumerState<ThrustBlockScreen> createState() => _ThrustBlockScreenState();
}

class _ThrustBlockScreenState extends ConsumerState<ThrustBlockScreen> {
  // Pipe size (inches)
  double _pipeSize = 6;

  // Test pressure (PSI)
  double _pressure = 150;

  // Fitting type
  String _fittingType = '90_bend';

  // Soil type
  String _soilType = 'clay';

  static const Map<String, ({String desc, double thrustFactor})> _fittingTypes = {
    '90_bend': (desc: '90° Bend', thrustFactor: 1.414),
    '45_bend': (desc: '45° Bend', thrustFactor: 0.765),
    '22_bend': (desc: '22½° Bend', thrustFactor: 0.390),
    '11_bend': (desc: '11¼° Bend', thrustFactor: 0.196),
    'tee': (desc: 'Tee (Branch)', thrustFactor: 1.0),
    'dead_end': (desc: 'Dead End/Cap', thrustFactor: 1.0),
    'reducer': (desc: 'Reducer', thrustFactor: 0.5),
  };

  static const Map<String, ({String desc, int bearingPsf})> _soilTypes = {
    'muck': (desc: 'Muck/Peat', bearingPsf: 0),
    'soft_clay': (desc: 'Soft Clay', bearingPsf: 500),
    'clay': (desc: 'Sandy Clay', bearingPsf: 1000),
    'sand': (desc: 'Sand', bearingPsf: 1500),
    'gravel': (desc: 'Sand & Gravel', bearingPsf: 2000),
    'hardpan': (desc: 'Hardpan', bearingPsf: 3000),
  };

  // Pipe area (sq inches)
  double get _pipeArea => 3.14159 * (_pipeSize / 2) * (_pipeSize / 2);

  // Thrust force (lbs)
  double get _thrustForce {
    final factor = _fittingTypes[_fittingType]?.thrustFactor ?? 1.0;
    return _pipeArea * _pressure * factor;
  }

  // Soil bearing capacity (psf)
  int get _bearingCapacity => _soilTypes[_soilType]?.bearingPsf ?? 1000;

  // Required bearing area (sq ft)
  double get _bearingArea {
    if (_bearingCapacity <= 0) return 0;
    return _thrustForce / _bearingCapacity;
  }

  // Block dimensions (assuming square)
  double get _blockSize => _bearingArea > 0 ? ((_bearingArea).abs()).clamp(0.1, 100).toDouble().sqrt() : 0;

  // Block thickness (minimum 6", typically 12" for larger pipes)
  int get _blockThickness => _pipeSize >= 6 ? 12 : 6;

  // Concrete volume (cubic feet)
  double get _concreteVolume => _bearingArea * (_blockThickness / 12);

  // Concrete volume (cubic yards)
  double get _concreteYards => _concreteVolume / 27;

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
          'Thrust Block Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildFittingCard(colors),
          const SizedBox(height: 16),
          _buildSoilCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final inadequateSoil = _bearingCapacity <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (inadequateSoil) ...[
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 48),
            const SizedBox(height: 8),
            Text(
              'Unsuitable Soil',
              style: TextStyle(
                color: colors.accentError,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Requires restrained joints or piles',
              style: TextStyle(color: colors.textTertiary, fontSize: 14),
            ),
          ] else ...[
            Text(
              '${_blockSize.toStringAsFixed(1)}\' × ${_blockSize.toStringAsFixed(1)}\'',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
            Text(
              'Minimum Block Size',
              style: TextStyle(color: colors.textTertiary, fontSize: 14),
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
                _buildResultRow(colors, 'Thrust Force', '${_thrustForce.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Bearing Area', '${_bearingArea.toStringAsFixed(2)} sq ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Block Thickness', '$_blockThickness\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Concrete Volume', '${_concreteYards.toStringAsFixed(2)} cu yd'),
              ],
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nominal Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeSize.toStringAsFixed(0)}\"',
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
              value: _pipeSize,
              min: 2,
              max: 24,
              divisions: 22,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeSize = v);
              },
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
            'TEST PRESSURE',
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
              Text('Maximum Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pressure.toStringAsFixed(0)} PSI',
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
              value: _pressure,
              min: 50,
              max: 300,
              divisions: 25,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pressure = v);
              },
            ),
          ),
          Text(
            'Use test pressure (1.5× working) for design',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFittingCard(ZaftoColors colors) {
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
            'FITTING TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fittingTypes.entries.map((entry) {
            final isSelected = _fittingType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _fittingType = entry.key);
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
                        '${entry.value.thrustFactor}×',
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

  Widget _buildSoilCard(ZaftoColors colors) {
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
            'SOIL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._soilTypes.entries.map((entry) {
            final isSelected = _soilType == entry.key;
            final isMuck = entry.key == 'muck';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _soilType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                    border: isMuck ? Border.all(color: colors.accentError.withValues(alpha: 0.5)) : null,
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
                        entry.value.bearingPsf > 0 ? '${entry.value.bearingPsf} psf' : 'N/A',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : (isMuck ? colors.accentError : colors.textTertiary),
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
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.mountain, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'AWWA M45',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Pour against undisturbed soil\n'
            '• 2500 PSI minimum concrete\n'
            '• Allow 7 days cure before testing\n'
            '• Polyethylene sheet between pipe\n'
            '• Consider restrained joints alternative\n'
            '• Verify soil conditions in field',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double sqrt() => this <= 0 ? 0 : this.toDouble().pow(0.5);
  double pow(double exponent) {
    if (this <= 0) return 0;
    return this.toDouble().pow(exponent);
  }
}
