import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Annual Bed Calculator - Plants for flower bed
class AnnualBedScreen extends ConsumerStatefulWidget {
  const AnnualBedScreen({super.key});
  @override
  ConsumerState<AnnualBedScreen> createState() => _AnnualBedScreenState();
}

class _AnnualBedScreenState extends ConsumerState<AnnualBedScreen> {
  final _lengthController = TextEditingController(text: '10');
  final _widthController = TextEditingController(text: '4');

  String _plantSize = 'medium';
  String _pattern = 'grid';

  int? _plantsNeeded;
  int? _flatsNeeded;
  double? _soilCuFt;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 10;
    final width = double.tryParse(_widthController.text) ?? 4;
    final area = length * width;

    // Spacing by plant size
    double spacingIn;
    switch (_plantSize) {
      case 'small': spacingIn = 6; break; // Alyssum, lobelia
      case 'medium': spacingIn = 9; break; // Petunias, marigolds
      case 'large': spacingIn = 12; break; // Geraniums, zinnias
      default: spacingIn = 9;
    }

    final spacingFt = spacingIn / 12;
    int plants;

    if (_pattern == 'grid') {
      final across = (length / spacingFt).ceil();
      final deep = (width / spacingFt).ceil();
      plants = across * deep;
    } else {
      // Triangular - more efficient
      final across = (length / spacingFt).ceil();
      final rowSpacing = spacingFt * 0.866;
      final rows = (width / rowSpacing).ceil();
      plants = (across * rows * 1.15).ceil(); // ~15% more
    }

    // Flats typically hold 36 or 48 plants (4-packs = 18 or 24 packs)
    final flats = (plants / 36).ceil();

    // Soil amendment: 2-3" of compost for bed prep
    final soilCuFt = area * (2.5 / 12);

    setState(() {
      _plantsNeeded = plants;
      _flatsNeeded = flats;
      _soilCuFt = soilCuFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '10'; _widthController.text = '4'; setState(() { _plantSize = 'medium'; _pattern = 'grid'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Annual Bed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PLANT SIZE', ['small', 'medium', 'large'], _plantSize, {'small': 'Small (6")', 'medium': 'Medium (9")', 'large': 'Large (12")'}, (v) { setState(() => _plantSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN', ['grid', 'triangle'], _pattern, {'grid': 'Grid', 'triangle': 'Triangular'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bed Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_plantsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PLANTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plantsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Flats (36 plants)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_flatsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Compost amendment', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuFt!.toStringAsFixed(1)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlantGuide(colors),
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

  Widget _buildPlantGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ANNUAL SPACING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Alyssum, Lobelia', '6"'),
        _buildTableRow(colors, 'Petunia, Marigold', '9"'),
        _buildTableRow(colors, 'Impatiens, Begonia', '9-12"'),
        _buildTableRow(colors, 'Geranium, Zinnia', '12"'),
        _buildTableRow(colors, 'Celosia, Salvia', '12-15"'),
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
