import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Antimicrobial Application Calculator — IICRC S520
///
/// Calculates antimicrobial product volumes, dilution ratios, dwell times,
/// and coverage rates for mold remediation and biohazard cleanup.
///
/// References: IICRC S520-2015, EPA List N (registered antimicrobials),
/// product SDS dilution rates, OSHA respiratory protection standards
class AntimicrobialDosingScreen extends ConsumerStatefulWidget {
  const AntimicrobialDosingScreen({super.key});
  @override
  ConsumerState<AntimicrobialDosingScreen> createState() => _AntimicrobialDosingScreenState();
}

class _AntimicrobialDosingScreenState extends ConsumerState<AntimicrobialDosingScreen> {
  double _sqft = 400;
  String _product = 'quaternary'; // quaternary, hydrogen_peroxide, chlorine, botanical
  String _application = 'spray'; // spray, fog, wipe
  String _surface = 'porous'; // porous, semi_porous, non_porous
  int _coats = 1;
  bool _isBiohazard = false;

  /// Coverage rate in sqft per gallon (mixed solution)
  /// Varies by application method and surface porosity
  double get _coverageRate {
    final baseRate = switch (_application) {
      'spray' => 200.0,  // pump sprayer: ~200 sqft/gal
      'fog' => 400.0,    // ULV fogger: ~400 sqft/gal
      'wipe' => 100.0,   // hand wipe: ~100 sqft/gal
      _ => 200.0,
    };
    final surfaceMultiplier = switch (_surface) {
      'porous' => 0.7,       // absorbs more
      'semi_porous' => 0.85,
      'non_porous' => 1.0,
      _ => 0.85,
    };
    return baseRate * surfaceMultiplier;
  }

  /// Dilution ratio (oz concentrate per gallon water)
  ({double ozPerGal, String ratio}) get _dilution {
    return switch (_product) {
      'quaternary' => (ozPerGal: 2.0, ratio: '2 oz/gal (1:64)'),
      'hydrogen_peroxide' => (ozPerGal: 16.0, ratio: '16 oz/gal (1:8)'),
      'chlorine' => (ozPerGal: 10.0, ratio: '10 oz/gal (1:13)'),
      'botanical' => (ozPerGal: 8.0, ratio: '8 oz/gal (1:16)'),
      _ => (ozPerGal: 2.0, ratio: '2 oz/gal (1:64)'),
    };
  }

  /// Dwell time in minutes
  int get _dwellTime {
    int base = switch (_product) {
      'quaternary' => 10,
      'hydrogen_peroxide' => 15,
      'chlorine' => 10,
      'botanical' => 10,
      _ => 10,
    };
    if (_isBiohazard) base = math.max(base, 20); // longer for biohazard
    return base;
  }

  /// Total mixed solution needed (gallons)
  double get _totalGallons => (_sqft * _coats) / _coverageRate;

  /// Concentrate needed (oz)
  double get _concentrateOz => _totalGallons * _dilution.ozPerGal;

  /// Concentrate bottles (32 oz standard size)
  int get _concentrateBottles => math.max(1, (_concentrateOz / 32).ceil());

  /// Application time estimate (minutes)
  int get _applicationMinutes {
    final base = (_sqft / 200 * 15).round(); // ~15 min per 200 sqft
    return base * _coats + _dwellTime; // apply + dwell
  }

  /// PPE requirements based on product
  String get _ppeRequired {
    return switch (_product) {
      'quaternary' => 'Nitrile gloves, safety glasses, N95 respirator',
      'hydrogen_peroxide' => 'Nitrile gloves, splash goggles, N95 respirator, Tyvek suit',
      'chlorine' => 'Nitrile gloves, splash goggles, half-face respirator w/ OV cartridge, Tyvek suit',
      'botanical' => 'Nitrile gloves, safety glasses',
      _ => 'Nitrile gloves, safety glasses, N95',
    };
  }

