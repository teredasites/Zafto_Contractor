import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Velocity Calculator - Design System v2.6
///
/// Calculates water velocity in pipes. Critical for avoiding water hammer,
/// noise, and pipe erosion. Helps verify pipe sizing.
///
/// References: IPC Appendix E, ASHRAE guidelines
class WaterVelocityScreen extends ConsumerStatefulWidget {
  const WaterVelocityScreen({super.key});
  @override
  ConsumerState<WaterVelocityScreen> createState() => _WaterVelocityScreenState();
}

class _WaterVelocityScreenState extends ConsumerState<WaterVelocityScreen> {
  // Flow rate (GPM)
  double _flowRate = 10.0;

  // Pipe diameter (inches - inside diameter)
  double _pipeDiameter = 0.75;

  // Pipe material
  String _pipeMaterial = 'copper';

  // Common pipe sizes (actual ID varies by material)
  static const Map<String, List<({double nominal, double id, String label})>> _pipeSizes = {
    'copper': [
      (nominal: 0.5, id: 0.545, label: '1/2" Type M'),
      (nominal: 0.75, id: 0.785, label: '3/4" Type M'),
      (nominal: 1.0, id: 1.025, label: '1" Type M'),
      (nominal: 1.25, id: 1.265, label: '1-1/4" Type M'),
      (nominal: 1.5, id: 1.505, label: '1-1/2" Type M'),
      (nominal: 2.0, id: 1.985, label: '2" Type M'),
    ],
    'cpvc': [
      (nominal: 0.5, id: 0.485, label: '1/2" CTS'),
      (nominal: 0.75, id: 0.655, label: '3/4" CTS'),
      (nominal: 1.0, id: 0.875, label: '1" CTS'),
      (nominal: 1.25, id: 1.095, label: '1-1/4" CTS'),
      (nominal: 1.5, id: 1.315, label: '1-1/2" CTS'),
      (nominal: 2.0, id: 1.755, label: '2" CTS'),
    ],
    'pex': [
      (nominal: 0.375, id: 0.36, label: '3/8" PEX'),
      (nominal: 0.5, id: 0.475, label: '1/2" PEX'),
      (nominal: 0.625, id: 0.574, label: '5/8" PEX'),
      (nominal: 0.75, id: 0.671, label: '3/4" PEX'),
      (nominal: 1.0, id: 0.862, label: '1" PEX'),
      (nominal: 1.25, id: 1.043, label: '1-1/4" PEX'),
      (nominal: 1.5, id: 1.293, label: '1-1/2" PEX'),
      (nominal: 2.0, id: 1.693, label: '2" PEX'),
    ],
    'galvanized': [
      (nominal: 0.5, id: 0.622, label: '1/2" Sch 40'),
      (nominal: 0.75, id: 0.824, label: '3/4" Sch 40'),
      (nominal: 1.0, id: 1.049, label: '1" Sch 40'),
      (nominal: 1.25, id: 1.380, label: '1-1/4" Sch 40'),
      (nominal: 1.5, id: 1.610, label: '1-1/2" Sch 40'),
      (nominal: 2.0, id: 2.067, label: '2" Sch 40'),
    ],
  };

  // Max velocities by application
  static const Map<String, double> _maxVelocities = {
    'Cold Water Supply': 8.0,
    'Hot Water Supply': 5.0,
    'Hot Water Recirc': 4.0,
    'Suction Line': 4.0,
    'Discharge Line': 8.0,
    'Fire Sprinkler': 20.0,
    'Chilled Water': 10.0,
  };

  List<({double nominal, double id, String label})> get _currentPipeSizes {
    return _pipeSizes[_pipeMaterial] ?? _pipeSizes['copper']!;
  }

  double get _selectedID {
    final sizes = _currentPipeSizes;
    for (final size in sizes) {
      if (size.nominal == _pipeDiameter) {
        return size.id;
      }
    }
    return _pipeDiameter; // Fallback to nominal
  }

  // Cross-sectional area in square feet
  double get _crossSectionAreaSqFt {
    final radiusInches = _selectedID / 2;
    final areaSqIn = 3.14159 * radiusInches * radiusInches;
    return areaSqIn / 144; // Convert to sq ft
  }

