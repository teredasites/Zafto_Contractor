import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weed Control Calculator - Herbicide application
class WeedControlScreen extends ConsumerStatefulWidget {
  const WeedControlScreen({super.key});
  @override
  ConsumerState<WeedControlScreen> createState() => _WeedControlScreenState();
}

class _WeedControlScreenState extends ConsumerState<WeedControlScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _herbicideType = 'post';
  String _application = 'broadcast';

  double? _productNeeded;
  double? _waterGallons;
  String? _mixRate;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    // Rates vary by product type and application
    double ozPer1000;
    double waterPer1000;
    String mixRate;

    switch (_herbicideType) {
      case 'post':
        // Post-emergent broadleaf (2,4-D type)
        ozPer1000 = _application == 'broadcast' ? 1.5 : 3.0;
        waterPer1000 = 1.0;
        mixRate = '1.5 oz per gallon';
        break;
      case 'pre':
        // Pre-emergent
        ozPer1000 = _application == 'broadcast' ? 1.0 : 2.0;
        waterPer1000 = 1.0;
        mixRate = '1 oz per gallon';
        break;
      case 'nonselective':
        // Glyphosate type
        ozPer1000 = _application == 'broadcast' ? 2.0 : 4.0;
        waterPer1000 = 1.0;
        mixRate = '2 oz per gallon';
        break;
      default:
        ozPer1000 = 1.5;
        waterPer1000 = 1.0;
        mixRate = '1.5 oz per gallon';
    }

    final product = (area / 1000) * ozPer1000;
    final water = (area / 1000) * waterPer1000;

    setState(() {
      _productNeeded = product;
      _waterGallons = water;
      _mixRate = mixRate;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _herbicideType = 'post'; _application = 'broadcast'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Weed Control', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HERBICIDE TYPE', ['post', 'pre', 'nonselective'], _herbicideType, {'post': 'Post-Emergent', 'pre': 'Pre-Emergent', 'nonselective': 'Non-Selective'}, (v) { setState(() => _herbicideType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'APPLICATION', ['broadcast', 'spot'], _application, {'broadcast': 'Broadcast', 'spot': 'Spot Spray'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Treatment Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_productNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PRODUCT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_productNeeded!.toStringAsFixed(1)} oz', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_waterGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mix rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_mixRate', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Always read and follow product label. Rates vary by product.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 20),
            _buildWeedGuide(colors),
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

  Widget _buildWeedGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best temp', '60-85°F'),
        _buildTableRow(colors, 'Wind', '<10 mph'),
        _buildTableRow(colors, 'Rain-free', '4+ hours after'),
        _buildTableRow(colors, 'Active growth', 'Required for post-em'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
