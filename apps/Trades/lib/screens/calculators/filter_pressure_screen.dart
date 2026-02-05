import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Filter Pressure Drop Calculator - Design System v2.6
/// Air filter pressure and replacement analysis
class FilterPressureScreen extends ConsumerStatefulWidget {
  const FilterPressureScreen({super.key});
  @override
  ConsumerState<FilterPressureScreen> createState() => _FilterPressureScreenState();
}

class _FilterPressureScreenState extends ConsumerState<FilterPressureScreen> {
  double _initialPd = 0.25; // inches WC (clean filter)
  double _currentPd = 0.55; // inches WC (current reading)
  double _maxPd = 1.0; // inches WC (change out point)
  double _airflowCfm = 2000;
  String _filterType = 'pleated';
  String _mervRating = 'merv_13';

  double? _percentLoaded;
  double? _remainingLife;
  double? _energyImpact;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Calculate filter loading
    final pdRange = _maxPd - _initialPd;
    final pdUsed = _currentPd - _initialPd;
    final percentLoaded = (pdUsed / pdRange) * 100;

    // Remaining life estimate
    final remainingLife = 100 - percentLoaded;

    // Energy impact (rough estimate based on increased pressure)
    // Fan power increases with pressure^3 at constant flow
    final pdIncrease = _currentPd / _initialPd;
    final energyImpact = (pdIncrease - 1) * 100; // Percent increase

    // Status determination
    String status;
    if (percentLoaded >= 100) {
      status = 'CHANGE NOW';
    } else if (percentLoaded >= 75) {
      status = 'CHANGE SOON';
    } else if (percentLoaded >= 50) {
      status = 'MONITOR';
    } else {
      status = 'GOOD';
    }

    String recommendation;
    recommendation = 'Filter ${percentLoaded.toStringAsFixed(0)}% loaded. Current: ${_currentPd.toStringAsFixed(2)}" WC, Max: ${_maxPd.toStringAsFixed(2)}" WC. ';

    if (percentLoaded >= 100) {
      recommendation += 'OVERDUE: High pressure drop restricting airflow. Change immediately. ';
    } else if (percentLoaded >= 75) {
      recommendation += 'Schedule replacement soon. Order filters now. ';
    } else if (percentLoaded >= 50) {
      recommendation += 'Normal loading. Check monthly. ';
    } else {
      recommendation += 'Filter in good condition. ';
    }

    recommendation += 'Energy penalty: ~${energyImpact.toStringAsFixed(0)}% increased fan power. ';

    switch (_filterType) {
      case 'fiberglass':
        recommendation += 'Fiberglass: Basic filtration, low cost. Change when visible dirt buildup.';
        break;
      case 'pleated':
        recommendation += 'Pleated: Good efficiency, moderate life. 90-day typical life.';
        break;
      case 'hepa':
        recommendation += 'HEPA: Maximum filtration. High initial PD. Critical environment filter.';
        break;
      case 'bag':
        recommendation += 'Bag filter: Extended surface area. 6-12 month typical life.';
        break;
    }

    // MERV rating notes
    switch (_mervRating) {
      case 'merv_8':
        recommendation += ' MERV-8: Captures pollen, dust mites. Residential/light commercial.';
        break;
      case 'merv_13':
        recommendation += ' MERV-13: Captures bacteria, smoke. Commercial standard.';
        break;
      case 'merv_16':
        recommendation += ' MERV-16: Hospital/clean room grade. High pressure drop.';
        break;
    }

    if (_currentPd > _maxPd) {
      recommendation += ' WARNING: Exceeded max PD. Risk of filter collapse or bypass.';
    }

    setState(() {
      _percentLoaded = percentLoaded;
      _remainingLife = remainingLife;
      _energyImpact = energyImpact;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _initialPd = 0.25;
      _currentPd = 0.55;
      _maxPd = 1.0;
      _airflowCfm = 2000;
      _filterType = 'pleated';
      _mervRating = 'merv_13';
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
        title: Text('Filter Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FILTER TYPE'),
              const SizedBox(height: 12),
              _buildFilterTypeSelector(colors),
              const SizedBox(height: 12),
              _buildMervSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PRESSURE READINGS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Initial PD', _initialPd, 0.1, 0.5, '" WC', (v) { setState(() => _initialPd = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Current PD', _currentPd, 0.1, 2.0, '" WC', (v) { setState(() => _currentPd = v); _calculate(); }, decimals: 2)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Max PD', _maxPd, 0.5, 2.0, '" WC', (v) { setState(() => _maxPd = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Airflow', _airflowCfm, 500, 10000, ' CFM', (v) { setState(() => _airflowCfm = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FILTER STATUS'),
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
        Expanded(child: Text('Monitor filter ΔP regularly. High PD = restricted airflow & energy waste. Change at manufacturer max PD.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFilterTypeSelector(ZaftoColors colors) {
    final types = [('fiberglass', 'Fiberglass'), ('pleated', 'Pleated'), ('hepa', 'HEPA'), ('bag', 'Bag')];
    return Row(
      children: types.map((t) {
        final selected = _filterType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _filterType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMervSelector(ZaftoColors colors) {
    final ratings = [('merv_8', 'MERV-8'), ('merv_13', 'MERV-13'), ('merv_16', 'MERV-16')];
    return Row(
      children: ratings.map((r) {
        final selected = _mervRating == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _mervRating = r.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: r != ratings.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_percentLoaded == null) return const SizedBox.shrink();

    Color statusColor;
    switch (_status) {
      case 'GOOD':
        statusColor = Colors.green;
        break;
      case 'MONITOR':
        statusColor = Colors.orange;
        break;
      case 'CHANGE SOON':
      case 'CHANGE NOW':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_percentLoaded?.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Filter Loaded', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          // Visual pressure bar
          Container(
            height: 24,
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
            child: Stack(children: [
              FractionallySizedBox(
                widthFactor: (_percentLoaded! / 100).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Center(child: Text('${_currentPd.toStringAsFixed(2)}" / ${_maxPd.toStringAsFixed(2)}" WC', style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Initial', '${_initialPd.toStringAsFixed(2)}" WC')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Remaining', '${_remainingLife?.toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Energy +', '${_energyImpact?.toStringAsFixed(0)}%')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
