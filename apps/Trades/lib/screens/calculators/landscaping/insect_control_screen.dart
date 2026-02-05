import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Insect Control Calculator - Pest treatment application
class InsectControlScreen extends ConsumerStatefulWidget {
  const InsectControlScreen({super.key});
  @override
  ConsumerState<InsectControlScreen> createState() => _InsectControlScreenState();
}

class _InsectControlScreenState extends ConsumerState<InsectControlScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _pestType = 'grubs';
  String _productType = 'granular';

  double? _productNeeded;
  String? _unit;
  String? _timing;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    double ratePer1000;
    String unit;
    String timing;

    if (_productType == 'granular') {
      switch (_pestType) {
        case 'grubs':
          ratePer1000 = 3.0; // lbs
          unit = 'lbs';
          timing = 'Late June-July';
          break;
        case 'ants':
          ratePer1000 = 2.0;
          unit = 'lbs';
          timing = 'Spring or as needed';
          break;
        case 'chinch':
          ratePer1000 = 2.5;
          unit = 'lbs';
          timing = 'June-August';
          break;
        default:
          ratePer1000 = 2.5;
          unit = 'lbs';
          timing = 'As needed';
      }
    } else {
      // Liquid
      switch (_pestType) {
        case 'grubs':
          ratePer1000 = 1.5; // oz
          unit = 'oz';
          timing = 'Late June-July';
          break;
        case 'ants':
          ratePer1000 = 1.0;
          unit = 'oz';
          timing = 'Spring or as needed';
          break;
        case 'chinch':
          ratePer1000 = 1.0;
          unit = 'oz';
          timing = 'June-August';
          break;
        default:
          ratePer1000 = 1.0;
          unit = 'oz';
          timing = 'As needed';
      }
    }

    final product = (area / 1000) * ratePer1000;

    setState(() {
      _productNeeded = product;
      _unit = unit;
      _timing = timing;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _pestType = 'grubs'; _productType = 'granular'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Insect Control', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TARGET PEST', ['grubs', 'ants', 'chinch'], _pestType, {'grubs': 'Grubs', 'ants': 'Ants', 'chinch': 'Chinch Bugs'}, (v) { setState(() => _pestType = v); _calculate(); }),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Best timing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_timing', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                if (_productType == 'granular') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water in', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('Within 24 hours', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            _buildPestGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildPestGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PEST ID', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Grubs', 'Spongy turf, pull-up'),
        _buildTableRow(colors, 'Chinch bugs', 'Yellow patches, thatch'),
        _buildTableRow(colors, 'Ants', 'Mounds, bare spots'),
        _buildTableRow(colors, 'Threshold', '5+ grubs per sq ft'),
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
