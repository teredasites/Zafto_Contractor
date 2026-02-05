import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Excavation Volume Calculator
class ExcavationCalculatorScreen extends ConsumerStatefulWidget {
  const ExcavationCalculatorScreen({super.key});
  @override
  ConsumerState<ExcavationCalculatorScreen> createState() => _ExcavationCalculatorScreenState();
}

class _ExcavationCalculatorScreenState extends ConsumerState<ExcavationCalculatorScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _shallowController = TextEditingController(text: '3.5');
  final _deepController = TextEditingController(text: '8');

  double? _cubicYards;
  int? _truckLoads;
  double? _estimatedCost;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final shallow = double.tryParse(_shallowController.text);
    final deep = double.tryParse(_deepController.text);

    if (length == null || width == null || shallow == null || deep == null ||
        length <= 0 || width <= 0 || shallow <= 0 || deep <= 0) {
      setState(() { _cubicYards = null; });
      return;
    }

    // Add 2 ft on each side for working room + shell thickness
    final digLength = length + 4;
    final digWidth = width + 4;
    // Add 1 ft to depth for floor, plumbing, and base
    final avgDepth = ((shallow + deep) / 2) + 1;

    // Approximate pool shape volume (accounts for sloped floor)
    final cubicFeet = digLength * digWidth * avgDepth;
    final cubicYards = cubicFeet / 27;

    // Standard dump truck = 10-12 cubic yards
    final trucks = (cubicYards / 10).ceil();

    // Excavation cost ~$5-15 per cubic yard depending on access/soil
    final cost = cubicYards * 10;

    setState(() {
      _cubicYards = cubicYards;
      _truckLoads = trucks;
      _estimatedCost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _shallowController.text = '3.5';
    _deepController.text = '8';
    setState(() { _cubicYards = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _shallowController.dispose();
    _deepController.dispose();
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
        title: Text('Pool Excavation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Length', unit: 'ft', hint: 'Finished pool length', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pool Width', unit: 'ft', hint: 'Finished pool width', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Shallow End', unit: 'ft', hint: 'Shallow depth', controller: _shallowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deep End', unit: 'ft', hint: 'Deep depth', controller: _deepController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cubicYards != null) _buildResultsCard(colors),
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
        Text('CY = (L+4) × (W+4) × Avg Depth / 27', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Adds 2 ft each side for work space', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Excavation', '${_cubicYards!.toStringAsFixed(0)} cu yd', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Truck Loads', '$_truckLoads trucks (10 cy each)'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Cost', '\$${_estimatedCost!.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Rock or groundwater may increase costs significantly. Verify soil conditions.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
