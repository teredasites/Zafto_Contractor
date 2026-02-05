import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Condensate Drain Pan Calculator - Design System v2.6
/// Secondary drain pan sizing and drain line requirements
class DrainPanScreen extends ConsumerStatefulWidget {
  const DrainPanScreen({super.key});
  @override
  ConsumerState<DrainPanScreen> createState() => _DrainPanScreenState();
}

class _DrainPanScreenState extends ConsumerState<DrainPanScreen> {
  double _systemTons = 3;
  double _airHandlerWidth = 24;
  double _airHandlerDepth = 24;
  String _location = 'attic';
  bool _hasSecondaryDrain = false;
  bool _hasFloatSwitch = true;
  String _drainType = 'gravity';

  double? _condensateGph;
  double? _panWidth;
  double? _panDepth;
  String? _drainLineSize;
  double? _minSlope;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Condensate production rate
    // Approximately 0.8-1.5 gallons per hour per ton at design conditions
    // Higher in humid climates
    final condensateGph = _systemTons * 1.2;

    // Pan sizing - must extend 3" beyond unit on all sides
    final panWidth = _airHandlerWidth + 6;
    final panDepth = _airHandlerDepth + 6;

    // Drain line sizing
    // IRC requires 3/4" min for units up to 20 tons
    String drainLineSize;
    if (_systemTons <= 5) {
      drainLineSize = '3/4" PVC';
    } else if (_systemTons <= 10) {
      drainLineSize = '1" PVC';
    } else {
      drainLineSize = '1-1/4" PVC';
    }

    // Minimum slope for gravity drain
    // 1/8" per foot minimum, 1/4" preferred
    final minSlope = 0.125; // inches per foot

    String recommendation;
    if (_location == 'attic' || _location == 'ceiling') {
      recommendation = 'Above living space: Secondary drain pan required by code. Pan must have separate drain to visible location.';
      if (!_hasFloatSwitch) {
        recommendation += ' CRITICAL: Float switch strongly recommended to prevent water damage.';
      }
    } else if (_location == 'basement') {
      recommendation = 'Basement location: Condensate pump may be needed if no gravity drain available.';
    } else {
      recommendation = 'Utility room/garage: Secondary pan recommended but may not be required by code. Check local requirements.';
    }

    if (_drainType == 'pump') {
      recommendation += ' Condensate pump: Size pump for GPH capacity with 25% margin. Float switch integral.';
    } else {
      recommendation += ' Gravity drain: Maintain ${minSlope}/ft minimum slope. Use P-trap to prevent air handler depressurization.';
    }

    if (!_hasSecondaryDrain && (_location == 'attic' || _location == 'ceiling')) {
      recommendation += ' WARNING: Secondary drain line should terminate at visible location to alert of primary blockage.';
    }

    setState(() {
      _condensateGph = condensateGph;
      _panWidth = panWidth;
      _panDepth = panDepth;
      _drainLineSize = drainLineSize;
      _minSlope = minSlope;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemTons = 3;
      _airHandlerWidth = 24;
      _airHandlerDepth = 24;
      _location = 'attic';
      _hasSecondaryDrain = false;
      _hasFloatSwitch = true;
      _drainType = 'gravity';
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
        title: Text('Condensate Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Size', value: _systemTons, min: 1, max: 10, unit: ' tons', decimals: 1, onChanged: (v) { setState(() => _systemTons = v); _calculate(); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'AHU Width', _airHandlerWidth, 18, 60, '"', (v) { setState(() => _airHandlerWidth = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'AHU Depth', _airHandlerDepth, 18, 60, '"', (v) { setState(() => _airHandlerDepth = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INSTALLATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 12),
              _buildDrainTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Secondary drain line', _hasSecondaryDrain, (v) { setState(() => _hasSecondaryDrain = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Float switch / safety cutoff', _hasFloatSwitch, (v) { setState(() => _hasFloatSwitch = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DRAIN REQUIREMENTS'),
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
        Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Secondary pan required above living space. Pan extends 3" beyond unit. Float switch prevents overflow damage.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = [
      ('attic', 'Attic'),
      ('ceiling', 'Above Ceiling'),
      ('basement', 'Basement'),
      ('utility', 'Utility Room'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipment Location', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: locations.map((l) {
            final selected = _location == l.$1;
            return GestureDetector(
              onTap: () { setState(() => _location = l.$1); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDrainTypeSelector(ZaftoColors colors) {
    final types = [('gravity', 'Gravity Drain'), ('pump', 'Condensate Pump')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Drain Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _drainType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _drainType = t.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_drainLineSize == null) return const SizedBox.shrink();

    final requiresSecondary = _location == 'attic' || _location == 'ceiling';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          if (requiresSecondary && !_hasSecondaryDrain)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('SECONDARY PAN REQUIRED BY CODE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('PAN SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${_panWidth?.toStringAsFixed(0)}" × ${_panDepth?.toStringAsFixed(0)}"', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('DRAIN LINE', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_drainLineSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Condensate', '${_condensateGph?.toStringAsFixed(1)} GPH')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Min Slope', '${_minSlope}"/ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Float Switch', _hasFloatSwitch ? 'Yes' : 'No')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
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
