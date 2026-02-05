import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Transformer Protection Calculator - Design System v2.6
/// Primary and secondary OCPD sizing per NEC 450.3
class TransformerProtectionScreen extends ConsumerStatefulWidget {
  const TransformerProtectionScreen({super.key});
  @override
  ConsumerState<TransformerProtectionScreen> createState() => _TransformerProtectionScreenState();
}

class _TransformerProtectionScreenState extends ConsumerState<TransformerProtectionScreen> {
  double _kva = 45;
  int _primaryVoltage = 480;
  int _secondaryVoltage = 208;
  int _phases = 3;
  String _impedanceRange = '<=6%';
  bool _primaryProtectionOnly = false;

  // Standard transformer kVA sizes
  static const List<double> _standardKva = [
    3, 5, 7.5, 10, 15, 25, 30, 37.5, 45, 50, 75, 100, 112.5, 150,
    167, 200, 225, 250, 300, 333, 500, 750, 1000
  ];

  // NEC Table 450.3(B) - Transformers 1000V nominal or less
  // Maximum rating of OCPD (% of transformer rated current)
  static const Map<String, Map<String, int>> _protectionPercent = {
    '<=6%': {'primary': 125, 'secondary': 125},
    '>6-10%': {'primary': 125, 'secondary': 125},
    '>10%': {'primary': 125, 'secondary': 167},
  };

  // If no secondary protection, primary max increases
  static const Map<String, int> _primaryOnlyPercent = {
    '<=6%': 125,
    '>6-10%': 167,
    '>10%': 300,
  };

  double get _primaryFla {
    if (_phases == 1) {
      return (_kva * 1000) / _primaryVoltage;
    } else {
      return (_kva * 1000) / (_primaryVoltage * 1.732);
    }
  }

  double get _secondaryFla {
    if (_phases == 1) {
      return (_kva * 1000) / _secondaryVoltage;
    } else {
      return (_kva * 1000) / (_secondaryVoltage * 1.732);
    }
  }

  int get _primaryProtectionPercent {
    if (_primaryProtectionOnly) {
      return _primaryOnlyPercent[_impedanceRange] ?? 125;
    }
    return _protectionPercent[_impedanceRange]?['primary'] ?? 125;
  }

  int get _secondaryProtectionPercent {
    return _protectionPercent[_impedanceRange]?['secondary'] ?? 125;
  }

  double get _maxPrimaryOcpd => _primaryFla * _primaryProtectionPercent / 100;
  double get _maxSecondaryOcpd => _secondaryFla * _secondaryProtectionPercent / 100;

