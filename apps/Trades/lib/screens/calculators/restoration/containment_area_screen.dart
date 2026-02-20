import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Containment Area Calculator — IICRC S520
///
/// Calculates poly sheeting, tape, zippers, and negative air requirements
/// for mold remediation and biohazard containment setup.
///
/// References: IICRC S520-2015, EPA Mold Remediation in Schools (2008),
/// NYC Dept of Health Guidelines on Assessment and Remediation of Fungi
class ContainmentAreaScreen extends ConsumerStatefulWidget {
  const ContainmentAreaScreen({super.key});
  @override
  ConsumerState<ContainmentAreaScreen> createState() => _ContainmentAreaScreenState();
}

class _ContainmentAreaScreenState extends ConsumerState<ContainmentAreaScreen> {
  double _length = 15;
  double _width = 12;
  double _ceilingHeight = 8;
  int _containmentLevel = 2; // 1=mini, 2=full, 3=critical
  int _numOpenings = 2; // doors/windows needing poly cover
  bool _doubleLayer = false;
  bool _needDeconChamber = false;

  double get _floorArea => _length * _width;
  double get _perimeter => 2 * (_length + _width);

  /// Wall poly: perimeter × ceiling height + 10% overlap
  double get _wallPolySqft => _perimeter * _ceilingHeight * 1.1;

  /// Ceiling poly: floor area + 10% drape overlap
  double get _ceilingPolySqft => _containmentLevel >= 2 ? _floorArea * 1.1 : 0;

  /// Floor poly: for critical barrier, floor covered too
  double get _floorPolySqft => _containmentLevel >= 3 ? _floorArea * 1.1 : 0;

  /// Total poly sheeting in sq ft
  double get _totalPolySqft {
    double total = _wallPolySqft + _ceilingPolySqft + _floorPolySqft;
    if (_doubleLayer) total *= 2;
    if (_needDeconChamber) total += 120; // ~60 sqft decon chamber, double-walled
    return total;
  }

  /// 6-mil poly rolls: standard 10ft × 100ft = 1,000 sqft per roll
  int get _polyRolls => math.max(1, (_totalPolySqft / 1000).ceil());

  /// Tape: perimeter seams + ceiling seams + overlap joints
  /// Estimate 1.5× perimeter for walls, 1× for ceiling grid
  double get _tapeLF {
    double lf = _perimeter * 1.5; // wall-to-wall seams
    if (_containmentLevel >= 2) lf += _perimeter; // ceiling seams
    if (_containmentLevel >= 3) lf += _perimeter * 0.5; // floor seams
    lf += _numOpenings * 20; // ~20 LF tape per opening seal
    return lf;
  }

  /// Tape rolls: standard 180 ft per roll
  int get _tapeRolls => math.max(1, (_tapeLF / 180).ceil());

  /// Containment zippers: one per entry/exit point
  int get _zipperCount {
    int count = 1; // primary entry
    if (_containmentLevel >= 2) count += 1; // emergency exit
    if (_needDeconChamber) count += 2; // decon entry + exit
    return count;
  }

  /// Negative air machines: 1 ACH minimum for containment
  /// IICRC S520: maintain negative pressure of -0.02" WC
  /// Rule: 1 NAM per 10,000 cu ft for standard, 1 per 5,000 for critical
  int get _negativeMachines {
    final volume = _floorArea * _ceilingHeight;
    final perUnit = _containmentLevel >= 3 ? 5000.0 : 10000.0;
    return math.max(1, (volume / perUnit).ceil());
  }

  /// Estimated setup labor hours
  double get _setupHours {
    double hrs = 1.0; // base setup
    hrs += (_totalPolySqft / 500) * 0.5; // ~30 min per 500 sqft poly
    hrs += _numOpenings * 0.25; // 15 min per opening seal
    if (_needDeconChamber) hrs += 1.5; // decon chamber build
    if (_doubleLayer) hrs *= 1.3; // 30% longer for double layer
    return hrs;
  }