  // Flow in cubic feet per second
  double get _flowCFS {
    // GPM to CFS: GPM / 448.831
    return _flowRate / 448.831;
  }

  // Velocity in feet per second
  double get _velocity {
    if (_crossSectionAreaSqFt <= 0) return 0;
    return _flowCFS / _crossSectionAreaSqFt;
  }

  // Velocity assessment
  String get _velocityAssessment {
    if (_velocity < 2) return 'LOW - May cause sediment deposits';
    if (_velocity > 10) return 'HIGH - Water hammer risk, noise, erosion';
    if (_velocity > 8) return 'ELEVATED - Acceptable but may be noisy';
    if (_velocity > 5) return 'MODERATE - Good for cold water';
    return 'OPTIMAL - Ideal range';
  }

  Color _velocityColor(ZaftoColors colors) {
    if (_velocity < 2 || _velocity > 10) return colors.accentError;
    if (_velocity > 8) return colors.accentWarning;
    return colors.accentSuccess;
  }

  // Reynolds number (simplified - water at 60°F)
  double get _reynoldsNumber {
    // Re = V * D / ν where ν ≈ 1.22 × 10⁻⁵ ft²/s for water at 60°F
    final diameterFt = _selectedID / 12;
    return _velocity * diameterFt / 0.0000122;
  }

  String get _flowRegime {
    if (_reynoldsNumber < 2300) return 'Laminar';
    if (_reynoldsNumber < 4000) return 'Transitional';
    return 'Turbulent';
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
          'Water Velocity',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildFlowRateCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildVelocityLimits(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _velocity.toStringAsFixed(1),
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' fps',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Water Velocity',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _velocityColor(colors).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _velocityAssessment,
              style: TextStyle(
                color: _velocityColor(colors),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                _buildResultRow(colors, 'Flow Rate', '${_flowRate.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pipe ID', '${_selectedID.toStringAsFixed(3)}"'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Cross Section', '${(_crossSectionAreaSqFt * 144).toStringAsFixed(3)} sq in'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Flow Regime', _flowRegime, highlight: true),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Reynolds #', _reynoldsNumber > 10000 ? '${(_reynoldsNumber / 1000).toStringAsFixed(0)}k' : _reynoldsNumber.toStringAsFixed(0)),
              ],
            ),
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
            children: [
              Text(
                '${_flowRate.toStringAsFixed(1)} GPM',
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
                    value: _flowRate,
                    min: 0.5,
                    max: 100,
                    divisions: 199,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Gallons per minute through pipe',
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
            children: [
              ('copper', 'Copper'),
              ('cpvc', 'CPVC'),
              ('pex', 'PEX'),
              ('galvanized', 'Galvanized'),
            ].map((entry) {
              final isSelected = _pipeMaterial == entry.$1;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _pipeMaterial = entry.$1;
                    // Reset to first available size
                    final sizes = _pipeSizes[entry.$1];
                    if (sizes != null && sizes.isNotEmpty) {
                      _pipeDiameter = sizes.first.nominal;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.$2,
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
          ..._currentPipeSizes.map((size) {
            final isSelected = _pipeDiameter == size.nominal;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _pipeDiameter = size.nominal);
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
                      child: Text(
                        size.label,
                        style: TextStyle(
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'ID: ${size.id}"',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
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

  Widget _buildVelocityLimits(ZaftoColors colors) {
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
            'MAX VELOCITY BY APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._maxVelocities.entries.map((entry) {
            final isOver = _velocity > entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.key,
                      style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value.toInt()} fps',
                      style: TextStyle(
                        color: isOver ? colors.accentError : colors.accentSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isOver ? LucideIcons.alertCircle : LucideIcons.checkCircle,
                    color: isOver ? colors.accentError : colors.accentSuccess,
                    size: 14,
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
                'ASHRAE / Industry Standards',
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
            '• V = Q / A (velocity = flow / area)\n'
            '• Max 8 fps cold, 5 fps hot water\n'
            '• Min 2 fps to prevent sediment\n'
            '• Higher velocity = more friction loss\n'
            '• Water hammer risk above 10 fps\n'
            '• Noise increases with velocity',
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
