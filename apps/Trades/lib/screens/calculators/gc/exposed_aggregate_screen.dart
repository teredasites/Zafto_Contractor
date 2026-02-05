import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Exposed Aggregate Calculator - Decorative aggregate concrete
class ExposedAggregateScreen extends ConsumerStatefulWidget {
  const ExposedAggregateScreen({super.key});
  @override
  ConsumerState<ExposedAggregateScreen> createState() => _ExposedAggregateScreenState();
}

class _ExposedAggregateScreenState extends ConsumerState<ExposedAggregateScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '15');
  final _depthController = TextEditingController(text: '4');

  String _method = 'retarder';

  double? _sqft;
  double? _cubicYards;
  double? _retarder;
  double? _sealer;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || width == null || depth == null) {
      setState(() { _sqft = null; _cubicYards = null; _retarder = null; _sealer = null; });
      return;
    }

    final sqft = length * width;
    final cubicFeet = sqft * (depth / 12);
    final cubicYards = cubicFeet / 27;

    // Surface retarder: 100-150 sqft per gallon
    final retarder = _method == 'retarder' ? sqft / 125 : 0.0;

    // Sealer: 200-300 sqft per gallon
    final sealer = sqft / 250;

    setState(() { _sqft = sqft; _cubicYards = cubicYards; _retarder = retarder; _sealer = sealer; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '15'; _depthController.text = '4'; setState(() => _method = 'retarder'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Exposed Aggregate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Slab Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(2)} CY', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                if (_method == 'retarder')
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Surface Retarder', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_retarder!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sealer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sealer!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Order decorative aggregate mix. Expose surface 4-6 hours after pour when retarder used.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMethodTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['retarder', 'wash', 'seeded'];
    final labels = {'retarder': 'Retarder', 'wash': 'Water Wash', 'seeded': 'Seeded'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('EXPOSURE METHOD', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _method == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _method = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildMethodTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EXPOSURE METHODS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Retarder', 'Spray on, wash off later'),
        _buildTableRow(colors, 'Water wash', 'Timing critical, ~2-4 hrs'),
        _buildTableRow(colors, 'Seeded', 'Broadcast aggregate on top'),
        _buildTableRow(colors, 'Depth', '1/16" to 1/4" exposure'),
        _buildTableRow(colors, 'Cost', '\$8-14/sqft installed'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
