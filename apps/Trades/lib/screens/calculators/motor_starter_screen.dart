import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor Starter Sizing Calculator - Design System v2.6
/// NEMA starter and overload relay sizing per NEC 430
class MotorStarterScreen extends ConsumerStatefulWidget {
  const MotorStarterScreen({super.key});
  @override
  ConsumerState<MotorStarterScreen> createState() => _MotorStarterScreenState();
}

class _MotorStarterScreenState extends ConsumerState<MotorStarterScreen> {
  double _motorFla = 28;
  double _motorHp = 10;
  int _voltage = 460;
  String _startType = 'DOL';
  double _serviceFactor = 1.15;

  // NEMA Starter Sizes - Max continuous amperage
  static const Map<String, Map<String, double>> _nemaStarterSizes = {
    // Size: {voltage: max_continuous_amps}
    '00': {'240': 9, '480': 9, '600': 9},
    '0': {'240': 18, '480': 18, '600': 18},
    '1': {'240': 27, '480': 27, '600': 27},
    '2': {'240': 45, '480': 45, '600': 45},
    '3': {'240': 90, '480': 90, '600': 90},
    '4': {'240': 135, '480': 135, '600': 135},
    '5': {'240': 270, '480': 270, '600': 270},
    '6': {'240': 540, '480': 540, '600': 540},
    '7': {'240': 810, '480': 810, '600': 810},
    '8': {'240': 1215, '480': 1215, '600': 1215},
    '9': {'240': 2250, '480': 2250, '600': 2250},
  };

  // NEMA Starter Sizes - Max HP ratings at different voltages
  static const Map<String, Map<int, double>> _nemaStarterHp = {
    '00': {200: 1.5, 230: 2, 460: 2, 575: 2},
    '0': {200: 3, 230: 3, 460: 5, 575: 5},
    '1': {200: 7.5, 230: 7.5, 460: 10, 575: 10},
    '2': {200: 10, 230: 15, 460: 25, 575: 25},
    '3': {200: 25, 230: 30, 460: 50, 575: 50},
    '4': {200: 40, 230: 50, 460: 100, 575: 100},
    '5': {200: 75, 230: 100, 460: 200, 575: 200},
    '6': {200: 150, 230: 200, 460: 400, 575: 400},
    '7': {200: 300, 230: 300, 460: 600, 575: 600},
    '8': {200: 450, 230: 450, 460: 900, 575: 900},
    '9': {200: 800, 230: 800, 460: 1600, 575: 1600},
  };

  static const List<String> _startTypes = ['DOL', 'Wye-Delta', 'Autotrans', 'Soft Start', 'VFD'];

  String get _voltageKey {
    if (_voltage <= 240) return '240';
    if (_voltage <= 480) return '480';
    return '600';
  }

  int get _voltageHpKey {
    if (_voltage <= 200) return 200;
    if (_voltage <= 230) return 230;
    if (_voltage <= 460) return 460;
    return 575;
  }

  // NEC 430.32 - Overload protection
  double get _overloadTripAmps {
    // Service factor >= 1.15: 125% of FLA
    // Service factor < 1.15: 115% of FLA
    return _serviceFactor >= 1.15 ? _motorFla * 1.25 : _motorFla * 1.15;
  }

  // Select NEMA starter size based on FLA
  String get _nemaStarterSize {
    for (final entry in _nemaStarterSizes.entries) {
      final maxAmps = entry.value[_voltageKey] ?? 0;
      if (_motorFla <= maxAmps) return entry.key;
    }
    return '9+';
  }

  // Select NEMA starter size based on HP
  String get _nemaStarterSizeByHp {
    for (final entry in _nemaStarterHp.entries) {
      final maxHp = entry.value[_voltageHpKey] ?? 0;
      if (_motorHp <= maxHp) return entry.key;
    }
    return '9+';
  }

  // Use larger of the two sizes
  String get _recommendedSize {
    final sizes = ['00', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '9+'];
    final byFla = sizes.indexOf(_nemaStarterSize);
    final byHp = sizes.indexOf(_nemaStarterSizeByHp);
    return sizes[byFla > byHp ? byFla : byHp];
  }

  // Reduced voltage start - lower inrush
  double get _reducedInrush {
    switch (_startType) {
      case 'Wye-Delta': return 0.33;
      case 'Autotrans': return 0.65;
      case 'Soft Start': return 0.50;
      case 'VFD': return 1.0; // No inrush issue
      default: return 1.0; // DOL - full inrush
    }
  }

  double get _estimatedInrush => _motorFla * 6 * _reducedInrush;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Motor Starter Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMotorDataCard(colors),
          const SizedBox(height: 16),
          _buildStartTypeCard(colors),
          const SizedBox(height: 16),
          _buildServiceFactorCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildNemaTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildMotorDataCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MOTOR DATA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FLA (Amps)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_motorFla.toStringAsFixed(1)}A', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              Expanded(child: SliderTheme(
                data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
                child: Slider(value: _motorFla, min: 1, max: 500, divisions: 499, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _motorFla = v); }),
              )),
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('HP', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_motorHp.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              Expanded(child: SliderTheme(
                data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
                child: Slider(value: _motorHp, min: 0.5, max: 500, divisions: 999, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _motorHp = v); }),
              )),
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        Text('Voltage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [208, 230, 460, 480, 575].map((v) {
          final isSelected = _voltage == v;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _voltage = v); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildStartTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('START TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _startTypes.map((type) {
          final isSelected = _startType == type;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _startType = type); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(type, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text(_startType == 'DOL' ? 'Direct On Line - Full voltage start' : 'Reduced voltage/current start', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildServiceFactorCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SERVICE FACTOR (SF)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [1.0, 1.15, 1.25].map((sf) {
          final isSelected = _serviceFactor == sf;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _serviceFactor = sf); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(sf.toStringAsFixed(2), style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text(_serviceFactor >= 1.15 ? 'Overload: 125% of FLA' : 'Overload: 115% of FLA', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('NEMA $_recommendedSize', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('Starter Size', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Motor FLA', '${_motorFla.toStringAsFixed(1)}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Motor HP', '${_motorHp.toStringAsFixed(1)} HP'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Size by FLA', 'NEMA $_nemaStarterSize'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Size by HP', 'NEMA $_nemaStarterSizeByHp'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Overload Trip', '${_overloadTripAmps.toStringAsFixed(1)}A', highlight: true),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Est. Inrush', '${_estimatedInrush.toStringAsFixed(0)}A (${(_reducedInrush * 100).toInt()}%)'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildNemaTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEMA STARTER SIZES (480V)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: ['00', '0', '1', '2', '3', '4', '5'].map((size) {
          final maxAmps = _nemaStarterSizes[size]?['480'] ?? 0;
          final maxHp = _nemaStarterHp[size]?[460] ?? 0;
          final isHighlighted = _recommendedSize == size;
          return Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
              borderRadius: BorderRadius.circular(6),
              border: isHighlighted ? Border.all(color: colors.accentPrimary) : null,
            ),
            child: Column(children: [
              Text(size, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${maxAmps.toInt()}A', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              Text('${maxHp.toInt()}HP', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 430 / NEMA ICS 2', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• NEMA ICS 2 - Starter sizing standards\n• NEC 430.32 - Overload protection\n• SF >= 1.15: 125% max overload\n• SF < 1.15: 115% max overload', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
