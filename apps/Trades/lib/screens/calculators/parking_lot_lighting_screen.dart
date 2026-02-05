import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Parking Lot Lighting Calculator - Design System v2.6
/// IES RP-20 recommended practice for parking facilities
class ParkingLotLightingScreen extends ConsumerStatefulWidget {
  const ParkingLotLightingScreen({super.key});
  @override
  ConsumerState<ParkingLotLightingScreen> createState() => _ParkingLotLightingScreenState();
}

class _ParkingLotLightingScreenState extends ConsumerState<ParkingLotLightingScreen> {
  double _lotLength = 200;
  double _lotWidth = 150;
  String _lightLevel = 'basic';
  double _poleHeight = 25;
  double _fixtureOutput = 20000;

  double? _lotArea;
  double? _targetFc;
  double? _totalLumens;
  int? _fixturesNeeded;
  double? _spacing;
  double? _totalWatts;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Parking Lot Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOT DIMENSIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Length', value: _lotLength, min: 50, max: 500, unit: ' ft', onChanged: (v) { setState(() => _lotLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Width', value: _lotWidth, min: 50, max: 500, unit: ' ft', onChanged: (v) { setState(() => _lotWidth = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LIGHTING LEVEL'),
              const SizedBox(height: 12),
              _buildLightLevelSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FIXTURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Pole Height', value: _poleHeight, min: 15, max: 40, unit: ' ft', onChanged: (v) { setState(() => _poleHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Fixture Output', value: _fixtureOutput, min: 5000, max: 50000, unit: ' lm', onChanged: (v) { setState(() => _fixtureOutput = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'LIGHTING DESIGN'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('IES RP-20 recommended illuminance levels', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round() ~/ 5, onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildLightLevelSelector(ZaftoColors colors) {
    final levels = [
      ('Basic', 'basic', '0.5 fc - Economy parking'),
      ('General', 'general', '1.0 fc - Most parking lots'),
      ('Enhanced', 'enhanced', '2.0 fc - High security'),
      ('Retail', 'retail', '5.0 fc - Shopping centers'),
    ];
    return Column(children: levels.map((l) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _lightLevel = l.$2); _calculate(); },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _lightLevel == l.$2 ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: _lightLevel == l.$2 ? colors.accentPrimary : colors.borderSubtle)),
          child: Row(children: [
            Icon(_lightLevel == l.$2 ? LucideIcons.checkCircle : LucideIcons.circle, color: _lightLevel == l.$2 ? colors.accentPrimary : colors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.$1, style: TextStyle(color: _lightLevel == l.$2 ? colors.accentPrimary : colors.textPrimary, fontWeight: FontWeight.w600)),
              Text(l.$3, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ])),
          ]),
        ),
      ),
    )).toList());
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_fixturesNeeded ?? 0}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('fixtures required', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildSpecCard(colors, '${_spacing?.toStringAsFixed(0) ?? '0'}', 'ft spacing'),
          _buildSpecCard(colors, '${(_totalWatts ?? 0 / 1000).toStringAsFixed(1)}', 'kW total'),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Lot area', '${_lotArea?.toStringAsFixed(0) ?? '0'} sq ft'),
        _buildCalcRow(colors, 'Target illuminance', '${_targetFc?.toStringAsFixed(1) ?? '0'} fc'),
        _buildCalcRow(colors, 'Total lumens needed', '${_totalLumens?.toStringAsFixed(0) ?? '0'} lm'),
        _buildCalcRow(colors, 'Fixtures needed', '${_fixturesNeeded ?? 0}'),
        _buildCalcRow(colors, 'Fixture spacing', '${_spacing?.toStringAsFixed(0) ?? '0'} ft'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Total load', '${_totalWatts?.toStringAsFixed(0) ?? '0'} W', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DESIGN NOTES', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('• Spacing ≤ 4× pole height for uniform coverage\n• Use Type III or V distribution\n• Consider light trespass at property lines\n• LED fixtures: ~150 lm/W efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final area = _lotLength * _lotWidth;

    // Target footcandles based on level
    double targetFc;
    switch (_lightLevel) {
      case 'basic': targetFc = 0.5; break;
      case 'general': targetFc = 1.0; break;
      case 'enhanced': targetFc = 2.0; break;
      case 'retail': targetFc = 5.0; break;
      default: targetFc = 1.0;
    }

    // Lumens needed = area × fc × coefficient of utilization (typically 0.3-0.5)
    // Using 0.4 CU and 0.85 maintenance factor
    final lumensNeeded = (area * targetFc) / (0.4 * 0.85);

    // Fixtures needed
    final fixtures = (lumensNeeded / _fixtureOutput).ceil();

    // Recommended spacing (max 4× pole height for good uniformity)
    final maxSpacing = _poleHeight * 4;
    // Calculate actual spacing based on fixture count
    final spacing = (_lotLength / ((fixtures / 2).ceil())).clamp(30.0, maxSpacing);

    // Total watts (assuming LED ~150 lm/W)
    final wattsPerFixture = _fixtureOutput / 150;
    final totalWatts = wattsPerFixture * fixtures;

    setState(() {
      _lotArea = area;
      _targetFc = targetFc;
      _totalLumens = lumensNeeded;
      _fixturesNeeded = fixtures;
      _spacing = spacing;
      _totalWatts = totalWatts;
    });
  }

  void _reset() {
    setState(() {
      _lotLength = 200;
      _lotWidth = 150;
      _lightLevel = 'basic';
      _poleHeight = 25;
      _fixtureOutput = 20000;
    });
    _calculate();
  }
}
