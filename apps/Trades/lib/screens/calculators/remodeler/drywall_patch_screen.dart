import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drywall Patch Calculator - Drywall repair estimation
class DrywallPatchScreen extends ConsumerStatefulWidget {
  const DrywallPatchScreen({super.key});
  @override
  ConsumerState<DrywallPatchScreen> createState() => _DrywallPatchScreenState();
}

class _DrywallPatchScreenState extends ConsumerState<DrywallPatchScreen> {
  final _widthController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '12');
  final _quantityController = TextEditingController(text: '1');

  String _type = 'medium';

  double? _patchSqIn;
  double? _compoundOz;
  double? _tapeLF;
  String? _method;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _quantityController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    final patchSqIn = width * height * quantity;
    final patchSqFt = patchSqIn / 144;

    // Joint compound: ~1 oz per sq inch for 3 coats
    final compoundOz = patchSqIn * 0.15;

    // Tape: perimeter of patch
    final perimeter = (width + height) * 2 / 12; // in feet
    final tapeLF = perimeter * quantity;

    // Method based on size
    String method;
    if (width <= 2 && height <= 2) {
      method = 'Spackle fill';
    } else if (width <= 6 && height <= 6) {
      method = 'Self-adhesive patch';
    } else if (width <= 12 && height <= 12) {
      method = 'California patch';
    } else {
      method = 'Full drywall piece';
    }

    setState(() { _patchSqIn = patchSqIn; _compoundOz = compoundOz; _tapeLF = tapeLF; _method = method; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '12'; _heightController.text = '12'; _quantityController.text = '1'; setState(() => _type = 'medium'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Drywall Patch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Hole Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Hole Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Patches', unit: 'qty', controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_patchSqIn != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_method!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Patch Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_patchSqIn!.toStringAsFixed(0)} sq in', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joint Compound', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_compoundOz!.toStringAsFixed(0)} oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tape (if needed)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tapeLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Allow 24hr dry time between coats. Sand between coats with 120-150 grit.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
    final options = ['small', 'medium', 'large'];
    final labels = {'small': 'Small (<2\")', 'medium': 'Medium (2-6\")', 'large': 'Large (6\"+)'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HOLE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
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
        Text('PATCH METHODS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Nail holes', 'Spackle, 1 coat'),
        _buildTableRow(colors, 'Up to 2\"', 'Self-adhesive mesh'),
        _buildTableRow(colors, '2-6\"', 'Adhesive patch kit'),
        _buildTableRow(colors, '6-12\"', 'California/hot patch'),
        _buildTableRow(colors, '12\"+', 'Stud-to-stud piece'),
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
