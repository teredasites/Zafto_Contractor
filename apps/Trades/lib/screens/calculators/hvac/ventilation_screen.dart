import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Ventilation Calculator - Design System v2.6
///
/// Calculates required mechanical ventilation per ASHRAE 62.2.
/// Determines outdoor air requirements for residential buildings.
///
/// References: ASHRAE 62.2-2022, IRC M1505
class VentilationScreen extends ConsumerStatefulWidget {
  const VentilationScreen({super.key});
  @override
  ConsumerState<VentilationScreen> createState() => _VentilationScreenState();
}

class _VentilationScreenState extends ConsumerState<VentilationScreen> {
  // Floor area (sq ft)
  double _floorArea = 2000;

  // Number of bedrooms
  int _bedrooms = 3;

  // Infiltration credit
  bool _infiltrationCredit = false;

  // ACH50 (for credit calculation)
  double _ach50 = 5.0;

  // Ventilation system type
  String _systemType = 'exhaust';

  static const Map<String, ({String desc, double efficiency})> _systemTypes = {
    'exhaust': (desc: 'Exhaust Only', efficiency: 1.0),
    'supply': (desc: 'Supply Only', efficiency: 1.0),
    'balanced': (desc: 'Balanced (HRV/ERV)', efficiency: 1.0),
    'cfis': (desc: 'Central Fan Integrated', efficiency: 0.72),
  };

  // ASHRAE 62.2 calculation
  // Qtot = 0.03 × Afloor + 7.5 × (Nbr + 1)
  double get _totalVentilation => (0.03 * _floorArea) + (7.5 * (_bedrooms + 1));

  // Infiltration credit (if applicable)
  double get _infiltrationCfm {
    if (!_infiltrationCredit) return 0;
    // Qinf = 0.052 × Qfan × wsf × Afloor
    // Simplified: approximately 2% of CFM50
    return _ach50 * _floorArea * 8 / 60 * 0.02;
  }

  // Required mechanical ventilation
  double get _mechanicalVentilation {
    final efficiency = _systemTypes[_systemType]?.efficiency ?? 1.0;
    final net = (_totalVentilation - _infiltrationCfm).clamp(0, double.infinity);
    return net / efficiency;
  }

  // Fan sizing (round up to common sizes)
  int get _fanSize {
    final cfm = _mechanicalVentilation;
    final sizes = [30, 50, 70, 80, 100, 110, 130, 150, 200];
    return sizes.firstWhere((s) => s >= cfm, orElse: () => 200);
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
          'Ventilation Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
          const SizedBox(height: 16),
          _buildSystemCard(colors),
          const SizedBox(height: 16),
          _buildInfiltrationCard(colors),
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
            '${_mechanicalVentilation.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'CFM Required',
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
                _buildResultRow(colors, 'Total Ventilation', '${_totalVentilation.toStringAsFixed(1)} CFM'),
                if (_infiltrationCredit) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Infiltration Credit', '-${_infiltrationCfm.toStringAsFixed(1)} CFM'),
                ],
                const SizedBox(height: 10),
                _buildResultRow(colors, 'System Type', _systemTypes[_systemType]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Recommended Fan', '$_fanSize CFM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Bedrooms + 1', '${_bedrooms + 1} occupants'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingCard(ZaftoColors colors) {
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
            'BUILDING INFO',
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
              Text('Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_floorArea.toStringAsFixed(0)} sq ft',
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
              value: _floorArea,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _floorArea = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bedrooms', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_bedrooms',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 4, 5].map((br) {
              final isSelected = _bedrooms == br;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _bedrooms = br);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$br',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildSystemCard(ZaftoColors colors) {
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
            'VENTILATION SYSTEM',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._systemTypes.entries.map((entry) {
            final isSelected = _systemType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _systemType = entry.key);
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
                      if (entry.value.efficiency < 1.0)
                        Text(
                          '${(entry.value.efficiency * 100).toStringAsFixed(0)}% eff',
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

  Widget _buildInfiltrationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _infiltrationCredit ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _infiltrationCredit ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _infiltrationCredit = !_infiltrationCredit);
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _infiltrationCredit ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _infiltrationCredit ? colors.accentPrimary : colors.borderSubtle),
                  ),
                  child: _infiltrationCredit
                      ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply Infiltration Credit',
                        style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Requires blower door test data',
                        style: TextStyle(color: colors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_infiltrationCredit) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACH50 Result', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Text(
                  '${_ach50.toStringAsFixed(1)}',
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
                value: _ach50,
                min: 1,
                max: 10,
                divisions: 18,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _ach50 = v);
                },
              ),
            ),
          ],
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
              Icon(LucideIcons.wind, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ASHRAE 62.2-2022',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Qtot = 0.03×Afloor + 7.5×(Nbr+1)\n'
            '• Continuous operation preferred\n'
            '• Kitchen: 100 CFM intermittent\n'
            '• Bath: 50 CFM intermittent\n'
            '• Controls: accessible\n'
            '• HRV/ERV for cold climates',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
