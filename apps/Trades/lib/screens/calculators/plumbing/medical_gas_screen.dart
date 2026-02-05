import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Medical Gas Piping Calculator - Design System v2.6
///
/// Calculates medical gas pipe sizing for healthcare facilities.
/// Covers oxygen, medical air, nitrogen, vacuum, and WAGD systems.
///
/// References: NFPA 99 2024
class MedicalGasScreen extends ConsumerStatefulWidget {
  const MedicalGasScreen({super.key});
  @override
  ConsumerState<MedicalGasScreen> createState() => _MedicalGasScreenState();
}

class _MedicalGasScreenState extends ConsumerState<MedicalGasScreen> {
  // Gas type
  String _gasType = 'oxygen';

  // Number of outlets
  int _outletCount = 10;

  // System pressure (PSI)
  double _pressure = 50;

  // Maximum pipe run (feet)
  double _pipeRun = 100;

  static const Map<String, ({String desc, double scfm, String color, double pressure})> _gasTypes = {
    'oxygen': (desc: 'Oxygen (O₂)', scfm: 1.0, color: 'Green', pressure: 50),
    'medical_air': (desc: 'Medical Air', scfm: 1.0, color: 'Yellow', pressure: 50),
    'nitrogen': (desc: 'Nitrogen (N₂)', scfm: 0.5, color: 'Black', pressure: 160),
    'nitrous': (desc: 'Nitrous Oxide (N₂O)', scfm: 0.5, color: 'Blue', pressure: 50),
    'vacuum': (desc: 'Medical Vacuum', scfm: 1.5, color: 'White', pressure: 15),
    'wagd': (desc: 'WAGD', scfm: 0.5, color: 'Purple', pressure: 5),
    'co2': (desc: 'Carbon Dioxide', scfm: 0.5, color: 'Gray', pressure: 50),
  };

  // Simultaneous use factors
  static const Map<int, double> _useFactor = {
    1: 1.0,
    2: 1.0,
    5: 0.8,
    10: 0.6,
    20: 0.5,
    50: 0.4,
    100: 0.3,
  };

  double get _scfmPerOutlet => _gasTypes[_gasType]?.scfm ?? 1.0;
  String get _pipeColor => _gasTypes[_gasType]?.color ?? 'Green';

  double get _diversityFactor {
    if (_outletCount <= 2) return 1.0;
    if (_outletCount <= 5) return 0.8;
    if (_outletCount <= 10) return 0.6;
    if (_outletCount <= 20) return 0.5;
    if (_outletCount <= 50) return 0.4;
    return 0.3;
  }

  double get _totalScfm => _scfmPerOutlet * _outletCount * _diversityFactor;

  String get _pipeSize {
    final scfm = _totalScfm;
    final isVacuum = _gasType == 'vacuum' || _gasType == 'wagd';

    if (isVacuum) {
      // Vacuum uses larger sizes
      if (scfm <= 5) return '¾"';
      if (scfm <= 15) return '1"';
      if (scfm <= 30) return '1¼"';
      if (scfm <= 50) return '1½"';
      if (scfm <= 100) return '2"';
      return '2½"';
    } else {
      // Positive pressure gases
      if (scfm <= 4) return '⅜"';
      if (scfm <= 8) return '½"';
      if (scfm <= 15) return '¾"';
      if (scfm <= 30) return '1"';
      if (scfm <= 60) return '1¼"';
      if (scfm <= 100) return '1½"';
      return '2"';
    }
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
          'Medical Gas Piping',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildGasTypeCard(colors),
          const SizedBox(height: 16),
          _buildOutletCard(colors),
          const SizedBox(height: 16),
          _buildSpecsCard(colors),
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
            _pipeSize,
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
                _buildResultRow(colors, 'Gas Type', _gasTypes[_gasType]?.desc ?? 'Oxygen'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total SCFM', '${_totalScfm.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Diversity Factor', '${(_diversityFactor * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Color', _pipeColor),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'System Pressure', '${_pressure.toStringAsFixed(0)} PSI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGasTypeCard(ZaftoColors colors) {
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
            'GAS TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._gasTypes.entries.map((entry) {
            final isSelected = _gasType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _gasType = entry.key;
                    _pressure = entry.value.pressure;
                  });
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (colors.isDark ? Colors.black26 : Colors.white30)
                              : colors.bgElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.value.color,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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

  Widget _buildOutletCard(ZaftoColors colors) {
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
            'SYSTEM DESIGN',
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
              Text('Number of Outlets', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_outletCount',
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
              value: _outletCount.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _outletCount = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Pipe Run', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_pipeRun.toStringAsFixed(0)} ft',
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
              value: _pipeRun,
              min: 25,
              max: 500,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pipeRun = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(ZaftoColors colors) {
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
            'PIPING SPECIFICATIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Material', 'Type K or L Copper (ASTM B88)'),
          _buildDimRow(colors, 'Fittings', 'Wrought Copper (ASME B16.22)'),
          _buildDimRow(colors, 'Brazing', 'BCuP-5 (Nitrogen purge required)'),
          _buildDimRow(colors, 'Labeling', 'Every 20\' and at valves'),
          _buildDimRow(colors, 'Testing', '24-hour standing pressure'),
          _buildDimRow(colors, 'Certification', 'ASSE 6010/6020/6030'),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
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
              Icon(LucideIcons.cross, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'NFPA 99 2024',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• ASSE certified installers only\n'
            '• Zone valves and alarms required\n'
            '• Cross-connection prevention critical\n'
            '• 24-hour pressure test mandatory\n'
            '• Purge with nitrogen during brazing\n'
            '• Final verification by qualified verifier',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
