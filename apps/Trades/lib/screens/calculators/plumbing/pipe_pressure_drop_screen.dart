import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pipe Pressure Drop Calculator - Design System v2.6
///
/// Calculates friction loss in water pipes using Hazen-Williams formula.
/// Essential for proper pipe sizing and pump selection.
///
/// References: IPC Appendix E, ASHRAE Handbook
class PipePressureDropScreen extends ConsumerStatefulWidget {
  const PipePressureDropScreen({super.key});
  @override
  ConsumerState<PipePressureDropScreen> createState() => _PipePressureDropScreenState();
}

class _PipePressureDropScreenState extends ConsumerState<PipePressureDropScreen> {
  // Flow rate (GPM)
  double _flowRate = 10.0;

  // Pipe diameter (inches)
  double _pipeDiameter = 0.75;

  // Pipe length (feet)
  double _pipeLength = 100.0;

  // Pipe material (affects C factor)
  String _pipeMaterial = 'copper';

  // Include fittings
  bool _includeFittings = true;

  // Number of each fitting type
  int _elbows90 = 4;
  int _elbows45 = 0;
  int _tees = 2;
  int _valves = 2;

  // Hazen-Williams C factors
  static const Map<String, ({int c, String desc})> _cFactors = {
    'copper': (c: 140, desc: 'Copper tube'),
    'pex': (c: 140, desc: 'PEX tubing'),
    'cpvc': (c: 140, desc: 'CPVC'),
    'newSteel': (c: 120, desc: 'New steel/iron'),
    'oldSteel': (c: 100, desc: 'Corroded steel'),
    'galvanized': (c: 120, desc: 'Galvanized'),
    'pvc': (c: 150, desc: 'PVC Schedule 40'),
  };

  // Common pipe sizes with actual ID
  static final Map<double, double> _pipeID = {
    0.5: 0.545,
    0.75: 0.785,
    1.0: 1.025,
    1.25: 1.265,
    1.5: 1.505,
    2.0: 1.985,
    2.5: 2.465,
    3.0: 2.945,
    4.0: 3.935,
  };

  // Equivalent length of fittings (in pipe diameters)
  static const Map<String, double> _fittingEquivalent = {
    'elbow90': 30, // 30 pipe diameters
    'elbow45': 16,
    'tee': 60,
    'gateValve': 8,
    'checkValve': 100,
    'ballValve': 3,
  };

  double get _actualID {
    return _pipeID[_pipeDiameter] ?? _pipeDiameter;
  }

  double get _cFactor {
    return (_cFactors[_pipeMaterial]?.c ?? 140).toDouble();
  }

  // Equivalent length from fittings (feet)
  double get _fittingEquivalentLength {
    if (!_includeFittings) return 0;
    // Convert from pipe diameters to feet
    final pipeDiaFt = _actualID / 12;
    final elbowLen = _elbows90 * _fittingEquivalent['elbow90']! * pipeDiaFt;
    final elbow45Len = _elbows45 * _fittingEquivalent['elbow45']! * pipeDiaFt;
    final teeLen = _tees * _fittingEquivalent['tee']! * pipeDiaFt;
    final valveLen = _valves * _fittingEquivalent['gateValve']! * pipeDiaFt;
    return elbowLen + elbow45Len + teeLen + valveLen;
  }

  double get _totalEquivalentLength {
    return _pipeLength + _fittingEquivalentLength;
  }

  // Hazen-Williams pressure drop (psi per 100 ft)
  // ΔP = 4.52 × Q^1.85 / (C^1.85 × d^4.87)
  double get _pressureDropPer100ft {
    final q = _flowRate;
    final c = _cFactor;
    final d = _actualID;

    if (d <= 0) return 0;

    // Hazen-Williams formula
    final numerator = 4.52 * _pow(q, 1.85);
    final denominator = _pow(c, 1.85) * _pow(d, 4.87);

    if (denominator <= 0) return 0;
    return numerator / denominator;
  }

  double get _totalPressureDrop {
    return _pressureDropPer100ft * _totalEquivalentLength / 100;
  }

  // Velocity (fps)
  double get _velocity {
    final areaSqIn = 3.14159 * (_actualID / 2) * (_actualID / 2);
    final areaSqFt = areaSqIn / 144;
    final flowCFS = _flowRate / 448.831;
    if (areaSqFt <= 0) return 0;
    return flowCFS / areaSqFt;
  }

  // Helper power function
  double _pow(double base, double exp) {
    if (base <= 0) return 0;
    // Use natural log for fractional exponents
    // x^y = e^(y*ln(x))
    final lnBase = _ln(base);
    return _exp(exp * lnBase);
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    double sum = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    for (int i = 1; i <= 50; i += 2) {
      sum += currentTerm / i;
      currentTerm *= termSquared;
    }
    return 2 * sum;
  }

