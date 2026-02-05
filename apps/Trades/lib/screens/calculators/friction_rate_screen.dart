import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Friction Rate Calculator - Design System v2.6
/// Available static pressure per 100 feet of duct
class FrictionRateScreen extends ConsumerStatefulWidget {
  const FrictionRateScreen({super.key});
  @override
  ConsumerState<FrictionRateScreen> createState() => _FrictionRateScreenState();
}

class _FrictionRateScreenState extends ConsumerState<FrictionRateScreen> {
  double _totalEsp = 0.5;
  double _filterDrop = 0.10;
  double _coilDrop = 0.20;
  double _registerDrop = 0.03;
  double _totalEquivLength = 200;
  int _fittingCount = 8;

  double? _availableForDuct;
  double? _frictionRate;
  double? _fittingLoss;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Component losses
    final componentLoss = _filterDrop + _coilDrop + _registerDrop;

    // Available for ductwork
    final availableForDuct = _totalEsp - componentLoss;

    // Fitting equivalent length (avg 15 ft per fitting)
    final fittingEquivLength = _fittingCount * 15.0;
    final totalLength = _totalEquivLength + fittingEquivLength;

    // Friction rate = Available / (Total Length / 100)
    final frictionRate = availableForDuct / (totalLength / 100);

    String recommendation;
    if (frictionRate < 0.05) {
      recommendation = 'Very low friction rate. May need larger equipment ESP or shorter duct runs. Check for restrictions.';
    } else if (frictionRate < 0.08) {
      recommendation = 'Low friction rate. Use larger duct sizes to stay within budget. Prioritize main trunk sizing.';
    } else if (frictionRate <= 0.10) {
      recommendation = 'Ideal friction rate for residential. Standard duct sizing charts will work well.';
    } else if (frictionRate <= 0.12) {
      recommendation = 'Acceptable for most systems. Watch velocity in smaller branches.';
    } else {
      recommendation = 'High friction rate. May cause noise issues. Consider equipment with higher ESP.';
    }

    if (availableForDuct < 0.1) {
      recommendation = 'WARNING: Very little static available for ductwork. Reduce component losses or increase equipment ESP.';
    }

    setState(() {
      _availableForDuct = availableForDuct;
      _frictionRate = frictionRate;
      _fittingLoss = fittingEquivLength;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _totalEsp = 0.5;
      _filterDrop = 0.10;
      _coilDrop = 0.20;
      _registerDrop = 0.03;
      _totalEquivLength = 200;
      _fittingCount = 8;
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
        title: Text('Friction Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EQUIPMENT'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total External Static', value: _totalEsp, min: 0.2, max: 1.0, unit: '" w.c.', decimals: 2, onChanged: (v) { setState(() => _totalEsp = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COMPONENT LOSSES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Filter Drop', value: _filterDrop, min: 0.05, max: 0.30, unit: '" w.c.', decimals: 2, onChanged: (v) { setState(() => _filterDrop = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Coil Drop', value: _coilDrop, min: 0.10, max: 0.40, unit: '" w.c.', decimals: 2, onChanged: (v) { setState(() => _coilDrop = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Register/Grille Drop', value: _registerDrop, min: 0.02, max: 0.10, unit: '" w.c.', decimals: 2, onChanged: (v) { setState(() => _registerDrop = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total Duct Length', value: _totalEquivLength, min: 50, max: 500, unit: ' ft', onChanged: (v) { setState(() => _totalEquivLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Fittings Count', value: _fittingCount.toDouble(), min: 2, max: 20, unit: '', isInt: true, onChanged: (v) { setState(() => _fittingCount = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FRICTION RATE'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildStaticBudget(colors),
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
        Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Friction rate determines duct sizing. Target 0.08-0.10" per 100 ft for residential. Lower = larger ducts needed.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_frictionRate == null) return const SizedBox.shrink();

    Color rateColor;
    if (_frictionRate! < 0.05 || _frictionRate! > 0.15) {
      rateColor = Colors.red;
    } else if (_frictionRate! < 0.08 || _frictionRate! > 0.12) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_frictionRate!.toStringAsFixed(3), style: TextStyle(color: rateColor, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('" w.c. per 100 ft', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Available', '${_availableForDuct?.toStringAsFixed(2)}" w.c.')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Fitting EL', '${_fittingLoss?.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total EL', '${(_totalEquivLength + _fittingLoss!).toStringAsFixed(0)} ft')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_frictionRate! < 0.05 ? LucideIcons.alertTriangle : LucideIcons.info, color: _frictionRate! < 0.05 ? Colors.orange : colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticBudget(ZaftoColors colors) {
    final componentTotal = _filterDrop + _coilDrop + _registerDrop;
    final ductLoss = _totalEsp - componentTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATIC PRESSURE BUDGET', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildBudgetRow(colors, 'Total ESP', _totalEsp, 1.0),
          _buildBudgetRow(colors, 'Filter', _filterDrop, _filterDrop / _totalEsp),
          _buildBudgetRow(colors, 'Coil', _coilDrop, _coilDrop / _totalEsp),
          _buildBudgetRow(colors, 'Registers', _registerDrop, _registerDrop / _totalEsp),
          const Divider(height: 16),
          _buildBudgetRow(colors, 'For Ductwork', ductLoss, ductLoss / _totalEsp, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(ZaftoColors colors, String label, double value, double fraction, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(color: isHighlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal))),
        Expanded(
          flex: 3,
          child: Stack(children: [
            Container(height: 8, decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(widthFactor: fraction.clamp(0, 1), child: Container(height: 8, decoration: BoxDecoration(color: isHighlight ? colors.accentPrimary : colors.textSecondary.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)))),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 60, child: Text('${value.toStringAsFixed(2)}"', textAlign: TextAlign.end, style: TextStyle(color: isHighlight ? colors.accentPrimary : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
