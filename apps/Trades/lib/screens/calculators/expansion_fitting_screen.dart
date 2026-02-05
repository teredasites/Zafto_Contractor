import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Expansion Fitting Calculator - Design System v2.6
/// Thermal expansion in PVC conduit per NEC 352.44
class ExpansionFittingScreen extends ConsumerStatefulWidget {
  const ExpansionFittingScreen({super.key});
  @override
  ConsumerState<ExpansionFittingScreen> createState() => _ExpansionFittingScreenState();
}

class _ExpansionFittingScreenState extends ConsumerState<ExpansionFittingScreen> {
  double _runLength = 100;
  double _tempChangeFahrenheit = 60;
  String _conduitType = 'PVC';

  // Coefficient of expansion (inches per 100 ft per 10°F)
  static const Map<String, double> _expansionCoefficient = {
    'PVC': 0.408,      // Schedule 40/80 PVC
    'HDPE': 0.72,      // High-density polyethylene
    'ENT': 0.408,      // Electrical nonmetallic tubing
    'LFNC': 0.35,      // Liquidtight flexible nonmetallic
    'EMT': 0.078,      // Electrical metallic tubing (steel)
    'RMC': 0.078,      // Rigid metal conduit (steel)
    'IMC': 0.078,      // Intermediate metal conduit
    'Aluminum': 0.144, // Aluminum conduit
  };

  static const Map<String, String> _conduitNames = {
    'PVC': 'PVC Schedule 40/80',
    'HDPE': 'HDPE Conduit',
    'ENT': 'Electrical Nonmetallic Tubing',
    'LFNC': 'Liquidtight Flex Nonmetallic',
    'EMT': 'Electrical Metallic Tubing',
    'RMC': 'Rigid Metal Conduit',
    'IMC': 'Intermediate Metal Conduit',
    'Aluminum': 'Aluminum Rigid Conduit',
  };

  double get _coefficient => _expansionCoefficient[_conduitType] ?? 0.408;

  // Total expansion = (length/100) × (temp change/10) × coefficient
  double get _totalExpansion => (_runLength / 100) * (_tempChangeFahrenheit / 10) * _coefficient;

  bool get _requiresExpansionFitting => _totalExpansion > 0.25; // Most fittings needed if > 1/4"

  String get _fittingSize {
    if (_totalExpansion <= 0.5) return '1/2" fitting';
    if (_totalExpansion <= 1.0) return '1" fitting';
    if (_totalExpansion <= 2.0) return '2" fitting';
    if (_totalExpansion <= 4.0) return '4" fitting';
    return '6" fitting or split run';
  }

  int get _recommendedFittings {
    if (_totalExpansion <= 0.25) return 0;
    // Recommend fitting every 4" of potential movement
    return ((_totalExpansion / 4) + 1).ceil();
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
        title: Text('Expansion Fitting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConduitTypeCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          const SizedBox(height: 16),
          _buildTempChangeCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildExpansionTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildConduitTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONDUIT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _expansionCoefficient.keys.map((type) {
          final isSelected = _conduitType == type;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _conduitType = type); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(type, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text(_conduitNames[_conduitType] ?? '', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildRunLengthCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RUN LENGTH (feet)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [50.0, 100.0, 150.0, 200.0, 300.0].map((length) {
          final isSelected = _runLength == length;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _runLength = length); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${length.toInt()}', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_runLength.toInt()} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _runLength, min: 10, max: 500, divisions: 49, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _runLength = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildTempChangeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TEMPERATURE CHANGE (°F)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('Expected swing from coldest to hottest', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [40.0, 60.0, 80.0, 100.0, 120.0].map((temp) {
          final isSelected = _tempChangeFahrenheit == temp;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _tempChangeFahrenheit = temp); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${temp.toInt()}°', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_tempChangeFahrenheit.toInt()}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _tempChangeFahrenheit, min: 20, max: 150, divisions: 13, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _tempChangeFahrenheit = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requiresExpansionFitting ? colors.accentWarning.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(_totalExpansion.toStringAsFixed(2), style: TextStyle(color: _requiresExpansionFitting ? colors.accentWarning : colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('inches Total Expansion', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _requiresExpansionFitting ? colors.accentWarning.withValues(alpha: 0.2) : colors.accentSuccess.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
          child: Text(_requiresExpansionFitting ? 'FITTING REQUIRED' : 'NO FITTING NEEDED', style: TextStyle(color: _requiresExpansionFitting ? colors.accentWarning : colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Conduit Type', _conduitType),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Run Length', '${_runLength.toInt()} ft'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Temp Change', '${_tempChangeFahrenheit.toInt()}°F'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Coefficient', '${_coefficient.toStringAsFixed(3)} in/100ft/10°F'),
            Divider(color: colors.borderSubtle, height: 20),
            if (_requiresExpansionFitting) ...[
              _buildResultRow(colors, 'Fitting Size', _fittingSize, highlight: true),
              const SizedBox(height: 10),
              _buildResultRow(colors, 'Qty Recommended', '$_recommendedFittings'),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildExpansionTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EXPANSION COEFFICIENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text('Inches per 100 ft per 10°F change', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        const SizedBox(height: 12),
        ...['PVC', 'HDPE', 'EMT', 'Aluminum'].map((type) {
          final coeff = _expansionCoefficient[type] ?? 0;
          final isHighlighted = _conduitType == type;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
              borderRadius: BorderRadius.circular(6),
              border: isHighlighted ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(type, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              Text(coeff.toStringAsFixed(3), style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textTertiary, fontSize: 12)),
            ]),
          );
        }),
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 352.44', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Required for PVC runs with temp swings\n• Install at midpoint of long runs\n• Follow manufacturer specifications\n• Metal conduit rarely needs fittings', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
