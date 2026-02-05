import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Junction Box Sizing Calculator - Design System v2.6
/// NEC 314.28 for larger conductors (4 AWG and larger)
class JunctionBoxSizingScreen extends ConsumerStatefulWidget {
  const JunctionBoxSizingScreen({super.key});
  @override
  ConsumerState<JunctionBoxSizingScreen> createState() => _JunctionBoxSizingScreenState();
}

class _JunctionBoxSizingScreenState extends ConsumerState<JunctionBoxSizingScreen> {
  String _largestConduit = '2';
  int _straightPulls = 2;
  int _anglePulls = 1;
  bool _hasUSplices = false;

  // Trade size to inches (internal diameter approximate)
  static const Map<String, double> _conduitDiameter = {
    '1/2': 0.622,
    '3/4': 0.824,
    '1': 1.049,
    '1-1/4': 1.380,
    '1-1/2': 1.610,
    '2': 2.067,
    '2-1/2': 2.469,
    '3': 3.068,
    '3-1/2': 3.548,
    '4': 4.026,
    '5': 5.047,
    '6': 6.065,
  };

  static const List<String> _conduitSizes = [
    '1', '1-1/4', '1-1/2', '2', '2-1/2', '3', '3-1/2', '4', '5', '6'
  ];

  double get _largestDiameter => _conduitDiameter[_largestConduit] ?? 2.067;

  // NEC 314.28(A)(1) - Straight pulls: 8 × largest conduit trade size
  double get _straightPullMin {
    // Parse trade size to number
    double size;
    if (_largestConduit.contains('/')) {
      final parts = _largestConduit.split('-');
      if (parts.length == 2) {
        size = double.parse(parts[0]) + 0.5; // e.g., "1-1/2" = 1.5
      } else {
        size = 0.5; // "1/2"
      }
    } else {
      size = double.parse(_largestConduit);
    }
    return size * 8;
  }

  // NEC 314.28(A)(2) - Angle pulls: 6 × largest + sum of others
  double get _anglePullMin {
    double size;
    if (_largestConduit.contains('/')) {
      final parts = _largestConduit.split('-');
      if (parts.length == 2) {
        size = double.parse(parts[0]) + 0.5;
      } else {
        size = 0.5;
      }
    } else {
      size = double.parse(_largestConduit);
    }
    // Simplified: 6× largest + assume other conduits add same size
    return (size * 6) + (size * (_anglePulls > 1 ? _anglePulls - 1 : 0));
  }

  // Distance between entries on same wall: 6 × trade diameter
  double get _minBetweenEntries {
    double size;
    if (_largestConduit.contains('/')) {
      final parts = _largestConduit.split('-');
      if (parts.length == 2) {
        size = double.parse(parts[0]) + 0.5;
      } else {
        size = 0.5;
      }
    } else {
      size = double.parse(_largestConduit);
    }
    return size * 6;
  }

  double get _recommendedSize => _anglePulls > 0 ? _anglePullMin : _straightPullMin;

  String get _boxSuggestion {
    final min = _recommendedSize;
    if (min <= 8) return '8" × 8" × 4"';
    if (min <= 12) return '12" × 12" × 6"';
    if (min <= 16) return '16" × 16" × 6"';
    if (min <= 24) return '24" × 24" × 8"';
    if (min <= 36) return '36" × 36" × 8"';
    return '48" × 48" × 12" or larger';
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
        title: Text('Junction Box Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConduitSizeCard(colors),
          const SizedBox(height: 16),
          _buildPullTypeCard(colors),
          const SizedBox(height: 16),
          _buildSpliceCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildFormulaCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildConduitSizeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LARGEST CONDUIT (Trade Size)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _conduitSizes.map((size) {
          final isSelected = _largestConduit == size;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _largestConduit = size); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('$size"', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildPullTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PULL CONFIGURATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(children: [
            Text('Straight Pulls', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: _straightPulls > 0 ? () { HapticFeedback.selectionClick(); setState(() => _straightPulls--); } : null, icon: Icon(LucideIcons.minus, color: _straightPulls > 0 ? colors.accentPrimary : colors.textTertiary)),
              Text('$_straightPulls', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              IconButton(onPressed: _straightPulls < 8 ? () { HapticFeedback.selectionClick(); setState(() => _straightPulls++); } : null, icon: Icon(LucideIcons.plus, color: _straightPulls < 8 ? colors.accentPrimary : colors.textTertiary)),
            ]),
          ])),
          Container(width: 1, height: 60, color: colors.borderSubtle),
          Expanded(child: Column(children: [
            Text('Angle Pulls', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: _anglePulls > 0 ? () { HapticFeedback.selectionClick(); setState(() => _anglePulls--); } : null, icon: Icon(LucideIcons.minus, color: _anglePulls > 0 ? colors.accentPrimary : colors.textTertiary)),
              Text('$_anglePulls', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              IconButton(onPressed: _anglePulls < 8 ? () { HapticFeedback.selectionClick(); setState(() => _anglePulls++); } : null, icon: Icon(LucideIcons.plus, color: _anglePulls < 8 ? colors.accentPrimary : colors.textTertiary)),
            ]),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildSpliceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SPLICES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Contains U-splices (no pull)', style: TextStyle(color: colors.textSecondary, fontSize: 14))),
          Switch(
            value: _hasUSplices,
            onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasUSplices = v); },
            activeColor: colors.accentPrimary,
          ),
        ]),
        if (_hasUSplices)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Add 6× trade size to depth calculation', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(_recommendedSize.toStringAsFixed(1), style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('inches Minimum Dimension', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_boxSuggestion, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Largest Conduit', '$_largestConduit"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Straight pull min (8×)', '${_straightPullMin.toStringAsFixed(1)}"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Angle pull min (6×+)', '${_anglePullMin.toStringAsFixed(1)}"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Min between entries', '${_minBetweenEntries.toStringAsFixed(1)}"'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Required Dimension', '${_recommendedSize.toStringAsFixed(1)}"', highlight: true),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC 314.28 FORMULAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildFormulaRow(colors, 'Straight Pull:', '8 × largest trade size'),
        const SizedBox(height: 8),
        _buildFormulaRow(colors, 'Angle Pull:', '6 × largest + sum of others'),
        const SizedBox(height: 8),
        _buildFormulaRow(colors, 'Between Entries:', '6 × trade diameter'),
        const SizedBox(height: 8),
        _buildFormulaRow(colors, 'U-Splices:', 'Add 6 × trade to depth'),
      ]),
    );
  }

  Widget _buildFormulaRow(ZaftoColors colors, String label, String formula) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))),
      Expanded(child: Text(formula, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
    ]);
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 314.28', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Applies to 4 AWG and larger conductors\n• (A)(1) Straight pulls: 8× largest conduit\n• (A)(2) Angle/U pulls: 6× + sum of others\n• (A)(3) Opposite wall entries: 6× trade size', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
