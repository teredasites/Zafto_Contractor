import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../data/wire_tables.dart';

/// Ampacity Calculator - Design System v2.6
class AmpacityScreen extends ConsumerStatefulWidget {
  const AmpacityScreen({super.key});
  @override
  ConsumerState<AmpacityScreen> createState() => _AmpacityScreenState();
}

class _AmpacityScreenState extends ConsumerState<AmpacityScreen> {
  WireSize _wireSize = WireSize.awg12;
  ConductorMaterial _material = ConductorMaterial.copper;
  TempRating _tempRating = TempRating.temp75c;
  int _ambientTemp = 30;
  int _conductorCount = 3;
  double? _baseAmpacity;
  double? _tempFactor;
  double? _fillFactor;
  double? _adjustedAmpacity;

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
        title: Text('Ampacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONDUCTOR'),
              const SizedBox(height: 12),
              _buildDropdownRow(colors, label: 'Wire Size', child: DropdownButton<WireSize>(
                value: _wireSize,
                dropdownColor: colors.bgElevated,
                underline: const SizedBox(),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                items: WireSize.values.where((w) => w.numericValue >= -3 && w.numericValue <= 14).map((w) => DropdownMenuItem(value: w, child: Text(w.displayName))).toList(),
                onChanged: (v) { setState(() => _wireSize = v!); _calculate(); },
              )),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Material', options: const ['Copper', 'Aluminum'], selectedIndex: _material == ConductorMaterial.copper ? 0 : 1, onChanged: (i) { setState(() => _material = i == 0 ? ConductorMaterial.copper : ConductorMaterial.aluminum); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Insulation Rating', options: const ['60°C', '75°C', '90°C'], selectedIndex: _tempRating == TempRating.temp60c ? 0 : _tempRating == TempRating.temp75c ? 1 : 2, onChanged: (i) { setState(() => _tempRating = i == 0 ? TempRating.temp60c : i == 1 ? TempRating.temp75c : TempRating.temp90c); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CORRECTION FACTORS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ambient Temperature', value: _ambientTemp, min: 21, max: 60, unit: '°C', onChanged: (v) { setState(() => _ambientTemp = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Current-Carrying Conductors', value: _conductorCount, min: 1, max: 20, unit: '', divisions: 19, onChanged: (v) { setState(() => _conductorCount = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ADJUSTED AMPACITY'),
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
        Expanded(child: Text('NEC 310.16 with temperature and conduit fill derating', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildDropdownRow(ZaftoColors colors, {required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))), child]),
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: List.generate(options.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(i); },
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selectedIndex == i ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: selectedIndex == i ? colors.accentPrimary : colors.borderSubtle)),
              alignment: Alignment.center,
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required int value, required int min, required int max, required String unit, int? divisions, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('$value$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: divisions ?? (max - min), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_adjustedAmpacity?.toStringAsFixed(1) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps adjusted', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Base ampacity (${_wireSize.displayName} ${_material.name})', '${_baseAmpacity?.toStringAsFixed(0) ?? '0'} A'),
        _buildCalcRow(colors, 'Temp factor (${_ambientTemp}°C)', '× ${_tempFactor?.toStringAsFixed(2) ?? '1.00'}'),
        _buildCalcRow(colors, 'Fill factor ($_conductorCount conductors)', '× ${_fillFactor?.toStringAsFixed(2) ?? '1.00'}'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Adjusted ampacity', '${_adjustedAmpacity?.toStringAsFixed(1) ?? '0'} A', highlight: true),
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
    final base = WireTables.getAmpacity(_wireSize, _tempRating, material: _material);
    double tempFactor = 1.0;
    if (_ambientTemp > 30) tempFactor = _getTempCorrectionFactor(_ambientTemp, _tempRating);
    double fillFactor = _getFillAdjustmentFactor(_conductorCount);
    final adjusted = (base ?? 0) * tempFactor * fillFactor;
    setState(() { _baseAmpacity = base?.toDouble(); _tempFactor = tempFactor; _fillFactor = fillFactor; _adjustedAmpacity = adjusted; });
  }

  double _getTempCorrectionFactor(int ambientTemp, TempRating rating) {
    if (ambientTemp <= 30) return 1.0;
    if (rating == TempRating.temp60c) { if (ambientTemp <= 35) return 0.91; if (ambientTemp <= 40) return 0.82; if (ambientTemp <= 45) return 0.71; if (ambientTemp <= 50) return 0.58; if (ambientTemp <= 55) return 0.41; return 0.0; }
    if (rating == TempRating.temp75c) { if (ambientTemp <= 35) return 0.94; if (ambientTemp <= 40) return 0.88; if (ambientTemp <= 45) return 0.82; if (ambientTemp <= 50) return 0.75; if (ambientTemp <= 55) return 0.67; if (ambientTemp <= 60) return 0.58; return 0.0; }
    if (ambientTemp <= 35) return 0.96; if (ambientTemp <= 40) return 0.91; if (ambientTemp <= 45) return 0.87; if (ambientTemp <= 50) return 0.82; if (ambientTemp <= 55) return 0.76; if (ambientTemp <= 60) return 0.71; return 0.0;
  }

  double _getFillAdjustmentFactor(int conductorCount) {
    if (conductorCount <= 3) return 1.0; if (conductorCount <= 6) return 0.80; if (conductorCount <= 9) return 0.70; if (conductorCount <= 20) return 0.50; if (conductorCount <= 30) return 0.45; if (conductorCount <= 40) return 0.40; return 0.35;
  }

  void _reset() { setState(() { _wireSize = WireSize.awg12; _material = ConductorMaterial.copper; _tempRating = TempRating.temp75c; _ambientTemp = 30; _conductorCount = 3; }); _calculate(); }
}
