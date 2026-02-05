import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Steam Trap Sizing Calculator - Design System v2.6
/// Steam trap selection and condensate load calculation
class SteamTrapScreen extends ConsumerStatefulWidget {
  const SteamTrapScreen({super.key});
  @override
  ConsumerState<SteamTrapScreen> createState() => _SteamTrapScreenState();
}

class _SteamTrapScreenState extends ConsumerState<SteamTrapScreen> {
  double _steamPressure = 15; // psig
  double _condensateLoad = 500; // lbs/hr
  double _backPressure = 0; // psig
  double _safetyFactor = 2.0;
  String _application = 'heating';
  String _trapType = 'float';

  double? _differential;
  double? _requiredCapacity;
  String? _recommendedTrap;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Pressure differential
    final differential = _steamPressure - _backPressure;

    // Required capacity with safety factor
    final requiredCapacity = _condensateLoad * _safetyFactor;

    // Recommend trap type based on application
    String recommendedTrap;
    switch (_application) {
      case 'heating':
        recommendedTrap = 'Float & Thermostatic (F&T)';
        break;
      case 'process':
        recommendedTrap = 'Inverted Bucket';
        break;
      case 'drip':
        recommendedTrap = 'Thermodynamic (TD)';
        break;
      case 'tracing':
        recommendedTrap = 'Thermostatic';
        break;
      default:
        recommendedTrap = 'Float & Thermostatic';
    }

    String recommendation;
    recommendation = 'Size for ${requiredCapacity.toStringAsFixed(0)} lbs/hr at ${differential.toStringAsFixed(0)} psi differential (${_safetyFactor}× safety factor). ';

    switch (_trapType) {
      case 'float':
        recommendation += 'F&T trap: Continuous discharge, handles varying loads. Best for most heating applications.';
        break;
      case 'bucket':
        recommendation += 'Inverted bucket: Rugged, handles water hammer. Good for process steam with dirt/scale.';
        break;
      case 'thermo':
        recommendation += 'Thermostatic: Compact, low cost. Good for tracing and low-pressure drip legs.';
        break;
      case 'td':
        recommendation += 'Thermodynamic: Simple, handles high pressure. Noisy, needs dry steam.';
        break;
    }

    if (differential < 5) {
      recommendation += ' Low differential: Size generously. Consider gravity drainage or pumped return.';
    } else if (differential > 50) {
      recommendation += ' High differential: Verify trap pressure rating. Consider orifice sizing.';
    }

    switch (_application) {
      case 'heating':
        recommendation += ' Heating coils: F&T handles modulating loads. Install at lowest point with drip pocket.';
        break;
      case 'process':
        recommendation += ' Process: Size for startup load which may be 3-5× operating. Include strainer.';
        break;
      case 'drip':
        recommendation += ' Drip leg: Install every 100 ft and at low points. Size for warm-up condensate.';
        break;
      case 'tracing':
        recommendation += ' Tracing: Low loads, thermostatic OK. Consider manifold for multiple tracers.';
        break;
    }

    recommendation += ' Test annually - failed traps waste 5-10% of steam energy.';

    setState(() {
      _differential = differential;
      _requiredCapacity = requiredCapacity;
      _recommendedTrap = recommendedTrap;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _steamPressure = 15;
      _condensateLoad = 500;
      _backPressure = 0;
      _safetyFactor = 2.0;
      _application = 'heating';
      _trapType = 'float';
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
        title: Text('Steam Trap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildTrapTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'STEAM CONDITIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Steam Press', _steamPressure, 5, 150, ' psig', (v) { setState(() => _steamPressure = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Back Press', _backPressure, 0, 50, ' psig', (v) { setState(() => _backPressure = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDENSATE LOAD'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Load', _condensateLoad, 50, 5000, ' lb/hr', (v) { setState(() => _condensateLoad = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Safety', _safetyFactor, 1.5, 4.0, '×', (v) { setState(() => _safetyFactor = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TRAP SIZING'),
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
        Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Steam traps remove condensate while retaining steam. Size for 2-3× operating load with appropriate differential pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('heating', 'Heating'), ('process', 'Process'), ('drip', 'Drip Leg'), ('tracing', 'Tracing')];
    return Row(
      children: apps.map((a) {
        final selected = _application == a.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _application = a.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: a != apps.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrapTypeSelector(ZaftoColors colors) {
    final types = [('float', 'F&T'), ('bucket', 'Bucket'), ('thermo', 'Thermo'), ('td', 'TD')];
    return Row(
      children: types.map((t) {
        final selected = _trapType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _trapType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 6 : 0),
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
    if (_requiredCapacity == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_requiredCapacity?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('lbs/hr Required Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_recommendedTrap ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Differential', '${_differential?.toStringAsFixed(0)} psi')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Base Load', '${_condensateLoad.toStringAsFixed(0)} lb/hr')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Safety', '${_safetyFactor.toStringAsFixed(1)}×')),
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
