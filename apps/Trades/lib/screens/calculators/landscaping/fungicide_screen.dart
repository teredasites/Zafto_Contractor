import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fungicide Calculator - Lawn disease treatment
class FungicideScreen extends ConsumerStatefulWidget {
  const FungicideScreen({super.key});
  @override
  ConsumerState<FungicideScreen> createState() => _FungicideScreenState();
}

class _FungicideScreenState extends ConsumerState<FungicideScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _diseaseType = 'brownpatch';
  String _productType = 'granular';

  double? _productNeeded;
  String? _unit;
  String? _interval;
  String? _conditions;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    double ratePer1000;
    String unit;
    String interval;
    String conditions;

    if (_productType == 'granular') {
      switch (_diseaseType) {
        case 'brownpatch':
          ratePer1000 = 3.0;
          unit = 'lbs';
          interval = '14-21 days';
          conditions = 'Warm, humid nights';
          break;
        case 'dollarspot':
          ratePer1000 = 2.5;
          unit = 'lbs';
          interval = '14 days';
          conditions = 'Low nitrogen, drought';
          break;
        case 'redthread':
          ratePer1000 = 2.0;
          unit = 'lbs';
          interval = '21-28 days';
          conditions = 'Cool, wet spring/fall';
          break;
        default:
          ratePer1000 = 3.0;
          unit = 'lbs';
          interval = '14-21 days';
          conditions = 'Varies';
      }
    } else {
      switch (_diseaseType) {
        case 'brownpatch':
          ratePer1000 = 2.0;
          unit = 'oz';
          interval = '14-21 days';
          conditions = 'Warm, humid nights';
          break;
        case 'dollarspot':
          ratePer1000 = 1.5;
          unit = 'oz';
          interval = '14 days';
          conditions = 'Low nitrogen, drought';
          break;
        case 'redthread':
          ratePer1000 = 1.0;
          unit = 'oz';
          interval = '21-28 days';
          conditions = 'Cool, wet spring/fall';
          break;
        default:
          ratePer1000 = 2.0;
          unit = 'oz';
          interval = '14-21 days';
          conditions = 'Varies';
      }
    }

    final product = (area / 1000) * ratePer1000;

    setState(() {
      _productNeeded = product;
      _unit = unit;
      _interval = interval;
      _conditions = conditions;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _diseaseType = 'brownpatch'; _productType = 'granular'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fungicide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'DISEASE', ['brownpatch', 'dollarspot', 'redthread'], _diseaseType, {'brownpatch': 'Brown Patch', 'dollarspot': 'Dollar Spot', 'redthread': 'Red Thread'}, (v) { setState(() => _diseaseType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'PRODUCT TYPE', ['granular', 'liquid'], _productType, {'granular': 'Granular', 'liquid': 'Liquid'}, (v) { setState(() => _productType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Treatment Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_productNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PRODUCT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_productNeeded!.toStringAsFixed(1)} $_unit', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Reapply interval', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_interval', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Conditions', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_conditions', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDiseaseGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDiseaseGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DISEASE ID', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Brown patch', 'Circular, smoke ring'),
        _buildTableRow(colors, 'Dollar spot', 'Small tan circles'),
        _buildTableRow(colors, 'Red thread', 'Pink/red threads'),
        _buildTableRow(colors, 'Prevention', 'Proper N, avoid overwatering'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
