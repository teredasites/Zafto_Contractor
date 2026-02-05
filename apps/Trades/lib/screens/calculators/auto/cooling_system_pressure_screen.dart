import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cooling System Pressure Cap Selection Calculator
class CoolingSystemPressureScreen extends ConsumerStatefulWidget {
  const CoolingSystemPressureScreen({super.key});
  @override
  ConsumerState<CoolingSystemPressureScreen> createState() => _CoolingSystemPressureScreenState();
}

class _CoolingSystemPressureScreenState extends ConsumerState<CoolingSystemPressureScreen> {
  final _boilPointController = TextEditingController(text: '265');
  final _maxTempController = TextEditingController(text: '230');
  final _altitudeController = TextEditingController(text: '0');

  double? _recommendedPressure;
  double? _effectiveBoilPoint;
  double? _safetyMargin;
  String? _capRecommendation;

  void _calculate() {
    final targetBoilPoint = double.tryParse(_boilPointController.text);
    final maxTemp = double.tryParse(_maxTempController.text);
    final altitude = double.tryParse(_altitudeController.text) ?? 0;

    if (targetBoilPoint == null || maxTemp == null) {
      setState(() { _recommendedPressure = null; });
      return;
    }

    // Boiling point of 50/50 coolant at sea level = 223°F at 0 PSI
    // Each PSI of pressure raises boiling point ~3°F
    final baseBoilPoint = 223.0;

    // Altitude adjustment: lose ~1°F boiling point per 500ft
    final altitudeAdjustment = altitude / 500;
    final adjustedBaseBoilPoint = baseBoilPoint - altitudeAdjustment;

    // Required pressure to achieve target boil point
    final requiredPressure = (targetBoilPoint - adjustedBaseBoilPoint) / 3;

    // Standard cap sizes: 7, 10, 13, 15, 16, 18, 20 PSI
    final standardCaps = [7.0, 10.0, 13.0, 15.0, 16.0, 18.0, 20.0];
    double recommendedCap = 15; // Default

    for (final cap in standardCaps) {
      if (cap >= requiredPressure) {
        recommendedCap = cap;
        break;
      }
    }
    if (requiredPressure > 20) recommendedCap = 20;

    // Calculate actual boiling point with recommended cap
    final effectiveBoil = adjustedBaseBoilPoint + (recommendedCap * 3);
    final margin = effectiveBoil - maxTemp;

    // Cap recommendation
    String capRec;
    if (recommendedCap <= 10) {
      capRec = 'Low pressure cap - Use for older vehicles or weak cooling systems';
    } else if (recommendedCap <= 15) {
      capRec = 'Standard pressure cap - Suitable for most vehicles';
    } else if (recommendedCap <= 18) {
      capRec = 'High pressure cap - For performance/heavy-duty applications';
    } else {
      capRec = 'Maximum pressure cap - Race/extreme duty only, check hose ratings';
    }

    if (altitude > 5000) {
      capRec += '. High altitude: Consider upgrading one pressure level';
    }

    setState(() {
      _recommendedPressure = recommendedCap;
      _effectiveBoilPoint = effectiveBoil;
      _safetyMargin = margin;
      _capRecommendation = capRec;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boilPointController.text = '265';
    _maxTempController.text = '230';
    _altitudeController.text = '0';
    setState(() { _recommendedPressure = null; });
  }

  @override
  void dispose() {
    _boilPointController.dispose();
    _maxTempController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pressure Cap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Boil Point', unit: 'F', hint: 'Desired boiling point', controller: _boilPointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Operating Temp', unit: 'F', hint: 'Highest expected temp', controller: _maxTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Altitude', unit: 'ft', hint: 'Elevation above sea level', controller: _altitudeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedPressure != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Boil Point = 223°F + (PSI x 3)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Each PSI raises boiling point ~3°F for 50/50 mix', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isMarginSafe = (_safetyMargin ?? 0) >= 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended Cap', '${_recommendedPressure!.toStringAsFixed(0)} PSI', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Effective Boil Point', '${_effectiveBoilPoint!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Safety Margin', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Row(children: [
            Icon(isMarginSafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isMarginSafe ? colors.accentSuccess : colors.warning, size: 16),
            const SizedBox(width: 6),
            Text('${_safetyMargin!.toStringAsFixed(0)}°F', style: TextStyle(color: isMarginSafe ? colors.accentSuccess : colors.warning, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_capRecommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 12),
        _buildPressureChart(colors),
      ]),
    );
  }

  Widget _buildPressureChart(ZaftoColors colors) {
    final caps = [
      {'psi': 7, 'boil': 244},
      {'psi': 13, 'boil': 262},
      {'psi': 15, 'boil': 268},
      {'psi': 16, 'boil': 271},
      {'psi': 18, 'boil': 277},
      {'psi': 20, 'boil': 283},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Common Cap Ratings (50/50 mix)', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...caps.map((c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${c['psi']} PSI', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('${c['boil']}°F boil point', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
