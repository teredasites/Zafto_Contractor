import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Irrigation System Sizing Calculator - Design System v2.6
///
/// Sizes residential irrigation supply piping and zones.
/// Calculates GPM requirements and zone capacity.
///
/// References: Irrigation Association Standards
class IrrigationSizingScreen extends ConsumerStatefulWidget {
  const IrrigationSizingScreen({super.key});
  @override
  ConsumerState<IrrigationSizingScreen> createState() => _IrrigationSizingScreenState();
}

class _IrrigationSizingScreenState extends ConsumerState<IrrigationSizingScreen> {
  // Available GPM at source
  double _availableGpm = 12;

  // Available pressure (PSI)
  double _availablePressure = 50;

  // Total area (sq ft)
  double _totalArea = 5000;

  // Sprinkler type
  String _sprinklerType = 'rotary';

  // Pipe material
  String _pipeMaterial = 'poly';

  static const Map<String, ({String desc, double gpmPer1000, double minPsi})> _sprinklerTypes = {
    'spray': (desc: 'Spray Heads', gpmPer1000: 1.5, minPsi: 30),
    'rotary': (desc: 'Rotary/Rotor', gpmPer1000: 0.6, minPsi: 40),
    'mp_rotator': (desc: 'MP Rotator', gpmPer1000: 0.4, minPsi: 25),
    'drip': (desc: 'Drip Irrigation', gpmPer1000: 0.3, minPsi: 20),
  };

  static const Map<String, ({String desc, String mainSize, String lateralSize})> _pipeMaterials = {
    'poly': (desc: 'Poly Pipe', mainSize: '1\"', lateralSize: '¾\"'),
    'pvc_sch40': (desc: 'PVC Schedule 40', mainSize: '1\"', lateralSize: '¾\"'),
    'pvc_class200': (desc: 'PVC Class 200', mainSize: '1\"', lateralSize: '¾\"'),
  };

  // Total GPM required
  double get _totalGpmRequired {
    final gpmPer1000 = _sprinklerTypes[_sprinklerType]?.gpmPer1000 ?? 0.6;
    return (_totalArea / 1000) * gpmPer1000;
  }

  // Number of zones needed
  int get _zonesRequired => (_totalGpmRequired / _availableGpm).ceil().clamp(1, 20);

  // GPM per zone
  double get _gpmPerZone => _totalGpmRequired / _zonesRequired;

  // Adequate pressure check
  bool get _pressureAdequate {
    final minPsi = _sprinklerTypes[_sprinklerType]?.minPsi ?? 30;
    return _availablePressure >= minPsi;
  }

  // Main line size recommendation
  String get _mainLineSize {
    if (_availableGpm <= 8) return '¾\"';
    if (_availableGpm <= 15) return '1\"';
    if (_availableGpm <= 25) return '1¼\"';
    return '1½\"';
  }

  // Lateral line size
  String get _lateralSize {
    if (_gpmPerZone <= 5) return '½\"';
    if (_gpmPerZone <= 10) return '¾\"';
    return '1\"';
  }

  // Run time per zone (to apply 1\" water)
  int get _runTimeMinutes {
    final gpmPer1000 = _sprinklerTypes[_sprinklerType]?.gpmPer1000 ?? 0.6;
    // 1" of water on 1000 sq ft = 623 gallons
    // Time = 623 / (GPM per 1000 sq ft)
    return (623 / (gpmPer1000 * 60)).round();
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
          'Irrigation Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSupplyCard(colors),
          const SizedBox(height: 16),
          _buildAreaCard(colors),
          const SizedBox(height: 16),
          _buildSprinklerTypeCard(colors),
          const SizedBox(height: 16),
          _buildPipeMaterialCard(colors),
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
            '$_zonesRequired',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Zones Required',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!_pressureAdequate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Pressure below minimum for ${_sprinklerTypes[_sprinklerType]?.desc}',
                    style: TextStyle(color: colors.accentError, fontSize: 11),
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
                _buildResultRow(colors, 'Total GPM Needed', '${_totalGpmRequired.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'GPM per Zone', '${_gpmPerZone.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Main Line', _mainLineSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Lateral Lines', _lateralSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Run Time (1\")', '$_runTimeMinutes min/zone'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyCard(ZaftoColors colors) {
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
            'WATER SUPPLY',
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
              Text('Available Flow', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_availableGpm.toStringAsFixed(0)} GPM',
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
              value: _availableGpm,
              min: 5,
              max: 30,
              divisions: 25,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _availableGpm = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_availablePressure.toStringAsFixed(0)} PSI',
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
              value: _availablePressure,
              min: 20,
              max: 80,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _availablePressure = v);
              },
            ),
          ),
          Text(
            'Measure at irrigation tap with hose bib running',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard(ZaftoColors colors) {
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
            'IRRIGATION AREA',
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
              Text('Total Area', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_totalArea.toStringAsFixed(0)} sq ft',
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
              value: _totalArea,
              min: 1000,
              max: 20000,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _totalArea = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprinklerTypeCard(ZaftoColors colors) {
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
            'SPRINKLER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._sprinklerTypes.entries.map((entry) {
            final isSelected = _sprinklerType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sprinklerType = entry.key);
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.desc,
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Min ${entry.value.minPsi.toInt()} PSI',
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.value.gpmPer1000} GPM/1000sf',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pipeMaterials.entries.map((entry) {
              final isSelected = _pipeMaterial == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeMaterial = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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
              Icon(LucideIcons.sprout, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Irrigation Best Practices',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Backflow preventer required\n'
            '• Don\'t mix spray and rotor on same zone\n'
            '• Keep velocity under 5 ft/sec\n'
            '• Water early morning (4-6 AM)\n'
            '• 1\" per week total (rain + irrigation)\n'
            '• Winterize in freezing climates',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
