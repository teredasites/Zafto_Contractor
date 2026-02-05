import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conduit Support Spacing Calculator - Design System v2.6
/// NEC support and securement requirements for raceways
class ConduitSupportSpacingScreen extends ConsumerStatefulWidget {
  const ConduitSupportSpacingScreen({super.key});
  @override
  ConsumerState<ConduitSupportSpacingScreen> createState() => _ConduitSupportSpacingScreenState();
}

class _ConduitSupportSpacingScreenState extends ConsumerState<ConduitSupportSpacingScreen> {
  String _conduitType = 'EMT';
  String _tradeSize = '1';
  bool _isVertical = false;

  // NEC support spacing requirements (feet)
  static const Map<String, Map<String, List<double>>> _supportSpacing = {
    // {conduitType: {tradeSize: [horizontal_spacing, from_box]}}
    'EMT': {
      '1/2': [10, 3], '3/4': [10, 3], '1': [10, 3], '1-1/4': [10, 3],
      '1-1/2': [10, 3], '2': [10, 3], '2-1/2': [10, 3], '3': [10, 3],
      '3-1/2': [10, 3], '4': [10, 3],
    },
    'IMC': {
      '1/2': [10, 3], '3/4': [10, 3], '1': [10, 3], '1-1/4': [10, 3],
      '1-1/2': [10, 3], '2': [10, 3], '2-1/2': [10, 3], '3': [10, 3],
      '3-1/2': [10, 3], '4': [10, 3],
    },
    'RMC': {
      '1/2': [10, 3], '3/4': [12, 3], '1': [12, 3], '1-1/4': [14, 3],
      '1-1/2': [14, 3], '2': [16, 3], '2-1/2': [16, 3], '3': [20, 3],
      '3-1/2': [20, 3], '4': [20, 3], '5': [20, 3], '6': [20, 3],
    },
    'PVC': {
      '1/2': [3, 3], '3/4': [3, 3], '1': [3, 3], '1-1/4': [4, 3],
      '1-1/2': [4, 3], '2': [5, 3], '2-1/2': [5, 3], '3': [5, 3],
      '3-1/2': [5, 3], '4': [5, 3], '5': [6, 3], '6': [6, 3],
    },
    'LFMC': {
      '1/2': [4.5, 1], '3/4': [4.5, 1], '1': [4.5, 1], '1-1/4': [4.5, 1],
      '1-1/2': [4.5, 1], '2': [4.5, 1], '2-1/2': [4.5, 1], '3': [4.5, 1],
      '3-1/2': [4.5, 1], '4': [4.5, 1],
    },
    'LFNC': {
      '1/2': [3, 1], '3/4': [3, 1], '1': [3, 1], '1-1/4': [3, 1],
      '1-1/2': [3, 1], '2': [3, 1],
    },
    'ENT': {
      '1/2': [3, 3], '3/4': [3, 3], '1': [3, 3], '1-1/4': [4, 3],
      '1-1/2': [4, 3], '2': [5, 3],
    },
    'FMC': {
      '1/2': [4.5, 1], '3/4': [4.5, 1], '1': [4.5, 1], '1-1/4': [4.5, 1],
      '1-1/2': [4.5, 1], '2': [4.5, 1], '2-1/2': [4.5, 1], '3': [4.5, 1],
      '3-1/2': [4.5, 1], '4': [4.5, 1],
    },
  };

  // NEC vertical support requirements (feet between supports)
  static const Map<String, Map<String, double>> _verticalSupport = {
    'EMT': {'1/2': 10, '3/4': 10, '1': 10, '1-1/4': 10, '1-1/2': 12, '2': 12, '2-1/2': 12, '3': 14, '3-1/2': 14, '4': 14},
    'IMC': {'1/2': 10, '3/4': 12, '1': 12, '1-1/4': 14, '1-1/2': 14, '2': 16, '2-1/2': 16, '3': 20, '3-1/2': 20, '4': 20},
    'RMC': {'1/2': 12, '3/4': 12, '1': 12, '1-1/4': 14, '1-1/2': 14, '2': 16, '2-1/2': 16, '3': 20, '3-1/2': 20, '4': 20, '5': 20, '6': 25},
    'PVC': {'1/2': 4, '3/4': 4, '1': 4, '1-1/4': 4, '1-1/2': 4, '2': 4, '2-1/2': 4, '3': 4, '3-1/2': 4, '4': 4, '5': 4, '6': 4},
    'LFMC': {'1/2': 6, '3/4': 6, '1': 6, '1-1/4': 6, '1-1/2': 6, '2': 6, '2-1/2': 6, '3': 6, '3-1/2': 6, '4': 6},
    'LFNC': {'1/2': 4, '3/4': 4, '1': 4, '1-1/4': 4, '1-1/2': 4, '2': 4},
    'ENT': {'1/2': 4, '3/4': 4, '1': 4, '1-1/4': 4, '1-1/2': 4, '2': 4},
    'FMC': {'1/2': 6, '3/4': 6, '1': 6, '1-1/4': 6, '1-1/2': 6, '2': 6, '2-1/2': 6, '3': 6, '3-1/2': 6, '4': 6},
  };

