import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Supply Pipe Sizing Calculator - Design System v2.6
///
/// Calculates pipe diameter based on GPM demand and flow rate.
/// Uses velocity method per IPC/UPC standards.
///
/// References: IPC 2024 Chapter 6, Table E103.3(2)
class WaterSupplyPipeScreen extends ConsumerStatefulWidget {
  const WaterSupplyPipeScreen({super.key});
  @override
  ConsumerState<WaterSupplyPipeScreen> createState() => _WaterSupplyPipeScreenState();
}

class _WaterSupplyPipeScreenState extends ConsumerState<WaterSupplyPipeScreen> {
  // Flow rate (GPM)
  double _gpm = 10;

  // Pipe material
  String _material = 'copper';

  // Maximum velocity (fps) - typically 5-8 for supply
  double _maxVelocity = 8;

  // Pipe materials with ID for common sizes
  static final Map<String, Map<String, double>> _pipeData = {
    'copper': {
      '1/2': 0.545,
      '3/4': 0.785,
      '1': 1.025,
      '1-1/4': 1.265,
      '1-1/2': 1.505,
      '2': 1.985,
      '2-1/2': 2.465,
      '3': 2.945,
    },
    'cpvc': {
      '1/2': 0.485,
      '3/4': 0.720,
      '1': 0.910,
      '1-1/4': 1.195,
      '1-1/2': 1.435,
      '2': 1.895,
    },
    'pex': {
      '3/8': 0.350,
      '1/2': 0.475,
      '5/8': 0.574,
      '3/4': 0.671,
      '1': 0.862,
      '1-1/4': 1.076,
      '1-1/2': 1.263,
      '2': 1.720,
    },
    'galvanized': {
      '1/2': 0.622,
      '3/4': 0.824,
      '1': 1.049,
      '1-1/4': 1.380,
      '1-1/2': 1.610,
      '2': 2.067,
      '2-1/2': 2.469,
      '3': 3.068,
    },
  };

  static const List<({String value, String label})> _materials = [
    (value: 'copper', label: 'Copper (Type L)'),
    (value: 'cpvc', label: 'CPVC'),
    (value: 'pex', label: 'PEX'),
    (value: 'galvanized', label: 'Galvanized'),
  ];

  /// Calculate required pipe size based on velocity method
  /// Q = A × V, where A = π × (D/2)²
  /// Solving for D: D = √(4Q / πV)
  String _calculatePipeSize() {
    // Convert GPM to cubic feet per second
    final cfs = _gpm / 448.831;

    // Calculate minimum area needed (sq ft)
    final minArea = cfs / _maxVelocity;

    // Calculate minimum diameter needed (ft then to inches)
    final minDiameterFt = 2 * (minArea / 3.14159).abs();
    final minDiameterIn = minDiameterFt > 0
        ? (minDiameterFt * 12 * 12).abs()
        : 0.0;
    final minDiameter = minDiameterIn > 0 ? (minDiameterIn).abs() : 0.0;

    // Actually recalculate properly
    // D = sqrt(4 * Q / (pi * V)) where Q in cfs, V in fps
    final diameterFt = (4 * cfs / (3.14159 * _maxVelocity)).abs();
    final diameterCalc = diameterFt > 0 ? (diameterFt * 12 * 12).abs() : 0.0;
    final minDiam = diameterCalc > 0 ? (diameterCalc).abs() : 0.0;

    // Simple approach: calculate area needed, find smallest pipe that works
    // Area = Q/V, D = sqrt(4*A/pi)
    final areaNeeded = cfs / _maxVelocity; // sq ft
    final dNeeded = 2 * _sqrt(areaNeeded / 3.14159) * 12; // inches

    // Find smallest pipe that meets requirement
    final pipes = _pipeData[_material] ?? {};
    String recommended = '';
    double recommendedId = 0;

    for (final entry in pipes.entries) {
      if (entry.value >= dNeeded && (recommendedId == 0 || entry.value < recommendedId)) {
        recommended = entry.key;
        recommendedId = entry.value;
      }
    }

    if (recommended.isEmpty && pipes.isNotEmpty) {
      // Use largest available
      recommended = pipes.keys.last;
    }

    return recommended.isEmpty ? 'N/A' : '$recommended"';
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  double _calculateVelocity(String pipeSize) {
    final id = _pipeData[_material]?[pipeSize.replaceAll('"', '')] ?? 0;
    if (id <= 0) return 0;

    // Area in sq ft
    final area = 3.14159 * (id / 12 / 2) * (id / 12 / 2);
    // Q in cfs
    final cfs = _gpm / 448.831;
    // V = Q/A
    return area > 0 ? cfs / area : 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final recommendedSize = _calculatePipeSize();

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
          'Water Supply Pipe Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, recommendedSize),
          const SizedBox(height: 16),
          _buildGpmCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildVelocityCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, String recommendedSize) {
    final velocity = _calculateVelocity(recommendedSize.replaceAll('"', ''));

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
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Pipe Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
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
                _buildResultRow(colors, 'Flow Rate', '${_gpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Material', _materials.firstWhere((m) => m.value == _material).label),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Velocity', '${_maxVelocity.toStringAsFixed(1)} fps'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Actual Velocity', '${velocity.toStringAsFixed(2)} fps', highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Status', velocity <= _maxVelocity ? 'OK ✓' : 'Too Fast'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpmCard(ZaftoColors colors) {
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
            'FLOW RATE (GPM)',
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
                '${_gpm.toStringAsFixed(1)} GPM',
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
                    value: _gpm,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _gpm = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Peak demand flow rate from WSFU calculation',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ZaftoColors colors) {
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
            'PIPE MATERIAL',
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
            children: _materials.map((mat) {
              final isSelected = _material == mat.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _material = mat.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mat.label,
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

  Widget _buildVelocityCard(ZaftoColors colors) {
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
            'MAXIMUM VELOCITY (FPS)',
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
                '${_maxVelocity.toStringAsFixed(1)} fps',
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
                    value: _maxVelocity,
                    min: 4,
                    max: 10,
                    divisions: 12,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _maxVelocity = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '5-8 fps typical for supply • Higher = more noise',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizeTable(ZaftoColors colors) {
    final pipes = _pipeData[_material] ?? {};

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
            'PIPE SIZE REFERENCE (${_materials.firstWhere((m) => m.value == _material).label.toUpperCase()})',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...pipes.entries.map((entry) {
            final velocity = _calculateVelocity(entry.key);
            final isRecommended = _calculatePipeSize() == '${entry.key}"';
            final meetsVelocity = velocity <= _maxVelocity;

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
                    width: 60,
                    child: Text(
                      '${entry.key}"',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'ID: ${entry.value.toStringAsFixed(3)}"',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${velocity.toStringAsFixed(1)} fps',
                      style: TextStyle(
                        color: meetsVelocity ? colors.textTertiary : colors.accentError,
                        fontSize: 12,
                      ),
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
                'IPC 2024 Chapter 6',
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
            '• Max velocity: 8 fps typical (IPC)\n'
            '• 5 fps recommended for noise control\n'
            '• Table E103.3(2) for sizing\n'
            '• Size up for long runs\n'
            '• Consider pressure drop at high flow\n'
            '• Verify with local AHJ',
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
