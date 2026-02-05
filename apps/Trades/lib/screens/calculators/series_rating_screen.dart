import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Series Rating Checker - Design System v2.6
/// NEC 240.86 - Series-rated combination verification
class SeriesRatingScreen extends ConsumerStatefulWidget {
  const SeriesRatingScreen({super.key});
  @override
  ConsumerState<SeriesRatingScreen> createState() => _SeriesRatingScreenState();
}

class _SeriesRatingScreenState extends ConsumerState<SeriesRatingScreen> {
  int _lineSideAmps = 200;
  int _loadSideAmps = 100;
  int _lineSideAic = 22;
  int _loadSideAic = 10;
  double _availableFault = 18000;

  bool? _isValidCombination;
  String? _seriesRating;
  String? _requirements;
  List<String> _warnings = [];

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
        title: Text('Series Rating', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LINE-SIDE DEVICE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Breaker Size', value: _lineSideAmps.toDouble(), min: 100, max: 800, unit: ' A', onChanged: (v) { setState(() => _lineSideAmps = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'AIC Rating', value: _lineSideAic.toDouble(), min: 10, max: 100, unit: ' kA', onChanged: (v) { setState(() => _lineSideAic = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD-SIDE DEVICE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Breaker Size', value: _loadSideAmps.toDouble(), min: 15, max: 400, unit: ' A', onChanged: (v) { setState(() => _loadSideAmps = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'AIC Rating', value: _loadSideAic.toDouble(), min: 10, max: 65, unit: ' kA', onChanged: (v) { setState(() => _loadSideAic = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AVAILABLE FAULT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'At Equipment', value: _availableFault, min: 5000, max: 65000, unit: ' A', onChanged: (v) { setState(() => _availableFault = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SERIES RATING CHECK'),
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
        Expanded(child: Text('NEC 240.86 - Series combination must be tested/listed', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
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
          child: Slider(value: value, min: min, max: max, divisions: ((max - min) / 5).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final valid = _isValidCombination ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: valid ? colors.accentPrimary.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(valid ? LucideIcons.checkCircle : LucideIcons.xCircle, color: valid ? colors.accentPrimary : colors.error, size: 32),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valid ? 'MAY BE VALID' : 'NOT VALID', style: TextStyle(color: valid ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Series combination', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('EFFECTIVE RATING', style: TextStyle(color: colors.textTertiary, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(_seriesRating ?? '22 kAIC', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 28)),
          ]),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Line-side device', '$_lineSideAmps A / ${_lineSideAic} kAIC'),
        _buildCalcRow(colors, 'Load-side device', '$_loadSideAmps A / ${_loadSideAic} kAIC'),
        _buildCalcRow(colors, 'Available fault', '${(_availableFault / 1000).toStringAsFixed(1)} kA'),
        const SizedBox(height: 16),
        if (_warnings.isNotEmpty) ...[
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          ..._warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(w, style: TextStyle(color: colors.warning, fontSize: 12))),
            ]),
          )),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REQUIREMENTS (NEC 240.86)', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_requirements ?? '', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
    final warnings = <String>[];
    bool valid = true;

    // Check if available fault exceeds load-side device's standalone rating
    if (_availableFault > _loadSideAic * 1000) {
      // This is the scenario where series rating is needed
      // Series rating allows using lower-rated downstream device

      // Check if line-side device can handle the fault
      if (_availableFault > _lineSideAic * 1000) {
        valid = false;
        warnings.add('Available fault (${(_availableFault / 1000).toStringAsFixed(0)} kA) exceeds line-side AIC rating ($_lineSideAic kA)');
      }

      // Check ratio (typically need 2:1 or better)
      final ratio = _lineSideAmps / _loadSideAmps;
      if (ratio < 2) {
        warnings.add('Size ratio (${ratio.toStringAsFixed(1)}:1) may not allow series rating. Most tested combinations require 2:1 or greater.');
      }
    }

    // The effective series rating is the line-side device's rating
    // (when the combination is listed/tested)
    final seriesRating = '${_lineSideAic} kAIC';

    // Requirements text
    const reqs = '''1. Combination must be tested and marked by manufacturer
2. Series rating label required on equipment
3. Cannot be used for:
   - Motor circuits
   - Elevator circuits
   - Emergency systems (per 700.32)
   - Legally required standby (per 701.32)
4. Selected under engineering supervision''';

    // Additional check for motor circuits
    if (_loadSideAmps >= 15 && _loadSideAmps <= 50) {
      warnings.add('If this protects a motor circuit, series rating is NOT permitted per NEC 240.86(A)');
    }

    setState(() {
      _isValidCombination = valid && warnings.isEmpty;
      _seriesRating = seriesRating;
      _requirements = reqs;
      _warnings = warnings;
    });
  }

  void _reset() {
    setState(() {
      _lineSideAmps = 200;
      _loadSideAmps = 100;
      _lineSideAic = 22;
      _loadSideAic = 10;
      _availableFault = 18000;
    });
    _calculate();
  }
}