  void _reset() => setState(() {
    _sqft = 400; _product = 'quaternary'; _application = 'spray';
    _surface = 'porous'; _coats = 1; _isBiohazard = false;
  });

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Antimicrobial Dosing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel(colors, 'Treatment Area'),
            _slider(colors, 'Area', _sqft, 50, 5000, 'sqft', (v) => setState(() => _sqft = v)),
            const SizedBox(height: 16),
            _sectionLabel(colors, 'Product Type'),
            _productSelector(colors),
            const SizedBox(height: 16),
            _sectionLabel(colors, 'Application Method'),
            _methodSelector(colors),
            const SizedBox(height: 16),
            _sectionLabel(colors, 'Surface Type'),
            _surfaceSelector(colors),
            const SizedBox(height: 12),
            _slider(colors, 'Coats', _coats.toDouble(), 1, 3, '', (v) => setState(() => _coats = v.round())),
            _check(colors, 'Biohazard (Category 3 / sewage)', _isBiohazard, (v) => setState(() => _isBiohazard = v)),
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
      SizedBox(width: 50, child: Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13))),
      Expanded(child: Slider(value: val, min: min, max: max, divisions: ((max - min) / (max > 100 ? 10 : 1)).round(), onChanged: cb, activeColor: c.accentPrimary)),
      SizedBox(width: 65, child: Text('${val.toStringAsFixed(val == val.roundToDouble() ? 0 : 1)}${unit.isNotEmpty ? ' $unit' : ''}', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
    ]));
  }

  Widget _productSelector(ZaftoColors c) {
    final products = {'quaternary': 'Quaternary Ammonium', 'hydrogen_peroxide': 'Hydrogen Peroxide', 'chlorine': 'Sodium Hypochlorite', 'botanical': 'Botanical / Thymol'};
    return Wrap(spacing: 8, runSpacing: 8, children: products.entries.map((e) {
      final sel = _product == e.key;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _product = e.key); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: sel ? c.accentPrimary : c.fillDefault, borderRadius: BorderRadius.circular(8)),
          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? (c.isDark ? Colors.black : Colors.white) : c.textSecondary)),
        ),
      );
    }).toList());
  }

  Widget _methodSelector(ZaftoColors c) {
    final methods = {'spray': 'Pump Sprayer', 'fog': 'ULV Fogger', 'wipe': 'Hand Wipe'};
    return Row(children: methods.entries.map((e) {
      final sel = _application == e.key;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _application = e.key); },
        child: Container(
          margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? c.accentPrimary : c.fillDefault, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? (c.isDark ? Colors.black : Colors.white) : c.textSecondary))),
        ),
      ));
    }).toList());
  }

  Widget _surfaceSelector(ZaftoColors c) {
    final surfaces = {'porous': 'Porous', 'semi_porous': 'Semi-Porous', 'non_porous': 'Non-Porous'};
    return Row(children: surfaces.entries.map((e) {
      final sel = _surface == e.key;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _surface = e.key); },
        child: Container(
          margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? c.accentPrimary : c.fillDefault, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? (c.isDark ? Colors.black : Colors.white) : c.textSecondary))),
        ),
      ));
    }).toList());
  }

  Widget _check(ZaftoColors c, String label, bool val, ValueChanged<bool> cb) {
    return Row(children: [
      Checkbox(value: val, onChanged: (v) => cb(v ?? false), activeColor: c.accentPrimary, side: BorderSide(color: c.borderSubtle)),
      Expanded(child: Text(label, style: TextStyle(color: c.textPrimary, fontSize: 13))),
    ]);
  }

  Widget _resultCard(ZaftoColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DOSING RESULTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accentPrimary, letterSpacing: 1)),
        const SizedBox(height: 12),
        _row(c, 'Mixed Solution', '${_totalGallons.toStringAsFixed(1)} gal'),
        _row(c, 'Concentrate', '${_concentrateOz.toStringAsFixed(1)} oz ($_concentrateBottles bottle${_concentrateBottles > 1 ? "s" : ""})'),
        _row(c, 'Dilution Ratio', _dilution.ratio),
        _row(c, 'Dwell Time', '$_dwellTime min'),
        _row(c, 'Coverage Rate', '${_coverageRate.toStringAsFixed(0)} sqft/gal'),
        _row(c, 'Est. Application', '$_applicationMinutes min'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: c.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.shieldAlert, size: 14, color: c.accentWarning),
              const SizedBox(width: 6),
              Text('Required PPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.accentWarning)),
            ]),
            const SizedBox(height: 4),
            Text(_ppeRequired, style: TextStyle(fontSize: 11, color: c.textSecondary, height: 1.4)),
          ]),
        ),
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
