import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lighting Layout Calculator - Recessed light placement
class LightingLayoutScreen extends ConsumerStatefulWidget {
  const LightingLayoutScreen({super.key});
  @override
  ConsumerState<LightingLayoutScreen> createState() => _LightingLayoutScreenState();
}

class _LightingLayoutScreenState extends ConsumerState<LightingLayoutScreen> {
  final _lengthController = TextEditingController(text: '15');
  final _widthController = TextEditingController(text: '12');
  final _ceilingController = TextEditingController(text: '8');

  String _roomType = 'living';
  String _lightSize = '6inch';

  int? _lightsNeeded;
  double? _spacing;
  int? _lumensTotal;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _ceilingController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final ceiling = double.tryParse(_ceilingController.text) ?? 8;

    final sqft = length * width;

    // Lumens needed per sqft by room type
    int lumensPerSqft;
    switch (_roomType) {
      case 'kitchen': lumensPerSqft = 50; break;
      case 'bathroom': lumensPerSqft = 60; break;
      case 'living': lumensPerSqft = 20; break;
      case 'bedroom': lumensPerSqft = 15; break;
      case 'office': lumensPerSqft = 40; break;
      default: lumensPerSqft = 20;
    }

    final lumensTotal = (sqft * lumensPerSqft).ceil();

    // LED recessed: ~800 lumens for 6", ~500 for 4"
    int lumensPerLight;
    switch (_lightSize) {
      case '4inch': lumensPerLight = 500; break;
      case '6inch': lumensPerLight = 800; break;
      default: lumensPerLight = 800;
    }

    var lightsNeeded = (lumensTotal / lumensPerLight).ceil();
    if (lightsNeeded < 1) lightsNeeded = 1;

    // Ideal spacing: ceiling height / 2
    final spacing = ceiling / 2;

    setState(() { _lightsNeeded = lightsNeeded; _spacing = spacing; _lumensTotal = lumensTotal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '15'; _widthController.text = '12'; _ceilingController.text = '8'; setState(() { _roomType = 'living'; _lightSize = '6inch'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lighting Layout', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROOM TYPE', ['kitchen', 'living', 'bedroom', 'office'], _roomType, {'kitchen': 'Kitchen', 'living': 'Living', 'bedroom': 'Bedroom', 'office': 'Office'}, (v) { setState(() => _roomType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'LIGHT SIZE', ['4inch', '6inch'], _lightSize, {'4inch': '4\" Recessed', '6inch': '6\" Recessed'}, (v) { setState(() => _lightSize = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _ceilingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lightsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LIGHTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_lightsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Lumens', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_lumensTotal lm', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ideal Spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_spacing!.toStringAsFixed(1)}\' apart', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Offset', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_spacing! / 2).toStringAsFixed(1)}\' from wall', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Rule: Spacing = ceiling height / 2. Start spacing/2 from walls.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLumensTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildLumensTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LUMENS BY ROOM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Kitchen/Bath', '50-60 lm/sqft'),
        _buildTableRow(colors, 'Office/Reading', '40-50 lm/sqft'),
        _buildTableRow(colors, 'Living room', '15-25 lm/sqft'),
        _buildTableRow(colors, 'Bedroom', '10-20 lm/sqft'),
        _buildTableRow(colors, 'Hallway', '5-10 lm/sqft'),
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
