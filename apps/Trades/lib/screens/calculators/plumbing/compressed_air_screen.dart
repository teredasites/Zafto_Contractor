import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Compressed Air Piping Calculator - Design System v2.6
///
/// Sizes compressed air distribution piping for shops.
/// Calculates CFM requirements and pressure drop.
///
/// References: CAGI, ASME
class CompressedAirScreen extends ConsumerStatefulWidget {
  const CompressedAirScreen({super.key});
  @override
  ConsumerState<CompressedAirScreen> createState() => _CompressedAirScreenState();
}

class _CompressedAirScreenState extends ConsumerState<CompressedAirScreen> {
  // Tools and equipment
  Map<String, int> _tools = {
    'impact_wrench': 1,
    'air_ratchet': 0,
    'die_grinder': 0,
    'spray_gun': 0,
    'blow_gun': 2,
    'brad_nailer': 0,
    'framing_nailer': 0,
  };

  // System pressure (PSI)
  double _pressure = 100;

  // Max pipe run (feet)
  double _pipeRun = 100;

  // Pipe material
  String _pipeMaterial = 'aluminum';

  static const Map<String, ({String desc, double cfm, double psi})> _toolData = {
    'impact_wrench': (desc: 'Impact Wrench (½")', cfm: 5.0, psi: 90),
    'air_ratchet': (desc: 'Air Ratchet', cfm: 3.0, psi: 90),
    'die_grinder': (desc: 'Die Grinder', cfm: 6.0, psi: 90),
    'spray_gun': (desc: 'HVLP Spray Gun', cfm: 12.0, psi: 40),
    'blow_gun': (desc: 'Blow Gun', cfm: 3.0, psi: 90),
    'brad_nailer': (desc: 'Brad Nailer', cfm: 0.5, psi: 70),
    'framing_nailer': (desc: 'Framing Nailer', cfm: 2.0, psi: 90),
  };

  static const Map<String, ({String desc, double factor})> _pipeMaterials = {
    'black_iron': (desc: 'Black Iron', factor: 1.0),
    'galvanized': (desc: 'Galvanized', factor: 1.1),
    'copper': (desc: 'Copper', factor: 0.9),
    'aluminum': (desc: 'Aluminum', factor: 0.85),
    'pvc': (desc: 'PVC (not rated)', factor: 1.5),
  };

  double get _totalCfm {
    double total = 0;
    _tools.forEach((key, count) {
      total += (_toolData[key]?.cfm ?? 0) * count;
    });
    return total;
  }

  // Diversity factor (50% for multiple tools)
  double get _designCfm => _totalCfm * 0.5 + (_totalCfm > 0 ? _totalCfm * 0.5 : 0);

  // Compressor HP estimate (5 CFM per HP at 100 PSI)
  double get _compressorHp => (_designCfm / 5).ceilToDouble();

  // Tank size (1 gallon per CFM minimum)
  int get _tankSize => (_designCfm * 1.5).ceil().clamp(20, 500);

  String get _mainPipeSize {
    final cfm = _designCfm;
    final run = _pipeRun;
    final factor = _pipeMaterials[_pipeMaterial]?.factor ?? 1.0;
    final adjustedCfm = cfm * factor;

    // Simplified sizing based on CFM and run length
    if (run <= 50) {
      if (adjustedCfm <= 10) return '½"';
      if (adjustedCfm <= 25) return '¾"';
      if (adjustedCfm <= 50) return '1"';
      return '1¼"';
    } else if (run <= 100) {
      if (adjustedCfm <= 8) return '½"';
      if (adjustedCfm <= 20) return '¾"';
      if (adjustedCfm <= 40) return '1"';
      return '1¼"';
    } else {
      if (adjustedCfm <= 5) return '½"';
      if (adjustedCfm <= 15) return '¾"';
      if (adjustedCfm <= 30) return '1"';
      if (adjustedCfm <= 60) return '1¼"';
      return '1½"';
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
          'Compressed Air Piping',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildToolsCard(colors),
          const SizedBox(height: 16),
          _buildSystemCard(colors),
          const SizedBox(height: 16),
          _buildPipeMaterialCard(colors),
          const SizedBox(height: 16),
          _buildTipsCard(colors),
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
            _mainPipeSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Main Line Size',
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
                _buildResultRow(colors, 'Total CFM', '${_totalCfm.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Design CFM (50%)', '${_designCfm.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Compressor Size', '${_compressorHp.toStringAsFixed(0)} HP'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Tank Size', '$_tankSize gallons'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard(ZaftoColors colors) {
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
            'AIR TOOLS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._toolData.entries.map((entry) {
            final count = _tools[entry.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.desc,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        ),
                        Text(
                          '${entry.value.cfm} CFM @ ${entry.value.psi.toInt()} PSI',
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (count > 0) {
                            setState(() => _tools[entry.key] = count - 1);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: count > 0 ? colors.bgBase : colors.bgBase.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.minus, color: count > 0 ? colors.textPrimary : colors.textTertiary, size: 16),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text('$count', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tools[entry.key] = count + 1);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.accentPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
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
            'SYSTEM PARAMETERS',
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
              Text('System Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
              min: 80,
              max: 175,
              divisions: 19,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _pressure = v);
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

  Widget _buildPipeMaterialCard(ZaftoColors colors) {
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
          ..._pipeMaterials.entries.map((entry) {
            final isSelected = _pipeMaterial == entry.key;
            final isPvc = entry.key == 'pvc';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeMaterial = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                    border: isPvc ? Border.all(color: colors.accentError.withValues(alpha: 0.5)) : null,
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
                      if (isPvc)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.accentError.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Not Safe',
                            style: TextStyle(color: colors.accentError, fontSize: 9, fontWeight: FontWeight.w600),
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

  Widget _buildTipsCard(ZaftoColors colors) {
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
                'Best Practices',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Loop system for balanced pressure\n'
            '• Slope lines 1° toward drip legs\n'
            '• Drip legs at low points\n'
            '• Use quick disconnects at drops\n'
            '• NEVER use PVC for compressed air\n'
            '• Size drops ½" minimum',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
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
}
