import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Damper Sizing Calculator - Design System v2.6
/// Control and balancing damper sizing with Cv calculations
class DamperSizingScreen extends ConsumerStatefulWidget {
  const DamperSizingScreen({super.key});
  @override
  ConsumerState<DamperSizingScreen> createState() => _DamperSizingScreenState();
}

class _DamperSizingScreenState extends ConsumerState<DamperSizingScreen> {
  double _airflow = 2000; // CFM
  double _pressureDrop = 0.15; // inches WC
  double _ductWidth = 24; // inches
  double _ductHeight = 18; // inches
  String _damperType = 'parallel';
  String _application = 'control';

  double? _damperArea;
  double? _faceVelocity;
  double? _cvValue;
  double? _recommendedSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Duct area
    final ductArea = (_ductWidth * _ductHeight) / 144; // sq ft

    // Face velocity
    final faceVelocity = _airflow / ductArea;

    // Cv calculation (airflow coefficient)
    // Cv = CFM / (1.08 × sqrt(ΔP))
    final cvValue = _airflow / (1.08 * math.sqrt(_pressureDrop * 4005));

    // Pressure drop at velocity
    // ΔP = (V/4005)²
    final velocityPressure = math.pow(faceVelocity / 4005, 2);

    // Recommended damper area (target 800-1500 fpm)
    final recommendedArea = _airflow / 1200; // Target 1200 fpm
    final recommendedSize = math.sqrt(recommendedArea * 144);

    String recommendation;
    recommendation = 'Duct: ${_ductWidth.toStringAsFixed(0)}×${_ductHeight.toStringAsFixed(0)}\" (${ductArea.toStringAsFixed(2)} sq ft). ';

    if (faceVelocity > 2000) {
      recommendation += 'WARNING: Velocity ${faceVelocity.toStringAsFixed(0)} fpm exceeds 2000 fpm max. Increase damper size.';
    } else if (faceVelocity > 1500) {
      recommendation += 'High velocity (${faceVelocity.toStringAsFixed(0)} fpm). May generate noise. Target 800-1500 fpm.';
    } else if (faceVelocity < 500) {
      recommendation += 'Low velocity (${faceVelocity.toStringAsFixed(0)} fpm). Damper may be oversized for good control.';
    } else {
      recommendation += 'Good velocity (${faceVelocity.toStringAsFixed(0)} fpm) for controllability.';
    }

    switch (_damperType) {
      case 'parallel':
        recommendation += ' Parallel blade: Linear flow characteristic. Good for mixing. Less authority for modulating control.';
        break;
      case 'opposed':
        recommendation += ' Opposed blade: Equal percentage characteristic. Better for modulating control. Standard for VAV.';
        break;
      case 'butterfly':
        recommendation += ' Butterfly: Round ducts. Quick open/close. Higher leakage.';
        break;
    }

    switch (_application) {
      case 'control':
        recommendation += ' Control damper: Size for 15-25% of system pressure drop. Use opposed blade.';
        break;
      case 'balance':
        recommendation += ' Balancing damper: Full duct size OK. Lock after commissioning.';
        break;
      case 'fire':
        recommendation += ' Fire/smoke damper: Must match duct size exactly. UL/FM rated. Fusible link or actuator.';
        break;
      case 'backdraft':
        recommendation += ' Backdraft: Size for 0.05" WC to open. Gravity or motorized.';
        break;
    }

    if (_pressureDrop > 0.3) {
      recommendation += ' High pressure drop. Check if damper is undersized or partially closed.';
    }

    setState(() {
      _damperArea = ductArea;
      _faceVelocity = faceVelocity;
      _cvValue = cvValue;
      _recommendedSize = recommendedSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _airflow = 2000;
      _pressureDrop = 0.15;
      _ductWidth = 24;
      _ductHeight = 18;
      _damperType = 'parallel';
      _application = 'control';
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
        title: Text('Damper Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DAMPER TYPE'),
              const SizedBox(height: 12),
              _buildDamperTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT SIZE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Width', _ductWidth, 6, 60, '"', (v) { setState(() => _ductWidth = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Height', _ductHeight, 6, 48, '"', (v) { setState(() => _ductHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AIRFLOW & PRESSURE'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Airflow', _airflow, 200, 10000, ' CFM', (v) { setState(() => _airflow = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Press Drop', _pressureDrop, 0.05, 0.5, '" WC', (v) { setState(() => _pressureDrop = v); _calculate(); }, decimals: 2)),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DAMPER ANALYSIS'),
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
        Icon(LucideIcons.slidersHorizontal, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Damper face velocity 800-1500 fpm for good control. Opposed blade for modulating, parallel for mixing. Fire dampers must match duct.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildDamperTypeSelector(ZaftoColors colors) {
    final types = [('parallel', 'Parallel'), ('opposed', 'Opposed'), ('butterfly', 'Butterfly')];
    return Row(
      children: types.map((t) {
        final selected = _damperType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _damperType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [('control', 'Control'), ('balance', 'Balance'), ('fire', 'Fire/Smoke'), ('backdraft', 'Backdraft')];
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
    if (_faceVelocity == null) return const SizedBox.shrink();

    final isGood = _faceVelocity! >= 800 && _faceVelocity! <= 1500;
    final isHigh = _faceVelocity! > 1500;
    final statusColor = isGood ? Colors.green : (isHigh ? Colors.red : Colors.orange);
    final status = isGood ? 'GOOD VELOCITY' : (isHigh ? 'HIGH VELOCITY' : 'LOW VELOCITY');

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
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Duct Area', '${_damperArea?.toStringAsFixed(2)} ft²')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cv', '${_cvValue?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Ideal Size', '${_recommendedSize?.toStringAsFixed(0)}"')),
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
