import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Air Filter Sizing Calculator - Design System v2.6
/// Filter area, MERV ratings, and pressure drop
class FilterSizingScreen extends ConsumerStatefulWidget {
  const FilterSizingScreen({super.key});
  @override
  ConsumerState<FilterSizingScreen> createState() => _FilterSizingScreenState();
}

class _FilterSizingScreenState extends ConsumerState<FilterSizingScreen> {
  double _cfm = 1200;
  double _filterWidth = 20;
  double _filterHeight = 25;
  int _filterCount = 1;
  String _mervRating = 'merv8';
  String _filterDepth = '1inch';

  double? _faceVelocity;
  double? _filterArea;
  double? _pressureDrop;
  String? _status;
  String? _recommendation;

  // Pressure drop by MERV (inches WC at 500 fpm)
  final Map<String, double> _mervPressureDrop = {
    'merv4': 0.10,
    'merv8': 0.18,
    'merv11': 0.25,
    'merv13': 0.35,
    'merv14': 0.45,
    'merv16': 0.55,
    'hepa': 1.00,
  };

  // Depth factor for pressure drop
  final Map<String, double> _depthFactor = {
    '1inch': 1.0,
    '2inch': 0.85,
    '4inch': 0.70,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Filter area in square feet
    final filterArea = (_filterWidth * _filterHeight * _filterCount) / 144;

    // Face velocity (fpm)
    final faceVelocity = _cfm / filterArea;

    // Base pressure drop at 500 fpm
    final basePd = _mervPressureDrop[_mervRating] ?? 0.18;
    final depthFactor = _depthFactor[_filterDepth] ?? 1.0;

    // Pressure drop scales with velocity squared
    final velocityRatio = faceVelocity / 500;
    final pressureDrop = basePd * depthFactor * velocityRatio * velocityRatio;

    String status;
    if (faceVelocity <= 300) {
      status = 'EXCELLENT';
    } else if (faceVelocity <= 400) {
      status = 'GOOD';
    } else if (faceVelocity <= 500) {
      status = 'ACCEPTABLE';
    } else {
      status = 'TOO HIGH';
    }

    String recommendation;
    if (faceVelocity > 500) {
      recommendation = 'Face velocity too high (>${faceVelocity.toStringAsFixed(0)} fpm). Add more filter area or reduce airflow. High velocity causes bypass and rapid loading.';
    } else if (faceVelocity > 400) {
      recommendation = 'Face velocity acceptable but on high side. Consider adding filter area for longer life and lower pressure drop.';
    } else {
      recommendation = 'Good filter sizing. Face velocity ${faceVelocity.toStringAsFixed(0)} fpm provides good filtration and long filter life.';
    }

    switch (_mervRating) {
      case 'merv4':
        recommendation += ' MERV-4: Basic filtration. Protects equipment only.';
        break;
      case 'merv8':
        recommendation += ' MERV-8: Standard residential. Captures pollen, dust mites.';
        break;
      case 'merv11':
        recommendation += ' MERV-11: Better residential. Captures mold spores.';
        break;
      case 'merv13':
        recommendation += ' MERV-13: ASHRAE min for IAQ. Captures bacteria, smoke.';
        break;
      case 'merv14':
        recommendation += ' MERV-14: Hospital grade. Captures most virus carriers.';
        break;
      case 'merv16':
        recommendation += ' MERV-16: Clean room grade. High pressure drop.';
        break;
      case 'hepa':
        recommendation += ' HEPA: 99.97% at 0.3 micron. Verify fan can handle pressure.';
        break;
    }

    if (pressureDrop > 0.5) {
      recommendation += ' WARNING: High pressure drop (${pressureDrop.toStringAsFixed(2)}" WC). Verify system can handle.';
    }

    setState(() {
      _faceVelocity = faceVelocity;
      _filterArea = filterArea;
      _pressureDrop = pressureDrop;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm = 1200;
      _filterWidth = 20;
      _filterHeight = 25;
      _filterCount = 1;
      _mervRating = 'merv8';
      _filterDepth = '1inch';
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Filter Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MERV RATING'),
              const SizedBox(height: 12),
              _buildMervSelector(colors),
              const SizedBox(height: 12),
              _buildDepthSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FILTER SIZE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Width', _filterWidth, 10, 30, '"', (v) { setState(() => _filterWidth = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Height', _filterHeight, 10, 36, '"', (v) { setState(() => _filterHeight = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Qty', _filterCount.toDouble(), 1, 8, '', (v) { setState(() => _filterCount = v.round()); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System CFM', value: _cfm, min: 400, max: 5000, unit: ' CFM', onChanged: (v) { setState(() => _cfm = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FILTER ANALYSIS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.filter, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Target 300-500 fpm face velocity. Higher MERV = better filtration but more pressure drop.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildMervSelector(ZaftoColors colors) {
    final ratings = [('merv4', 'MERV-4'), ('merv8', 'MERV-8'), ('merv11', 'MERV-11'), ('merv13', 'MERV-13')];
    return Column(children: [
      Row(
        children: ratings.map((r) {
          final selected = _mervRating == r.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _mervRating = r.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: r != ratings.last ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
      Row(
        children: [('merv14', 'MERV-14'), ('merv16', 'MERV-16'), ('hepa', 'HEPA')].map((r) {
          final selected = _mervRating == r.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _mervRating = r.$1); _calculate(); },
              child: Container(
                margin: EdgeInsets.only(right: r.$1 != 'hepa' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildDepthSelector(ZaftoColors colors) {
    final depths = [('1inch', '1"'), ('2inch', '2"'), ('4inch', '4"')];
    return Row(
      children: depths.map((d) {
        final selected = _filterDepth == d.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _filterDepth = d.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: d != depths.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text('${d.$2} Deep', style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_faceVelocity == null) return const SizedBox.shrink();

    final isGood = _faceVelocity! <= 400;
    final isAcceptable = _faceVelocity! <= 500;
    final statusColor = isGood ? Colors.green : (isAcceptable ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_faceVelocity?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('fpm Face Velocity', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Filter Area', '${_filterArea?.toStringAsFixed(2)} sq ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Press. Drop', '${_pressureDrop?.toStringAsFixed(2)}" WC')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'MERV', _mervRating.toUpperCase().replaceAll('MERV', ''))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? Colors.green : Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
