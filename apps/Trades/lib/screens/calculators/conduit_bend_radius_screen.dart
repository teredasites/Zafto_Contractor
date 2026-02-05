import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Conduit Bend Radius Calculator - Design System v2.6
/// Minimum bend radius per NEC 344.24, 358.24, etc.
class ConduitBendRadiusScreen extends ConsumerStatefulWidget {
  const ConduitBendRadiusScreen({super.key});
  @override
  ConsumerState<ConduitBendRadiusScreen> createState() => _ConduitBendRadiusScreenState();
}

class _ConduitBendRadiusScreenState extends ConsumerState<ConduitBendRadiusScreen> {
  String _conduitType = 'EMT';
  String _tradeSize = '1';
  bool _hasLeadSheath = false;

  // NEC Chapter 9 Table 2 - Minimum bend radius (inches)
  // One shot bends (field bends)
  static const Map<String, Map<String, double>> _oneShot = {
    'EMT': {'1/2': 4, '3/4': 5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12, '2-1/2': 15, '3': 18, '3-1/2': 21, '4': 24},
    'IMC': {'1/2': 4, '3/4': 5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12, '2-1/2': 15, '3': 18, '3-1/2': 21, '4': 24},
    'RMC': {'1/2': 4, '3/4': 5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12, '2-1/2': 15, '3': 18, '3-1/2': 21, '4': 24, '5': 30, '6': 36},
    'PVC': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5, '2-1/2': 10.5, '3': 13, '3-1/2': 15, '4': 16, '5': 20, '6': 24},
    'LFMC': {'1/2': 4.5, '3/4': 5.5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12, '2-1/2': 15, '3': 18, '3-1/2': 21, '4': 24},
    'LFNC': {'1/2': 4.5, '3/4': 5.5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12},
    'ENT': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5},
  };

  // Factory bends / segmented (larger radius required)
  static const Map<String, Map<String, double>> _factoryBend = {
    'EMT': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5, '2-1/2': 10.5, '3': 13, '3-1/2': 15, '4': 16},
    'IMC': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5, '2-1/2': 10.5, '3': 13, '3-1/2': 15, '4': 16},
    'RMC': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5, '2-1/2': 10.5, '3': 13, '3-1/2': 15, '4': 16, '5': 20, '6': 24},
    'PVC': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5, '2-1/2': 10.5, '3': 13, '3-1/2': 15, '4': 16, '5': 20, '6': 24},
    'LFMC': {'1/2': 4.5, '3/4': 5.5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12, '2-1/2': 15, '3': 18, '3-1/2': 21, '4': 24},
    'LFNC': {'1/2': 4.5, '3/4': 5.5, '1': 6, '1-1/4': 8, '1-1/2': 10, '2': 12},
    'ENT': {'1/2': 4, '3/4': 4.5, '1': 5.75, '1-1/4': 7.25, '1-1/2': 8.25, '2': 9.5},
  };

  // Lead sheath multiplier (NEC Chapter 9 Note 2)
  static const double _leadSheathMultiplier = 1.5;

  static const List<String> _conduitTypes = ['EMT', 'IMC', 'RMC', 'PVC', 'LFMC', 'LFNC', 'ENT'];

  List<String> get _availableSizes => _oneShot[_conduitType]?.keys.toList() ?? [];

  double get _minRadiusOneShot {
    final radius = _oneShot[_conduitType]?[_tradeSize] ?? 0;
    return _hasLeadSheath ? radius * _leadSheathMultiplier : radius;
  }

  double get _minRadiusFactory {
    final radius = _factoryBend[_conduitType]?[_tradeSize] ?? 0;
    return _hasLeadSheath ? radius * _leadSheathMultiplier : radius;
  }

  String get _necReference {
    switch (_conduitType) {
      case 'EMT': return 'NEC 358.24';
      case 'IMC': return 'NEC 342.24';
      case 'RMC': return 'NEC 344.24';
      case 'PVC': return 'NEC 352.24';
      case 'LFMC': return 'NEC 350.24';
      case 'LFNC': return 'NEC 356.24';
      case 'ENT': return 'NEC 362.24';
      default: return 'NEC Chapter 9 Table 2';
    }
  }

  @override
  void didUpdateWidget(covariant ConduitBendRadiusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_availableSizes.contains(_tradeSize)) {
      setState(() => _tradeSize = _availableSizes.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    // Ensure valid trade size for selected conduit type
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
        title: Text('Conduit Bend Radius', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConduitTypeCard(colors),
          const SizedBox(height: 16),
          _buildTradeSizeCard(colors),
          const SizedBox(height: 16),
          _buildLeadSheathCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildBendingTipsCard(colors),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildLeadSheathCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONDUCTOR TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Lead-sheathed conductors', style: TextStyle(color: colors.textSecondary, fontSize: 14))),
          Switch(
            value: _hasLeadSheath,
            onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasLeadSheath = v); },
            activeColor: colors.accentPrimary,
          ),
        ]),
        const SizedBox(height: 4),
        Text(_hasLeadSheath ? 'Min radius increased 50%' : 'Standard conductors', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_minRadiusOneShot.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('inches Min Radius (Field Bend)', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Conduit Type', _conduitType),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Trade Size', '$_tradeSize"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'One-Shot Bend', '${_minRadiusOneShot.toStringAsFixed(1)}"'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Factory/Segment', '${_minRadiusFactory.toStringAsFixed(1)}"'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Diameter', '${(_minRadiusOneShot * 2).toStringAsFixed(1)}"', highlight: true),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBendingTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BENDING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildTipRow(colors, LucideIcons.checkCircle, 'Max 360 degrees of bends between pull points'),
        const SizedBox(height: 8),
        _buildTipRow(colors, LucideIcons.checkCircle, 'Use bender shoe matched to conduit size'),
        const SizedBox(height: 8),
        _buildTipRow(colors, LucideIcons.checkCircle, 'PVC must be heated uniformly for bends'),
        const SizedBox(height: 8),
        _buildTipRow(colors, LucideIcons.alertCircle, 'Never exceed 90 degrees per bend'),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: colors.textTertiary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text(_necReference, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• NEC Chapter 9 Table 2 - Radius of bends\n• One-shot bends: Field-made with bender\n• Segmented bends: Multiple cuts or factory\n• Lead sheath: 1.5x standard radius', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
