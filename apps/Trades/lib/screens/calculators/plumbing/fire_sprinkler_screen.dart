import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Fire Sprinkler Water Demand Calculator - Design System v2.6
///
/// Calculates residential fire sprinkler water supply requirements.
/// For NFPA 13D residential systems only.
///
/// References: NFPA 13D 2024
class FireSprinklerScreen extends ConsumerStatefulWidget {
  const FireSprinklerScreen({super.key});
  @override
  ConsumerState<FireSprinklerScreen> createState() => _FireSprinklerScreenState();
}

class _FireSprinklerScreenState extends ConsumerState<FireSprinklerScreen> {
  // Sprinkler type
  String _sprinklerType = 'residential';

  // Number of sprinklers in design area
  int _sprinklerCount = 2;

  // Available static pressure (PSI)
  double _availablePressure = 60;

  // Pipe material
  String _pipeMaterial = 'cpvc';

  static const Map<String, ({String desc, double gpm, double psi})> _sprinklerTypes = {
    'residential': (desc: 'Residential (13D)', gpm: 13, psi: 7),
    'quick_response': (desc: 'Quick Response', gpm: 18, psi: 7),
    'extended': (desc: 'Extended Coverage', gpm: 20, psi: 10),
    'concealed': (desc: 'Concealed', gpm: 15, psi: 7),
  };

  static const Map<String, ({String desc, double cFactor})> _pipeMaterials = {
    'cpvc': (desc: 'CPVC (Orange)', cFactor: 150),
    'copper': (desc: 'Copper', cFactor: 140),
    'steel': (desc: 'Steel (Black)', cFactor: 100),
    'pex': (desc: 'PEX (Listed)', cFactor: 150),
  };

  double get _gpmPerHead => _sprinklerTypes[_sprinklerType]?.gpm ?? 13;
  double get _minPressure => _sprinklerTypes[_sprinklerType]?.psi ?? 7;
  double get _totalDemand => _gpmPerHead * _sprinklerCount;

  // NFPA 13D requires 10-minute water supply
  double get _waterStorageGallons => _totalDemand * 10;

  bool get _pressureOk => _availablePressure >= _minPressure + 20; // 20 PSI for friction loss margin

  String get _mainPipeSize {
    if (_totalDemand <= 25) return '¾"';
    if (_totalDemand <= 40) return '1"';
    if (_totalDemand <= 60) return '1¼"';
    return '1½"';
  }

  String get _branchSize {
    if (_gpmPerHead <= 15) return '¾"';
    if (_gpmPerHead <= 25) return '1"';
    return '1¼"';
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
          'Fire Sprinkler (13D)',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSprinklerTypeCard(colors),
          const SizedBox(height: 16),
          _buildDesignCard(colors),
          const SizedBox(height: 16),
          _buildPipeMaterialCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizingCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = _pressureOk ? colors.accentSuccess : colors.accentError;

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
            '${_totalDemand.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'GPM Total Demand',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _pressureOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _pressureOk ? 'Pressure OK' : 'Check Pressure',
                  style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
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
                _buildResultRow(colors, 'Per Sprinkler', '${_gpmPerHead.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Design Sprinklers', '$_sprinklerCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Pressure', '${_minPressure.toStringAsFixed(0)} PSI'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Water Storage', '${_waterStorageGallons.toStringAsFixed(0)} gal (10 min)'),
              ],
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
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.gpm} GPM @ ${entry.value.psi} PSI',
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

  Widget _buildDesignCard(ZaftoColors colors) {
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
            'DESIGN PARAMETERS',
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
              Text('Design Sprinklers', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_sprinklerCount',
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
              value: _sprinklerCount.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _sprinklerCount = v.round());
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NFPA 13D: 2 sprinklers for most residential',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Pressure', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_availablePressure.toStringAsFixed(0)} PSI',
                style: TextStyle(
                  color: _pressureOk ? colors.accentPrimary : colors.accentError,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _pressureOk ? colors.accentPrimary : colors.accentError,
              inactiveTrackColor: colors.bgBase,
              thumbColor: _pressureOk ? colors.accentPrimary : colors.accentError,
              trackHeight: 4,
            ),
            child: Slider(
              value: _availablePressure,
              min: 20,
              max: 120,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _availablePressure = v);
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
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
          const SizedBox(height: 8),
          Text(
            'C-Factor: ${_pipeMaterials[_pipeMaterial]?.cFactor ?? 150}',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizingCard(ZaftoColors colors) {
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
            'PIPE SIZING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Main/Riser', _mainPipeSize),
          _buildDimRow(colors, 'Branch Lines', _branchSize),
          _buildDimRow(colors, 'Sprinkler Drop', '¾" minimum'),
          Divider(color: colors.borderSubtle, height: 20),
          _buildDimRow(colors, 'Max Velocity', '32 ft/s (NFPA 13D)'),
          _buildDimRow(colors, 'Min Pressure', '${_minPressure.toStringAsFixed(0)} PSI at head'),
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
              Icon(LucideIcons.flame, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Text(
                'NFPA 13D 2024',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Residential sprinklers only\n'
            '• 2 sprinklers typical design\n'
            '• 10 minute water supply\n'
            '• Listed materials only\n'
            '• Check AHJ requirements\n'
            '• Professional design required',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
