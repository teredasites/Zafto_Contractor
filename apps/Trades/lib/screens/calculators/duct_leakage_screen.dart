import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Duct Leakage Test Calculator - Design System v2.6
/// Duct leakage testing and IECC compliance
class DuctLeakageScreen extends ConsumerStatefulWidget {
  const DuctLeakageScreen({super.key});
  @override
  ConsumerState<DuctLeakageScreen> createState() => _DuctLeakageScreenState();
}

class _DuctLeakageScreenState extends ConsumerState<DuctLeakageScreen> {
  double _systemCfm = 1200;
  double _ductSurfaceArea = 400; // sq ft
  double _testPressure = 25; // Pa
  double _measuredLeakage = 60; // CFM
  String _testType = 'total';
  String _ductLocation = 'conditioned';
  String _codeStandard = 'iecc';

  double? _leakageClass;
  double? _cfm25;
  double? _percentLeakage;
  bool? _passesCode;
  String? _codeLimit;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Leakage class = CFM25 / 100 sq ft duct surface
    final cfm25 = _measuredLeakage;
    final leakageClass = (cfm25 / _ductSurfaceArea) * 100;

    // Percent of system flow
    final percentLeakage = (_measuredLeakage / _systemCfm) * 100;

    // Code limits
    double limitPercent;
    String codeLimit;

    if (_codeStandard == 'iecc') {
      if (_ductLocation == 'conditioned') {
        limitPercent = 4.0; // 4% for ducts in conditioned space
        codeLimit = 'IECC: 4% in conditioned space';
      } else {
        limitPercent = 4.0; // 4 CFM25/100 sq ft or 4%
        codeLimit = 'IECC: 4 CFM25/100 sq ft or 4% total';
      }
    } else if (_codeStandard == 'energy_star') {
      if (_testType == 'total') {
        limitPercent = 4.0;
        codeLimit = 'ENERGY STAR: ≤4% total leakage';
      } else {
        limitPercent = 4.0;
        codeLimit = 'ENERGY STAR: ≤4% to outside';
      }
    } else {
      limitPercent = 6.0;
      codeLimit = 'Standard: ≤6% typical';
    }

    final passesCode = percentLeakage <= limitPercent &&
                       (_ductLocation != 'unconditioned' || leakageClass <= 4);

    String recommendation;
    if (passesCode) {
      recommendation = 'PASS: Duct leakage within acceptable limits. Document test results.';
    } else {
      recommendation = 'FAIL: Leakage exceeds limit. Seal joints with mastic and retest.';
    }

    if (leakageClass > 6) {
      recommendation += ' High leakage class (${leakageClass.toStringAsFixed(1)}) - check connections, seams, and boot-to-drywall seals.';
    }

    if (_ductLocation == 'unconditioned') {
      recommendation += ' Unconditioned space: Leakage impacts efficiency significantly. Target <3% for best performance.';
    }

    if (_testType == 'total') {
      recommendation += ' Total leakage test includes leakage to conditioned space. Leakage to outside is more critical.';
    } else {
      recommendation += ' Leakage to outside directly impacts energy use and comfort.';
    }

    setState(() {
      _leakageClass = leakageClass;
      _cfm25 = cfm25;
      _percentLeakage = percentLeakage;
      _passesCode = passesCode;
      _codeLimit = codeLimit;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _systemCfm = 1200;
      _ductSurfaceArea = 400;
      _testPressure = 25;
      _measuredLeakage = 60;
      _testType = 'total';
      _ductLocation = 'conditioned';
      _codeStandard = 'iecc';
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
        title: Text('Duct Leakage Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSliderRow(colors, label: 'System CFM', value: _systemCfm, min: 400, max: 4000, unit: ' CFM', onChanged: (v) { setState(() => _systemCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Duct Surface Area', value: _ductSurfaceArea, min: 100, max: 1500, unit: ' sq ft', onChanged: (v) { setState(() => _ductSurfaceArea = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEST RESULTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Measured Leakage @ 25 Pa', value: _measuredLeakage, min: 0, max: 300, unit: ' CFM', onChanged: (v) { setState(() => _measuredLeakage = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEST PARAMETERS'),
              const SizedBox(height: 12),
              _buildTestTypeSelector(colors),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 12),
              _buildCodeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TEST RESULTS'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Duct leakage: Test at 25 Pa. IECC requires ≤4 CFM25/100 sq ft or ≤4% of system flow.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildTestTypeSelector(ZaftoColors colors) {
    final types = [('total', 'Total Leakage'), ('outside', 'Leakage to Outside')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _testType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _testType = t.$1); _calculate(); },
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
        ),
      ],
    );
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = [('conditioned', 'Conditioned'), ('unconditioned', 'Unconditioned')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duct Location', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: locations.map((l) {
            final selected = _ductLocation == l.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _ductLocation = l.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: l != locations.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCodeSelector(ZaftoColors colors) {
    final codes = [('iecc', 'IECC'), ('energy_star', 'ENERGY STAR'), ('standard', 'Standard')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Code Standard', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: codes.map((c) {
            final selected = _codeStandard == c.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _codeStandard = c.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: c != codes.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_percentLeakage == null) return const SizedBox.shrink();

    final passed = _passesCode ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: passed ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(passed ? 'PASS' : 'FAIL', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 16),
          Text('${_percentLeakage?.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('of System Airflow', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(_codeLimit ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'CFM25', '${_cfm25?.toStringAsFixed(0)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Leakage Class', '${_leakageClass?.toStringAsFixed(1)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Duct Area', '${_ductSurfaceArea.toStringAsFixed(0)} sf')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(passed ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: passed ? Colors.green : Colors.red, size: 16),
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
