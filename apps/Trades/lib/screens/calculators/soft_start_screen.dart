import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Soft Start Sizing Calculator - Design System v2.6
/// Reduced voltage motor starter sizing
class SoftStartScreen extends ConsumerStatefulWidget {
  const SoftStartScreen({super.key});
  @override
  ConsumerState<SoftStartScreen> createState() => _SoftStartScreenState();
}

class _SoftStartScreenState extends ConsumerState<SoftStartScreen> {
  double _motorHp = 25;
  int _voltage = 460;
  String _startType = 'normal';
  int _startsPerHour = 4;

  double? _motorFla;
  double? _softStartAmps;
  double? _reducedInrush;
  String? _modelSize;
  String? _bypassOption;

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
        title: Text('Soft Start', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MOTOR'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Horsepower', value: _motorHp, min: 5, max: 500, unit: ' HP', onChanged: (v) { setState(() => _motorHp = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['208V', '230V', '460V', '575V'], selectedIndex: _voltage == 208 ? 0 : _voltage == 230 ? 1 : _voltage == 460 ? 2 : 3, onChanged: (i) { setState(() => _voltage = [208, 230, 460, 575][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'APPLICATION'),
              const SizedBox(height: 12),
              _buildStartTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Starts per Hour', value: _startsPerHour.toDouble(), min: 1, max: 20, unit: '', onChanged: (v) { setState(() => _startsPerHour = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SOFT START SIZING'),
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
        Expanded(child: Text('Reduced voltage starter - limits inrush to 2-4× FLA', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
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
          Text('${value.toStringAsFixed(value < 10 ? 1 : 0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
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

  Widget _buildStartTypeSelector(ZaftoColors colors) {
    final types = [
      ('Normal', 'normal', 'Centrifugal pumps, fans'),
      ('Heavy', 'heavy', 'Loaded conveyors, compressors'),
      ('Light', 'light', 'Unloaded starts'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Start Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        ...types.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _startType = t.$2); _calculate(); },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _startType == t.$2 ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: _startType == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
              child: Row(children: [
                Icon(_startType == t.$2 ? LucideIcons.checkCircle : LucideIcons.circle, color: _startType == t.$2 ? colors.accentPrimary : colors.textTertiary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$1, style: TextStyle(color: _startType == t.$2 ? colors.accentPrimary : colors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(t.$3, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                ])),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_softStartAmps?.toStringAsFixed(0) ?? '0'}A', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('soft start rating', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_modelSize ?? 'Size 3', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Motor FLA', '${_motorFla?.toStringAsFixed(1) ?? '0'} A'),
        _buildCalcRow(colors, 'DOL inrush (6×)', '${((_motorFla ?? 0) * 6).toStringAsFixed(0)} A'),
        _buildCalcRow(colors, 'Soft start inrush (3×)', '${_reducedInrush?.toStringAsFixed(0) ?? '0'} A'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Soft start rating', '${_softStartAmps?.toStringAsFixed(0) ?? '0'} A', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recommendations:', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_bypassOption ?? 'Internal bypass contactor recommended', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
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
    // Get motor FLA (simplified for 3-phase)
    double fla;
    if (_voltage <= 230) {
      fla = _motorHp * 2.5;
    } else if (_voltage <= 460) {
      fla = _motorHp * 1.25;
    } else {
      fla = _motorHp * 1.0;
    }

    // Soft start sizing factor based on application
    double sizingFactor;
    switch (_startType) {
      case 'heavy':
        sizingFactor = 1.5; // Size up for heavy loads
        break;
      case 'light':
        sizingFactor = 1.0;
        break;
      default:
        sizingFactor = 1.2;
    }

    // Adjust for frequent starts
    if (_startsPerHour > 10) {
      sizingFactor *= 1.25;
    } else if (_startsPerHour > 5) {
      sizingFactor *= 1.1;
    }

    final softStartRating = fla * sizingFactor;
    final reducedInrush = fla * 3; // Typical soft start limits to 3× FLA

    // Determine size designation
    String size;
    if (softStartRating <= 18) size = 'Size 1 (18A)';
    else if (softStartRating <= 27) size = 'Size 2 (27A)';
    else if (softStartRating <= 45) size = 'Size 3 (45A)';
    else if (softStartRating <= 85) size = 'Size 4 (85A)';
    else if (softStartRating <= 135) size = 'Size 5 (135A)';
    else if (softStartRating <= 200) size = 'Size 6 (200A)';
    else if (softStartRating <= 361) size = 'Size 7 (361A)';
    else size = 'Size 8+ (>361A)';

    // Bypass recommendation
    String bypass;
    if (_motorHp >= 50) {
      bypass = 'Internal bypass contactor required for thermal protection';
    } else if (_startsPerHour > 10) {
      bypass = 'External bypass contactor recommended for frequent starts';
    } else {
      bypass = 'Internal bypass contactor recommended';
    }

    setState(() {
      _motorFla = fla;
      _softStartAmps = softStartRating;
      _reducedInrush = reducedInrush;
      _modelSize = size;
      _bypassOption = bypass;
    });
  }

  void _reset() {
    setState(() {
      _motorHp = 25;
      _voltage = 460;
      _startType = 'normal';
      _startsPerHour = 4;
    });
    _calculate();
  }
}
