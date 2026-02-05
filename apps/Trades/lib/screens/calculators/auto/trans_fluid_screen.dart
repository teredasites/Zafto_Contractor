import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Transmission Fluid Service Calculator
class TransFluidScreen extends ConsumerStatefulWidget {
  const TransFluidScreen({super.key});
  @override
  ConsumerState<TransFluidScreen> createState() => _TransFluidScreenState();
}

class _TransFluidScreenState extends ConsumerState<TransFluidScreen> {
  final _capacityController = TextEditingController();
  String _transType = 'Automatic';
  String _serviceType = 'Drain & Fill';

  double? _fluidNeeded;
  String? _recommendation;

  void _calculate() {
    final capacity = double.tryParse(_capacityController.text);

    if (capacity == null || capacity <= 0) {
      setState(() { _fluidNeeded = null; });
      return;
    }

    double fluidNeeded;
    String recommendation;

    if (_serviceType == 'Drain & Fill') {
      // Drain & fill only gets ~40-50% of fluid
      fluidNeeded = capacity * 0.45;
      recommendation = 'Drain & fill: May need 2-3 services to replace most fluid';
    } else if (_serviceType == 'Pan Drop') {
      // Pan drop gets slightly more
      fluidNeeded = capacity * 0.5;
      recommendation = 'Pan drop: Replace filter when dropping pan';
    } else {
      // Full flush replaces nearly all fluid
      fluidNeeded = capacity * 1.1; // Extra for purging
      recommendation = 'Full flush: Use approved fluid only. Check for leaks after.';
    }

    setState(() {
      _fluidNeeded = fluidNeeded;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _capacityController.clear();
    setState(() { _fluidNeeded = null; });
  }

  @override
  void dispose() {
    _capacityController.dispose();
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
        title: Text('Trans Fluid Service', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('TRANSMISSION TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTransSelector(colors),
            const SizedBox(height: 16),
            Text('SERVICE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildServiceSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Total Capacity', unit: 'qt', hint: 'From manual', controller: _capacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fluidNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTransSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Automatic', 'Manual', 'CVT', 'DCT'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _transType == type,
        onSelected: (_) => setState(() { _transType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildServiceSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Drain & Fill', 'Pan Drop', 'Full Flush'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _serviceType == type,
        onSelected: (_) => setState(() { _serviceType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Drain gets ~45% of total capacity', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Use manufacturer-specified fluid only', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Fluid Needed', '${_fluidNeeded!.toStringAsFixed(1)} qt', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${(_fluidNeeded! * 0.946).toStringAsFixed(1)} L'),
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
