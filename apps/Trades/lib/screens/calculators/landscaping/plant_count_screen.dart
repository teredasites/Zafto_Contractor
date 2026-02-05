import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Plant Count Calculator - Plants for bed area
class PlantCountScreen extends ConsumerStatefulWidget {
  const PlantCountScreen({super.key});
  @override
  ConsumerState<PlantCountScreen> createState() => _PlantCountScreenState();
}

class _PlantCountScreenState extends ConsumerState<PlantCountScreen> {
  final _areaController = TextEditingController(text: '100');
  final _spacingController = TextEditingController(text: '12');

  String _pattern = 'grid';

  int? _plantCount;
  double? _plantsPerSqFt;

  @override
  void dispose() { _areaController.dispose(); _spacingController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 100;
    final spacingIn = double.tryParse(_spacingController.text) ?? 12;

    final spacingFt = spacingIn / 12;
    final sqFtPerPlant = spacingFt * spacingFt;

    int plants;
    switch (_pattern) {
      case 'grid':
        // Square grid pattern
        plants = (area / sqFtPerPlant).ceil();
        break;
      case 'triangular':
        // Triangular/offset pattern - 15% more efficient
        plants = (area / sqFtPerPlant * 1.15).ceil();
        break;
      case 'natural':
        // Natural/random - use 80% of grid
        plants = (area / sqFtPerPlant * 0.8).ceil();
        break;
      default:
        plants = (area / sqFtPerPlant).ceil();
    }

    final perSqFt = plants / area;

    setState(() {
      _plantCount = plants;
      _plantsPerSqFt = perSqFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '100'; _spacingController.text = '12'; setState(() { _pattern = 'grid'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Plant Count', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PLANTING PATTERN', ['grid', 'triangular', 'natural'], _pattern, {'grid': 'Grid', 'triangular': 'Triangular', 'natural': 'Natural'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Bed Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Plant Spacing', unit: 'in', controller: _spacingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_plantCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PLANTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plantCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Density', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_plantsPerSqFt!.toStringAsFixed(2)} per sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpacingGuide(colors),
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

  Widget _buildSpacingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SPACINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Ground cover', '6-9\"'),
        _buildTableRow(colors, 'Perennials', '12-18\"'),
        _buildTableRow(colors, 'Small shrubs', '24-36\"'),
        _buildTableRow(colors, 'Large shrubs', '48-72\"'),
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
