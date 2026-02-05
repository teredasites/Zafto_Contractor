import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Defrost Cycle Calculator - Design System v2.6
/// Defrost timing and efficiency analysis
class DefrostCycleScreen extends ConsumerStatefulWidget {
  const DefrostCycleScreen({super.key});
  @override
  ConsumerState<DefrostCycleScreen> createState() => _DefrostCycleScreenState();
}

class _DefrostCycleScreenState extends ConsumerState<DefrostCycleScreen> {
  double _evapTemp = 28; // degrees F (below 32 = frost)
  double _defrostInterval = 4; // hours between defrosts
  double _defrostDuration = 20; // minutes
  double _boxTemp = 35; // degrees F
  String _defrostType = 'electric';
  String _application = 'walk_in';

  double? _defrostsPerDay;
  double? _defrostHours;
  double? _tempRise;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Defrosts per day
    final defrostsPerDay = 24 / _defrostInterval;

    // Total defrost time per day
    final defrostHours = (defrostsPerDay * _defrostDuration) / 60;

    // Expected temperature rise during defrost
    double tempRise;
    switch (_defrostType) {
      case 'electric':
        tempRise = 8 + (_defrostDuration / 5); // More rise with longer duration
        break;
      case 'hot_gas':
        tempRise = 5 + (_defrostDuration / 8);
        break;
      case 'off_cycle':
        tempRise = 3 + (_defrostDuration / 15);
        break;
      default:
        tempRise = 8;
    }

    String recommendation;
    recommendation = '${defrostsPerDay.toStringAsFixed(1)} defrosts/day, ${defrostHours.toStringAsFixed(1)} hours total defrost time. ';

    // Check if defrost is needed
    if (_evapTemp > 32) {
      recommendation += 'Evap temp above freezing (${_evapTemp.toStringAsFixed(0)}°F). Defrost may not be needed.';
    } else {
      recommendation += 'Evap temp ${_evapTemp.toStringAsFixed(0)}°F will accumulate frost. Defrost required.';
    }

    switch (_defrostType) {
      case 'electric':
        recommendation += ' Electric defrost: Fast, reliable. High energy use. 15-30 min typical.';
        break;
      case 'hot_gas':
        recommendation += ' Hot gas defrost: Fastest, uses waste heat. More complex piping.';
        break;
      case 'off_cycle':
        recommendation += ' Off-cycle defrost: Simple, low energy. Only for temps >32°F ambient.';
        break;
    }

    switch (_application) {
      case 'walk_in':
        recommendation += ' Walk-in cooler: 4-6 defrosts/day typical. Time defrosts for low-traffic periods.';
        break;
      case 'walk_in_freezer':
        recommendation += ' Freezer: 2-4 defrosts/day. May need drain pan heaters. Check for ice buildup.';
        break;
      case 'heat_pump':
        recommendation += ' Heat pump: Demand defrost preferred. 35-45°F coil temp initiates defrost.';
        break;
      case 'display_case':
        recommendation += ' Display case: Frequent short defrosts. Consider night covers.';
        break;
    }

    if (_defrostDuration > 30) {
      recommendation += ' WARNING: Long defrost duration. May indicate undersized heaters or excessive frost buildup.';
    }

    if (_defrostInterval < 2) {
      recommendation += ' Frequent defrosts reduce efficiency. Check for air infiltration or door seals.';
    }

    // Temperature impact
    if (tempRise > 10 && _application.contains('freezer')) {
      recommendation += ' Expected ${tempRise.toStringAsFixed(0)}°F rise during defrost. Product may exceed safe temps.';
    }

    recommendation += ' Terminate defrost at 50-55°F coil temp to save energy.';

    setState(() {
      _defrostsPerDay = defrostsPerDay;
      _defrostHours = defrostHours;
      _tempRise = tempRise;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _evapTemp = 28;
      _defrostInterval = 4;
      _defrostDuration = 20;
      _boxTemp = 35;
      _defrostType = 'electric';
      _application = 'walk_in';
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
        title: Text('Defrost Cycle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'APPLICATION'),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 12),
              _buildDefrostTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DEFROST TIMING'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Interval', _defrostInterval, 1, 12, ' hr', (v) { setState(() => _defrostInterval = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Duration', _defrostDuration, 5, 60, ' min', (v) { setState(() => _defrostDuration = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Evap Temp', _evapTemp, -20, 45, '°F', (v) { setState(() => _evapTemp = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Box Temp', _boxTemp, -10, 50, '°F', (v) { setState(() => _boxTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DEFROST ANALYSIS'),
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
        Icon(LucideIcons.thermometerSun, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Defrost needed when evap temp <32°F. Terminate at 50-55°F coil. Minimize defrosts to save energy.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('walk_in', 'Walk-In'), ('walk_in_freezer', 'Freezer'), ('heat_pump', 'Heat Pump'), ('display_case', 'Display')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDefrostTypeSelector(ZaftoColors colors) {
    final types = [('electric', 'Electric'), ('hot_gas', 'Hot Gas'), ('off_cycle', 'Off-Cycle')];
    return Row(
      children: types.map((t) {
        final selected = _defrostType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _defrostType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_defrostsPerDay == null) return const SizedBox.shrink();

    final needsDefrost = _evapTemp < 32;
    final statusColor = needsDefrost ? colors.accentPrimary : Colors.green;
    final status = needsDefrost ? 'DEFROST REQUIRED' : 'NO DEFROST NEEDED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_defrostsPerDay?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Defrosts per Day', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Time', '${_defrostHours?.toStringAsFixed(1)} hr/day')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Temp Rise', '~${_tempRise?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Evap', '${_evapTemp.toStringAsFixed(0)}°F')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
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
