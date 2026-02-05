import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pool/Spa Plumbing Calculator - Design System v2.6
///
/// Sizes pool plumbing including pump, filter, and return lines.
/// Calculates turnover rate and pipe sizing.
///
/// References: NSF/ANSI 50, State Health Codes
class PoolPlumbingScreen extends ConsumerStatefulWidget {
  const PoolPlumbingScreen({super.key});
  @override
  ConsumerState<PoolPlumbingScreen> createState() => _PoolPlumbingScreenState();
}

class _PoolPlumbingScreenState extends ConsumerState<PoolPlumbingScreen> {
  // Pool type
  String _poolType = 'residential';

  // Pool volume (gallons)
  double _poolVolume = 20000;

  // Desired turnover (hours)
  double _turnoverHours = 8;

  // Number of returns
  int _returnCount = 2;

  // Number of skimmers
  int _skimmerCount = 2;

  // Main drain
  bool _hasMainDrain = true;

  static const Map<String, ({String desc, double maxTurnover, double velocity})> _poolTypes = {
    'residential': (desc: 'Residential', maxTurnover: 12, velocity: 6),
    'commercial': (desc: 'Commercial', maxTurnover: 6, velocity: 6),
    'spa': (desc: 'Spa/Hot Tub', maxTurnover: 0.5, velocity: 8),
    'wading': (desc: 'Wading Pool', maxTurnover: 1, velocity: 6),
  };

  double get _flowRateGpm => _poolVolume / (_turnoverHours * 60);

  double get _velocityLimit => _poolTypes[_poolType]?.velocity ?? 6;

  // Pipe size based on flow rate and velocity
  // Area = GPM / (velocity × 449)
  // Diameter = sqrt(Area × 4 / π)
  String get _pumpSuctionSize {
    final gpm = _flowRateGpm;
    if (gpm <= 30) return '1½"';
    if (gpm <= 50) return '2"';
    if (gpm <= 85) return '2½"';
    if (gpm <= 120) return '3"';
    return '4"';
  }

  String get _returnLineSize {
    final gpmPerReturn = _flowRateGpm / _returnCount;
    if (gpmPerReturn <= 15) return '1"';
    if (gpmPerReturn <= 25) return '1½"';
    if (gpmPerReturn <= 45) return '2"';
    return '2½"';
  }

  String get _mainDrainSize {
    final gpm = _flowRateGpm;
    if (gpm <= 60) return '2"';
    if (gpm <= 100) return '3"';
    return '4"';
  }

  double get _filterSizeSqFt {
    // Rule of thumb: 3 sq ft per 10,000 gallons or 1 sq ft per 15 GPM
    return (_flowRateGpm / 15).ceilToDouble();
  }

  int get _pumpHp {
    // Rough estimate based on GPM and typical head pressure
    final gpm = _flowRateGpm;
    if (gpm <= 40) return 1;
    if (gpm <= 60) return 2;
    if (gpm <= 90) return 3;
    return 5;
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
          'Pool Plumbing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPoolTypeCard(colors),
          const SizedBox(height: 16),
          _buildVolumeCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
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
            '${_flowRateGpm.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'GPM Required',
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
                _buildResultRow(colors, 'Pool Type', _poolTypes[_poolType]?.desc ?? 'Residential'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Volume', '${_poolVolume.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Turnover', '${_turnoverHours.toStringAsFixed(1)} hours'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pump Size', '$_pumpHp HP (est)'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Filter Area', '${_filterSizeSqFt.toStringAsFixed(0)} sq ft'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolTypeCard(ZaftoColors colors) {
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
            'POOL TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._poolTypes.entries.map((entry) {
            final isSelected = _poolType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _poolType = entry.key;
                    _turnoverHours = entry.value.maxTurnover;
                    if (entry.key == 'spa') {
                      _poolVolume = 500;
                    } else if (entry.key == 'wading') {
                      _poolVolume = 2000;
                    }
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Max ${entry.value.maxTurnover}h turnover',
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

  Widget _buildVolumeCard(ZaftoColors colors) {
    final maxVolume = _poolType == 'spa' ? 1000.0 : (_poolType == 'wading' ? 5000.0 : 100000.0);
    final minVolume = _poolType == 'spa' ? 200.0 : (_poolType == 'wading' ? 500.0 : 5000.0);

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
            'POOL SPECIFICATIONS',
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
              Text('Volume', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_poolVolume.toStringAsFixed(0)} gal',
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
              value: _poolVolume.clamp(minVolume, maxVolume),
              min: minVolume,
              max: maxVolume,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _poolVolume = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Turnover Time', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_turnoverHours.toStringAsFixed(1)} hours',
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
              value: _turnoverHours,
              min: _poolType == 'spa' ? 0.25 : 0.5,
              max: _poolTypes[_poolType]?.maxTurnover ?? 12,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _turnoverHours = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
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
            'POOL FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildCounterRow(colors, 'Return Inlets', _returnCount, (v) => setState(() => _returnCount = v), 1, 8),
          const SizedBox(height: 12),
          _buildCounterRow(colors, 'Skimmers', _skimmerCount, (v) => setState(() => _skimmerCount = v), 1, 4),
          const SizedBox(height: 12),
          _buildToggleRow(colors, 'Main Drain', 'Dual drain VGBA required', _hasMainDrain, (v) => setState(() => _hasMainDrain = v)),
        ],
      ),
    );
  }

  Widget _buildCounterRow(ZaftoColors colors, String label, int value, Function(int) onChanged, int min, int max) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (value > min) onChanged(value - 1);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: value > min ? colors.bgBase : colors.bgBase.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.minus, color: value > min ? colors.textPrimary : colors.textTertiary, size: 16),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (value < max) onChanged(value + 1);
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
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String title, String subtitle, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : colors.bgBase,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
            ),
            child: value
                ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
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
          _buildDimRow(colors, 'Pump Suction', _pumpSuctionSize),
          _buildDimRow(colors, 'Return Lines', '$_returnLineSize each'),
          _buildDimRow(colors, 'Skimmer Lines', '$_pumpSuctionSize (to pump)'),
          if (_hasMainDrain)
            _buildDimRow(colors, 'Main Drain', '$_mainDrainSize (dual required)'),
          _buildDimRow(colors, 'Max Velocity', '${_velocityLimit.toStringAsFixed(0)} ft/s suction, 8 ft/s pressure'),
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Pool Codes',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• VGBA: Dual main drains required\n'
            '• Commercial: 6 hr max turnover\n'
            '• Spa: 30 min turnover typical\n'
            '• Suction velocity max 6 ft/s\n'
            '• Pressure velocity max 8-10 ft/s\n'
            '• Check state health codes',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