  void _reset() => setState(() {
    _length = 15; _width = 12; _ceilingHeight = 8;
    _containmentLevel = 2; _numOpenings = 2;
    _doubleLayer = false; _needDeconChamber = false;
  });

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Containment Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel(colors, 'Room Dimensions'),
            _slider(colors, 'Length', _length, 5, 60, 'ft', (v) => setState(() => _length = v)),
            _slider(colors, 'Width', _width, 5, 50, 'ft', (v) => setState(() => _width = v)),
            _slider(colors, 'Ceiling', _ceilingHeight, 7, 20, 'ft', (v) => setState(() => _ceilingHeight = v)),
            const SizedBox(height: 16),
            _sectionLabel(colors, 'Containment Level'),
            _levelSelector(colors),
            const SizedBox(height: 12),
            _slider(colors, 'Openings', _numOpenings.toDouble(), 0, 8, '', (v) => setState(() => _numOpenings = v.round())),
            const SizedBox(height: 8),
            _check(colors, 'Double-layer poly (critical/biohazard)', _doubleLayer, (v) => setState(() => _doubleLayer = v)),
            _check(colors, 'Decontamination chamber required', _needDeconChamber, (v) => setState(() => _needDeconChamber = v)),
            const SizedBox(height: 24),
            _resultCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(ZaftoColors c, String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary, letterSpacing: 0.5)));

  Widget _slider(ZaftoColors c, String label, double val, double min, double max, String unit, ValueChanged<double> cb) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 65, child: Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13))),
      Expanded(child: Slider(value: val, min: min, max: max, divisions: ((max - min) * 2).round(), onChanged: cb, activeColor: c.accentPrimary)),
      SizedBox(width: 55, child: Text('${val.toStringAsFixed(val == val.roundToDouble() ? 0 : 1)}${unit.isNotEmpty ? ' $unit' : ''}', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
    ]));
  }

  Widget _levelSelector(ZaftoColors c) {
    final levels = {1: 'Mini', 2: 'Full', 3: 'Critical'};
    final descs = {1: 'Small area, low risk', 2: '10-100 sqft mold, standard', 3: '>100 sqft, biohazard, or HVAC involved'};
    return Column(children: levels.entries.map((e) {
      final sel = _containmentLevel == e.key;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _containmentLevel = e.key); },
        child: Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: sel ? c.accentPrimary : c.fillDefault, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? (c.isDark ? Colors.black : Colors.white) : c.textPrimary)),
            Text(descs[e.key]!, style: TextStyle(fontSize: 11, color: sel ? (c.isDark ? Colors.black54 : Colors.white70) : c.textTertiary)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _check(ZaftoColors c, String label, bool val, ValueChanged<bool> cb) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
      Checkbox(value: val, onChanged: (v) => cb(v ?? false), activeColor: c.accentPrimary, side: BorderSide(color: c.borderSubtle)),
      Expanded(child: Text(label, style: TextStyle(color: c.textPrimary, fontSize: 13))),
    ]));
  }

  Widget _resultCard(ZaftoColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MATERIALS NEEDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accentPrimary, letterSpacing: 1)),
        const SizedBox(height: 12),
        _row(c, '6-mil Poly Sheeting', '${_totalPolySqft.toStringAsFixed(0)} sqft ($_polyRolls roll${_polyRolls > 1 ? "s" : ""})'),
        _row(c, 'Seam Tape', '${_tapeLF.toStringAsFixed(0)} LF ($_tapeRolls roll${_tapeRolls > 1 ? "s" : ""})'),
        _row(c, 'Containment Zippers', '$_zipperCount'),
        _row(c, 'Negative Air Machines', '$_negativeMachines'),
        const Divider(height: 20),
        _row(c, 'Contained Area', '${_floorArea.toStringAsFixed(0)} sqft'),
        _row(c, 'Est. Setup Time', '${_setupHours.toStringAsFixed(1)} hours'),
        if (_containmentLevel >= 3) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, size: 14, color: c.accentWarning),
              const SizedBox(width: 8),
              Expanded(child: Text('Critical containment requires airlock decon chamber, HEPA-filtered negative air, and worker PPE per OSHA 29 CFR 1926.1101.', style: TextStyle(fontSize: 11, color: c.textSecondary, height: 1.4))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _row(ZaftoColors c, String label, String val) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13)),
      Text(val, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]));
  }
}