  double _exp(double x) {
    double sum = 1;
    double term = 1;
    for (int i = 1; i <= 30; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }

  String get _velocityAssessment {
    if (_velocity > 8) return 'HIGH VELOCITY';
    if (_velocity < 2) return 'LOW VELOCITY';
    return 'ACCEPTABLE';
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
          'Pressure Drop',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildPipeCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          _buildFittingsCard(colors),
          const SizedBox(height: 16),
          _buildBreakdown(colors),
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
                _totalPressureDrop.toStringAsFixed(1),
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
                  ' psi',
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
            'Total Friction Loss',
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
                _buildResultRow(colors, 'Loss per 100 ft', '${_pressureDropPer100ft.toStringAsFixed(2)} psi'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Equiv. Length', '${_totalEquivalentLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Velocity', '${_velocity.toStringAsFixed(1)} fps'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Assessment', _velocityAssessment, highlight: true),
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
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipeCard(ZaftoColors colors) {
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
            'PIPE SIZE & LENGTH',
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
            children: _pipeID.keys.map((size) {
              final isSelected = _pipeDiameter == size;
              String label;
              if (size == 0.5) label = '1/2"';
              else if (size == 0.75) label = '3/4"';
              else if (size == 1.25) label = '1-1/4"';
              else if (size == 1.5) label = '1-1/2"';
              else if (size == 2.5) label = '2-1/2"';
              else label = '${size.toInt()}"';

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeDiameter = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_pipeLength.toStringAsFixed(0)} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
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
                    max: 500,
                    divisions: 49,
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
            'Total pipe run length',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
            'PIPE MATERIAL (C FACTOR)',
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
            children: _cFactors.entries.map((entry) {
              final isSelected = _pipeMaterial == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeMaterial = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'C=${entry.value.c}',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 9,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FITTINGS',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _includeFittings = !_includeFittings);
                },
                child: Row(
                  children: [
                    Icon(
                      _includeFittings ? LucideIcons.checkSquare : LucideIcons.square,
                      color: _includeFittings ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Include',
                      style: TextStyle(
                        color: _includeFittings ? colors.accentPrimary : colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_includeFittings) ...[
            const SizedBox(height: 16),
            _buildFittingRow(colors, '90\u00B0 Elbows', _elbows90, (v) => setState(() => _elbows90 = v)),
            _buildFittingRow(colors, '45\u00B0 Elbows', _elbows45, (v) => setState(() => _elbows45 = v)),
            _buildFittingRow(colors, 'Tees', _tees, (v) => setState(() => _tees = v)),
            _buildFittingRow(colors, 'Gate Valves', _valves, (v) => setState(() => _valves = v)),
            const SizedBox(height: 8),
            Text(
              'Adds ${_fittingEquivalentLength.toStringAsFixed(1)} ft equivalent length',
              style: TextStyle(color: colors.textTertiary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFittingRow(ZaftoColors colors, String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
          _buildCounterButton(colors, LucideIcons.minus, () {
            if (value > 0) onChanged(value - 1);
          }),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _buildCounterButton(colors, LucideIcons.plus, () {
            onChanged(value + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildCounterButton(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildBreakdown(ZaftoColors colors) {
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
            'CALCULATION BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pipe Run', '${_pipeLength.toStringAsFixed(0)} ft'),
          const SizedBox(height: 6),
          _buildResultRow(colors, 'Fittings Equiv.', '+ ${_fittingEquivalentLength.toStringAsFixed(1)} ft'),
          Divider(color: colors.borderSubtle, height: 16),
          _buildResultRow(colors, 'Total Equiv. Length', '${_totalEquivalentLength.toStringAsFixed(1)} ft', highlight: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Hazen-Williams C', _cFactor.toStringAsFixed(0)),
          _buildResultRow(colors, 'Pipe ID', '${_actualID.toStringAsFixed(3)}"'),
          _buildResultRow(colors, 'Flow', '${_flowRate.toStringAsFixed(1)} GPM'),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? colors.accentPrimary : colors.textPrimary,
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
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
                'Hazen-Williams Formula',
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
            '• \u0394P = 4.52 \u00d7 Q\u00b9\u00b7\u2078\u2075 / (C\u00b9\u00b7\u2078\u2075 \u00d7 d\u2074\u00b7\u2078\u2077)\n'
            '• C factor: roughness coefficient\n'
            '• Higher C = smoother pipe = less loss\n'
            '• Old pipes have lower C (more friction)\n'
            '• Fittings add equivalent pipe length\n'
            '• Keep velocity under 8 fps',
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