  static const List<String> _conduitTypes = ['EMT', 'IMC', 'RMC', 'PVC', 'LFMC', 'LFNC', 'ENT', 'FMC'];

  List<String> get _availableSizes => _supportSpacing[_conduitType]?.keys.toList() ?? [];

  double get _maxSpacing {
    final spacing = _supportSpacing[_conduitType]?[_tradeSize];
    return spacing != null ? spacing[0] : 10;
  }

  double get _fromBox {
    final spacing = _supportSpacing[_conduitType]?[_tradeSize];
    return spacing != null ? spacing[1] : 3;
  }

  double get _verticalSpacing => _verticalSupport[_conduitType]?[_tradeSize] ?? 10;

  String get _necReference {
    switch (_conduitType) {
      case 'EMT': return 'NEC 358.30';
      case 'IMC': return 'NEC 342.30';
      case 'RMC': return 'NEC 344.30';
      case 'PVC': return 'NEC 352.30';
      case 'LFMC': return 'NEC 350.30';
      case 'LFNC': return 'NEC 356.30';
      case 'ENT': return 'NEC 362.30';
      case 'FMC': return 'NEC 348.30';
      default: return 'NEC Article 300';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (!_availableSizes.contains(_tradeSize) && _availableSizes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _tradeSize = _availableSizes.first);
      });
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Conduit Support Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConduitTypeCard(colors),
          const SizedBox(height: 16),
          _buildTradeSizeCard(colors),
          const SizedBox(height: 16),
          _buildOrientationCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildSupportTableCard(colors),
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
        Wrap(spacing: 8, runSpacing: 8, children: _conduitTypes.map((type) {
          final isSelected = _conduitType == type;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() { _conduitType = type; if (!_availableSizes.contains(_tradeSize)) _tradeSize = _availableSizes.first; }); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(type, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildTradeSizeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRADE SIZE (inches)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _availableSizes.map((size) {
          final isSelected = _tradeSize == size;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _tradeSize = size); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(size, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildOrientationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION ORIENTATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _isVertical = false); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: !_isVertical ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.arrowRight, size: 18, color: !_isVertical ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary),
                const SizedBox(width: 8),
                Text('Horizontal', style: TextStyle(color: !_isVertical ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _isVertical = true); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: _isVertical ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.arrowUp, size: 18, color: _isVertical ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary),
                const SizedBox(width: 8),
                Text('Vertical', style: TextStyle(color: _isVertical ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontWeight: FontWeight.w500)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final displaySpacing = _isVertical ? _verticalSpacing : _maxSpacing;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${displaySpacing.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('ft Maximum Spacing', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Conduit Type', _conduitType),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Trade Size', '$_tradeSize"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Orientation', _isVertical ? 'Vertical' : 'Horizontal'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Max from box/fitting', '${_fromBox.toStringAsFixed(0)} ft', highlight: true),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Max between supports', '${displaySpacing.toStringAsFixed(1)} ft'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSupportTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SUPPORT REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildSupportItem(colors, 'EMT', '10 ft', '3 ft'),
        const SizedBox(height: 8),
        _buildSupportItem(colors, 'RMC', '10-20 ft', '3 ft'),
        const SizedBox(height: 8),
        _buildSupportItem(colors, 'PVC', '3-6 ft', '3 ft'),
        const SizedBox(height: 8),
        _buildSupportItem(colors, 'LFMC/FMC', '4.5 ft', '12 in'),
      ]),
    );
  }

  Widget _buildSupportItem(ZaftoColors colors, String type, String spacing, String fromBox) {
    final isHighlighted = _conduitType == type;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
        borderRadius: BorderRadius.circular(6),
        border: isHighlighted ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)) : null,
      ),
      child: Row(children: [
        SizedBox(width: 60, child: Text(type, style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(child: Text('Max: $spacing', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text('From box: $fromBox', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text(_necReference, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• Support within 3 ft of boxes (most types)\n• Flexible conduit: 12 in from fittings\n• PVC requires closer spacing due to flexibility\n• Vertical runs may allow longer spacing', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
