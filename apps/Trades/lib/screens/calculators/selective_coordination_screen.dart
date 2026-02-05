import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Selective Coordination Checker - Design System v2.6
/// NEC 700.32, 701.32 - Breaker coordination for critical systems
class SelectiveCoordinationScreen extends ConsumerStatefulWidget {
  const SelectiveCoordinationScreen({super.key});
  @override
  ConsumerState<SelectiveCoordinationScreen> createState() => _SelectiveCoordinationScreenState();
}

class _SelectiveCoordinationScreenState extends ConsumerState<SelectiveCoordinationScreen> {
  int _upstreamAmps = 400;
  int _downstreamAmps = 100;
  String _upstreamType = 'mccb';
  String _downstreamType = 'mccb';
  double _availableFault = 22000;

  double? _coordinationRatio;
  bool? _isCoordinated;
  String? _recommendation;
  String? _necRequirement;

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
        title: Text('Selective Coord', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'UPSTREAM (LINE SIDE)'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Breaker Size', value: _upstreamAmps.toDouble(), min: 100, max: 2000, unit: 'A', onChanged: (v) { setState(() => _upstreamAmps = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildBreakerTypeSelector(colors, 'Type', _upstreamType, (v) { setState(() => _upstreamType = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DOWNSTREAM (LOAD SIDE)'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Breaker Size', value: _downstreamAmps.toDouble(), min: 15, max: 600, unit: 'A', onChanged: (v) { setState(() => _downstreamAmps = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildBreakerTypeSelector(colors, 'Type', _downstreamType, (v) { setState(() => _downstreamType = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FAULT CURRENT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Available Fault', value: _availableFault, min: 5000, max: 65000, unit: ' A', onChanged: (v) { setState(() => _availableFault = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COORDINATION ANALYSIS'),
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
        Expanded(child: Text('NEC 700.32/701.32 - Required for emergency systems', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
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

  Widget _buildBreakerTypeSelector(ZaftoColors colors, String label, String value, ValueChanged<String> onChanged) {
    final types = [('Thermal-Mag', 'tm'), ('MCCB', 'mccb'), ('ELCB', 'elcb'), ('ICCB', 'iccb')];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: types.map((t) => GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onChanged(t.$2); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: value == t.$2 ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: value == t.$2 ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(t.$1, style: TextStyle(color: value == t.$2 ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        )).toList()),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final coordinated = _isCoordinated ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: coordinated ? colors.accentPrimary.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(coordinated ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: coordinated ? colors.accentPrimary : colors.error, size: 32),
          const SizedBox(width: 12),
          Text(coordinated ? 'COORDINATED' : 'NOT COORDINATED', style: TextStyle(color: coordinated ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
        const SizedBox(height: 20),
        _buildCalcRow(colors, 'Upstream breaker', '$_upstreamAmps A'),
        _buildCalcRow(colors, 'Downstream breaker', '$_downstreamAmps A'),
        _buildCalcRow(colors, 'Size ratio', '${_coordinationRatio?.toStringAsFixed(1) ?? '0'}:1'),
        _buildCalcRow(colors, 'Available fault', '${_availableFault.toStringAsFixed(0)} A'),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: coordinated ? colors.accentPrimary.withValues(alpha: 0.1) : colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ANALYSIS', style: TextStyle(color: coordinated ? colors.accentPrimary : colors.error, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_necRequirement ?? 'NEC 700.32', style: TextStyle(color: colors.textTertiary, fontSize: 11))),
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
    final ratio = _upstreamAmps / _downstreamAmps;

    // Simplified coordination check
    // Generally need 2:1 ratio minimum, better with 3:1 or more
    // Also depends on breaker types and trip curves
    bool coordinated = false;
    String rec = '';

    if (ratio >= 3) {
      coordinated = true;
      rec = 'Good coordination ratio (≥3:1). Verify with manufacturer TCC curves.';
    } else if (ratio >= 2) {
      // Might coordinate depending on types
      if (_upstreamType == 'iccb' || _upstreamType == 'elcb') {
        coordinated = true;
        rec = 'Likely coordinated with electronic trip upstream. Verify TCC overlap.';
      } else {
        coordinated = false;
        rec = 'Marginal ratio (2:1). May not coordinate at high fault currents. Consider electronic trip upstream or zone-selective interlocking.';
      }
    } else {
      coordinated = false;
      rec = 'Insufficient ratio (<2:1). Will not selectively coordinate. Options: increase upstream size, add intermediate breaker, or use zone-selective interlocking (ZSI).';
    }

    // Check if fault current is too high for standard breakers
    if (_availableFault > 42000 && (_upstreamType == 'tm' || _downstreamType == 'tm')) {
      rec += ' WARNING: Standard thermal-mag breakers may not be rated for available fault current.';
    }

    setState(() {
      _coordinationRatio = ratio;
      _isCoordinated = coordinated;
      _recommendation = rec;
      _necRequirement = 'NEC 700.32 (Emergency), 701.32 (Legally Required Standby), 708.54 (Critical Operations)';
    });
  }

  void _reset() {
    setState(() {
      _upstreamAmps = 400;
      _downstreamAmps = 100;
      _upstreamType = 'mccb';
      _downstreamType = 'mccb';
      _availableFault = 22000;
    });
    _calculate();
  }
}
