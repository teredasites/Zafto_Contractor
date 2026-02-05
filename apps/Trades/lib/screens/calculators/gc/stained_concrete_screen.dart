import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stained Concrete Calculator - Acid/water stain estimation
class StainedConcreteScreen extends ConsumerStatefulWidget {
  const StainedConcreteScreen({super.key});
  @override
  ConsumerState<StainedConcreteScreen> createState() => _StainedConcreteScreenState();
}

class _StainedConcreteScreenState extends ConsumerState<StainedConcreteScreen> {
  final _sqftController = TextEditingController(text: '500');
  final _coatsController = TextEditingController(text: '2');

  String _stainType = 'acid';

  double? _stainGallons;
  double? _neutralizer;
  double? _sealer;

  @override
  void dispose() { _sqftController.dispose(); _coatsController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text);
    final coats = int.tryParse(_coatsController.text) ?? 1;

    if (sqft == null) {
      setState(() { _stainGallons = null; _neutralizer = null; _sealer = null; });
      return;
    }

    double coveragePerGal;
    double neutralizerNeeded;

    switch (_stainType) {
      case 'acid':
        // Acid stain: 200-400 sqft/gal depending on porosity
        coveragePerGal = 300;
        neutralizerNeeded = sqft / 200; // Neutralizer coverage
        break;
      case 'water':
        // Water-based stain: 300-500 sqft/gal
        coveragePerGal = 400;
        neutralizerNeeded = 0; // No neutralizer needed
        break;
      case 'dye':
        // Concrete dye: 400-600 sqft/gal
        coveragePerGal = 500;
        neutralizerNeeded = 0;
        break;
      default:
        coveragePerGal = 300;
        neutralizerNeeded = sqft / 200;
    }

    final stainGallons = (sqft / coveragePerGal) * coats;

    // Sealer: 200-300 sqft per gallon, 2 coats typical
    final sealer = (sqft / 250) * 2;

    setState(() { _stainGallons = stainGallons; _neutralizer = neutralizerNeeded; _sealer = sealer; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '500'; _coatsController.text = '2'; setState(() => _stainType = 'acid'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stained Concrete', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Floor Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stain Coats', unit: 'coats', controller: _coatsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_stainGallons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STAIN NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stainGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_stainType == 'acid') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Neutralizer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_neutralizer!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sealer (2 coats)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sealer!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _stainType == 'acid' ? colors.accentWarning.withValues(alpha: 0.1) : colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_stainType == 'acid' ? 'Acid stain: Use PPE. Neutralize before sealing. Results vary by concrete composition.' : 'Water-based: Lower VOC, more color options. Good for interior use.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStainTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['acid', 'water', 'dye'];
    final labels = {'acid': 'Acid Stain', 'water': 'Water-Based', 'dye': 'Concrete Dye'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STAIN TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _stainType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _stainType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStainTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STAIN COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Acid stain', 'Natural, mottled look'),
        _buildTableRow(colors, 'Water-based', 'Solid, consistent color'),
        _buildTableRow(colors, 'Dye', 'Vibrant, fast drying'),
        _buildTableRow(colors, 'Surface prep', 'Clean, dry, 28+ days'),
        _buildTableRow(colors, 'Cost', '\$2-4/sqft DIY'),
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
