import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Collector Calculator - Size header collector for exhaust flow
class CollectorScreen extends ConsumerStatefulWidget {
  const CollectorScreen({super.key});
  @override
  ConsumerState<CollectorScreen> createState() => _CollectorScreenState();
}

class _CollectorScreenState extends ConsumerState<CollectorScreen> {
  final _primaryDiaController = TextEditingController();
  final _numPrimariesController = TextEditingController();

  double? _collectorDia;
  double? _collectorArea;

  void _calculate() {
    final primaryDia = double.tryParse(_primaryDiaController.text);
    final numPrimaries = double.tryParse(_numPrimariesController.text);

    if (primaryDia == null || numPrimaries == null || numPrimaries <= 0) {
      setState(() { _collectorDia = null; });
      return;
    }

    // Calculate total primary area
    final primaryArea = numPrimaries * math.pi * math.pow(primaryDia / 2, 2);

    // Collector should be 85-95% of total primary area for street
    // Using 90% as a good balance
    final collectorArea = primaryArea * 0.90;
    final collectorDia = 2 * math.sqrt(collectorArea / math.pi);

    setState(() {
      _collectorDia = collectorDia;
      _collectorArea = collectorArea;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _primaryDiaController.clear();
    _numPrimariesController.clear();
    setState(() { _collectorDia = null; });
  }

  @override
  void dispose() {
    _primaryDiaController.dispose();
    _numPrimariesController.dispose();
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
        title: Text('Collector Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Primary Tube Diameter', unit: 'in', hint: 'e.g., 1.75', controller: _primaryDiaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Primaries', unit: '', hint: '4 for V8 side', controller: _numPrimariesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_collectorDia != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildCollectorTypes(colors),
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
        Text('Collector Area = 0.9 x Total Primary Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Size collector to merge primary tubes efficiently', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('COLLECTOR SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_collectorDia!.toStringAsFixed(2)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Area: ${_collectorArea!.toStringAsFixed(2)} sq in', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('Standard sizes: 2.5", 3", 3.5"', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Merge collectors add 10-15% flow', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCollectorTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COLLECTOR TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTypeRow(colors, '4-into-1', 'Best top-end power'),
        _buildTypeRow(colors, '4-2-1 (Tri-Y)', 'Better mid-range torque'),
        _buildTypeRow(colors, 'Merge', 'Smoothest transition'),
        _buildTypeRow(colors, 'Spike', 'Budget option'),
        const SizedBox(height: 12),
        Text('Merge collectors outperform spike collectors at all RPM ranges.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildTypeRow(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