  // Standard breaker sizes
  int _getStandardBreaker(double amps) {
    const sizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100,
                   110, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450,
                   500, 600, 700, 800, 1000, 1200, 1600, 2000, 2500, 3000];
    for (final size in sizes) {
      if (size >= amps) return size;
    }
    return sizes.last;
  }

  int get _recommendedPrimaryBreaker {
    // Per NEC 450.3(B): May round up to next standard size
    return _getStandardBreaker(_maxPrimaryOcpd);
  }

  int get _recommendedSecondaryBreaker {
    return _getStandardBreaker(_maxSecondaryOcpd);
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
        title: Text('Transformer Protection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTransformerDataCard(colors),
          const SizedBox(height: 16),
          _buildVoltageCard(colors),
          const SizedBox(height: 16),
          _buildImpedanceCard(colors),
          const SizedBox(height: 16),
          _buildProtectionTypeCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildTransformerDataCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRANSFORMER SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [15.0, 25.0, 30.0, 45.0, 75.0, 112.5, 150.0, 225.0].map((kva) {
          final isSelected = _kva == kva;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _kva = kva); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${kva.toStringAsFixed(kva == kva.toInt() ? 0 : 1)}', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_kva.toStringAsFixed(1)} kVA', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _kva, min: 3, max: 500, divisions: 497, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _kva = v); }),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _phases = 1); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _phases == 1 ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('1-Phase', style: TextStyle(color: _phases == 1 ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500))),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _phases = 3); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _phases == 3 ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('3-Phase', style: TextStyle(color: _phases == 3 ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500))),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _buildVoltageCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VOLTAGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text('Primary', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [240, 277, 480, 600].map((v) {
          final isSelected = _primaryVoltage == v;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _primaryVoltage = v); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        Text('Secondary', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [120, 208, 240, 277, 480].map((v) {
          final isSelected = _secondaryVoltage == v;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _secondaryVoltage = v); },
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

  Widget _buildImpedanceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRANSFORMER IMPEDANCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...['<=6%', '>6-10%', '>10%'].map((range) {
          final isSelected = _impedanceRange == range;
          String description;
          switch (range) {
            case '<=6%': description = 'Most common (3-6%)'; break;
            case '>6-10%': description = 'Medium impedance'; break;
            case '>10%': description = 'High impedance'; break;
            default: description = '';
          }
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _impedanceRange = range); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(children: [
                Text(range, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(child: Text(description, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildProtectionTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('PRIMARY PROTECTION ONLY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1))),
          Switch(value: _primaryProtectionOnly, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _primaryProtectionOnly = v); }, activeColor: colors.accentPrimary),
        ]),
        const SizedBox(height: 4),
        Text(_primaryProtectionOnly
            ? 'No secondary OCPD - primary limits increased per 450.3(B)'
            : 'Both primary and secondary protection',
            style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            Text('$_recommendedPrimaryBreaker', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
            Text('A Primary', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
          if (!_primaryProtectionOnly) ...[
            Container(width: 1, height: 50, color: colors.borderSubtle),
            Column(children: [
              Text('$_recommendedSecondaryBreaker', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
              Text('A Secondary', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ]),
          ],
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Transformer', '${_kva.toStringAsFixed(1)} kVA, $_phases-ph'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Primary FLA', '${_primaryFla.toStringAsFixed(1)}A @ ${_primaryVoltage}V'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Secondary FLA', '${_secondaryFla.toStringAsFixed(1)}A @ ${_secondaryVoltage}V'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Primary Max', '${_maxPrimaryOcpd.toStringAsFixed(1)}A ($_primaryProtectionPercent%)', highlight: true),
            if (!_primaryProtectionOnly) ...[
              const SizedBox(height: 10),
              _buildResultRow(colors, 'Secondary Max', '${_maxSecondaryOcpd.toStringAsFixed(1)}A ($_secondaryProtectionPercent%)'),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC TABLE 450.3(B) SUMMARY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Impedance', 'Primary', 'Secondary', isHeader: true),
        const SizedBox(height: 6),
        _buildTableRow(colors, '≤6%', '125%', '125%', isHighlighted: _impedanceRange == '<=6%'),
        const SizedBox(height: 4),
        _buildTableRow(colors, '>6-10%', '125%*', '125%', isHighlighted: _impedanceRange == '>6-10%'),
        const SizedBox(height: 4),
        _buildTableRow(colors, '>10%', '125%*', '167%', isHighlighted: _impedanceRange == '>10%'),
        const SizedBox(height: 8),
        Text('* Primary only: ≤6%=125%, >6-10%=167%, >10%=300%', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String c1, String c2, String c3, {bool isHeader = false, bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.1) : (isHeader ? colors.bgBase : Colors.transparent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Text(c1, style: TextStyle(color: isHighlighted ? colors.accentPrimary : (isHeader ? colors.textSecondary : colors.textTertiary), fontSize: 11, fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400))),
        Expanded(child: Text(c2, textAlign: TextAlign.center, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textTertiary, fontSize: 11))),
        Expanded(child: Text(c3, textAlign: TextAlign.center, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textTertiary, fontSize: 11))),
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 450.3(B)', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Table 450.3(B) - OCPD sizing\n• May round up to next standard size\n• Secondary prot allows higher primary\n• Consider downstream protection', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
