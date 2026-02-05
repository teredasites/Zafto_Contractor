import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fire Extinguisher Calculator - Commercial/residential placement
class FireExtinguisherScreen extends ConsumerStatefulWidget {
  const FireExtinguisherScreen({super.key});
  @override
  ConsumerState<FireExtinguisherScreen> createState() => _FireExtinguisherScreenState();
}

class _FireExtinguisherScreenState extends ConsumerState<FireExtinguisherScreen> {
  final _sqftController = TextEditingController(text: '5000');

  String _occupancy = 'light';
  String _building = 'commercial';

  int? _quantity;
  String? _type;
  String? _spacing;

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text);

    if (sqft == null) {
      setState(() { _quantity = null; _type = null; _spacing = null; });
      return;
    }

    String type;
    int maxTravel;
    int coveragePerUnit;

    // NFPA 10 requirements
    switch (_occupancy) {
      case 'light':
        // Office, church, classroom
        type = '2A:10B:C';
        maxTravel = 75;
        coveragePerUnit = 3000;
        break;
      case 'ordinary':
        // Restaurant, retail, warehouse
        type = '2A:10B:C';
        maxTravel = 75;
        coveragePerUnit = 3000;
        break;
      case 'extra':
        // Workshop, manufacturing
        type = '4A:40B:C';
        maxTravel = 50;
        coveragePerUnit = 2000;
        break;
      default:
        type = '2A:10B:C';
        maxTravel = 75;
        coveragePerUnit = 3000;
    }

    // Calculate quantity (minimum 1)
    var quantity = (sqft / coveragePerUnit).ceil();
    if (quantity < 1) quantity = 1;

    // Residential recommendation (not code required)
    if (_building == 'residential') {
      type = '2A:10B:C or 5-B:C kitchen';
      quantity = 1 + ((sqft / 2000).ceil() - 1); // 1 per floor effectively
      if (quantity < 1) quantity = 1;
    }

    final spacing = '${maxTravel}ft max travel distance';

    setState(() { _quantity = quantity; _type = type; _spacing = spacing; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '5000'; setState(() { _occupancy = 'light'; _building = 'commercial'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fire Extinguishers', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BUILDING TYPE', ['residential', 'commercial'], _building, {'residential': 'Residential', 'commercial': 'Commercial'}, (v) { setState(() => _building = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'OCCUPANCY HAZARD', ['light', 'ordinary', 'extra'], _occupancy, {'light': 'Light', 'ordinary': 'Ordinary', 'extra': 'Extra'}, (v) { setState(() => _occupancy = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Floor Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_quantity != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EXTINGUISHERS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_quantity', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rating', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_type!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_spacing!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Mount 3.5-5ft above floor. Near exits. K-class for commercial kitchens.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildClassTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildClassTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FIRE CLASSES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Class A', 'Wood, paper, cloth'),
        _buildTableRow(colors, 'Class B', 'Flammable liquids'),
        _buildTableRow(colors, 'Class C', 'Electrical equipment'),
        _buildTableRow(colors, 'Class K', 'Cooking oils/fats'),
        _buildTableRow(colors, 'ABC type', 'Most common multi-use'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }
}
