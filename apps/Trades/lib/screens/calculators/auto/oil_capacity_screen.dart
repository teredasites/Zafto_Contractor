import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Engine Oil Capacity Calculator
class OilCapacityScreen extends ConsumerStatefulWidget {
  const OilCapacityScreen({super.key});
  @override
  ConsumerState<OilCapacityScreen> createState() => _OilCapacityScreenState();
}

class _OilCapacityScreenState extends ConsumerState<OilCapacityScreen> {
  final _displacementController = TextEditingController();
  String _engineType = 'Inline 4';
  bool _withFilter = true;

  double? _oilCapacity;
  String? _recommendation;

  // Base oil capacity by engine type (quarts per liter of displacement)
  static const Map<String, double> _capacityPerLiter = {
    'Inline 4': 1.1,
    'Inline 6': 1.0,
    'V6': 1.15,
    'V8': 1.2,
    'Diesel': 1.4,
  };

  void _calculate() {
    final displacement = double.tryParse(_displacementController.text);

    if (displacement == null || displacement <= 0) {
      setState(() { _oilCapacity = null; });
      return;
    }

    final baseCapacity = displacement * _capacityPerLiter[_engineType]!;
    // Filter adds 0.5-1 quart
    final filterAdd = _withFilter ? 0.75 : 0.0;
    final totalCapacity = baseCapacity + filterAdd;

    String recommendation;
    if (_engineType == 'Diesel') {
      recommendation = 'Use diesel-rated oil (CK-4 or FA-4 spec)';
    } else if (displacement > 5.0) {
      recommendation = 'High-displacement: Consider synthetic 5W-30 or 5W-40';
    } else {
      recommendation = 'Check owner\'s manual for exact capacity and spec';
    }

    setState(() {
      _oilCapacity = totalCapacity;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _withFilter = true;
    setState(() { _oilCapacity = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
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
        title: Text('Oil Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('ENGINE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Displacement', unit: 'L', hint: 'Engine size', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildFilterToggle(colors),
            const SizedBox(height: 32),
            if (_oilCapacity != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _capacityPerLiter.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _engineType == type,
        onSelected: (_) => setState(() { _engineType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFilterToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('With Filter'), selected: _withFilter, onSelected: (_) => setState(() { _withFilter = true; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Without Filter'), selected: !_withFilter, onSelected: (_) => setState(() { _withFilter = false; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Capacity = Displacement × Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate based on engine configuration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Oil Capacity', '${_oilCapacity!.toStringAsFixed(1)} qt', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${(_oilCapacity! * 0.946).toStringAsFixed(1)} L'),
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
