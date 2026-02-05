import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Automotive Paint Coverage Calculator
class PaintCoverageScreen extends ConsumerStatefulWidget {
  const PaintCoverageScreen({super.key});
  @override
  ConsumerState<PaintCoverageScreen> createState() => _PaintCoverageScreenState();
}

class _PaintCoverageScreenState extends ConsumerState<PaintCoverageScreen> {
  String _vehicleSize = 'Midsize';
  String _paintType = 'Basecoat';
  int _coats = 3;

  double? _paintNeeded;
  double? _clearNeeded;
  String? _recommendation;

  // Square footage by vehicle size
  static const Map<String, double> _vehicleSqFt = {
    'Compact': 80,
    'Midsize': 110,
    'Full Size': 130,
    'Truck': 150,
    'SUV': 160,
  };

  // Coverage per quart (sq ft) by paint type
  static const Map<String, double> _coveragePerQt = {
    'Primer': 40,
    'Basecoat': 35,
    'Single Stage': 30,
  };

  void _calculate() {
    final sqFt = _vehicleSqFt[_vehicleSize]!;
    final coveragePerQt = _coveragePerQt[_paintType]!;

    // Calculate paint needed
    final paintNeeded = (sqFt * _coats) / coveragePerQt;

    // Clear coat (if using basecoat) - typically 2-3 coats
    double clearNeeded = 0;
    if (_paintType == 'Basecoat') {
      clearNeeded = (sqFt * 2.5) / 40; // Clear covers about 40 sq ft per quart
    }

    String recommendation;
    if (_paintType == 'Single Stage') {
      recommendation = 'Single stage: No clear coat needed, but less durable';
    } else if (_paintType == 'Basecoat') {
      recommendation = 'Add 10-15% extra for blending and touch-ups';
    } else {
      recommendation = 'Use 2-3 coats of primer for best adhesion';
    }

    setState(() {
      _paintNeeded = paintNeeded;
      _clearNeeded = clearNeeded;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleSize = 'Midsize';
    _paintType = 'Basecoat';
    _coats = 3;
    setState(() { _paintNeeded = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paint Coverage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('VEHICLE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildVehicleSelector(colors),
            const SizedBox(height: 16),
            Text('PAINT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildPaintSelector(colors),
            const SizedBox(height: 16),
            Text('NUMBER OF COATS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildCoatSelector(colors),
            const SizedBox(height: 32),
            if (_paintNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _vehicleSqFt.keys.map((size) => ChoiceChip(
        label: Text(size, style: const TextStyle(fontSize: 11)),
        selected: _vehicleSize == size,
        onSelected: (_) => setState(() { _vehicleSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPaintSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _coveragePerQt.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _paintType == type,
        onSelected: (_) => setState(() { _paintType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildCoatSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [2, 3, 4, 5].map((num) => ChoiceChip(
        label: Text('$num'),
        selected: _coats == num,
        onSelected: (_) => setState(() { _coats = num; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Paint = (Area × Coats) / Coverage', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Typical coverage: 30-40 sq ft per quart', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, '$_paintType Needed', '${_paintNeeded!.toStringAsFixed(1)} qt', isPrimary: true),
        if (_clearNeeded! > 0) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Clear Coat', '${_clearNeeded!.toStringAsFixed(1)} qt'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
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
