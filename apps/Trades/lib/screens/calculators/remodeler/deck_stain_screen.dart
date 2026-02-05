import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Stain Calculator - Deck refinishing estimation
class DeckStainScreen extends ConsumerStatefulWidget {
  const DeckStainScreen({super.key});
  @override
  ConsumerState<DeckStainScreen> createState() => _DeckStainScreenState();
}

class _DeckStainScreenState extends ConsumerState<DeckStainScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');
  final _railingLFController = TextEditingController(text: '40');
  final _stepsController = TextEditingController(text: '4');

  String _stainType = 'semi';

  double? _deckSqft;
  double? _totalSqft;
  double? _gallons;
  double? _cleanerGal;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _railingLFController.dispose(); _stepsController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final railingLF = double.tryParse(_railingLFController.text) ?? 0;
    final steps = int.tryParse(_stepsController.text) ?? 0;

    final deckSqft = length * width;

    // Railings: ~4 sqft per linear foot (both sides, spindles)
    final railingSqft = railingLF * 4;

    // Steps: ~6 sqft per step (tread + riser + stringers)
    final stepSqft = steps * 6;

    final totalSqft = deckSqft + railingSqft + stepSqft;

    // Coverage varies by stain type
    double coveragePerGal;
    switch (_stainType) {
      case 'transparent':
        coveragePerGal = 400; // Penetrates more
        break;
      case 'semi':
        coveragePerGal = 300; // Standard
        break;
      case 'solid':
        coveragePerGal = 200; // Thick, 2 coats
        break;
      default:
        coveragePerGal = 300;
    }

    final gallons = totalSqft / coveragePerGal;

    // Deck cleaner: ~150 sqft per gallon
    final cleanerGal = totalSqft / 150;

    setState(() { _deckSqft = deckSqft; _totalSqft = totalSqft; _gallons = gallons; _cleanerGal = cleanerGal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; _railingLFController.text = '40'; _stepsController.text = '4'; setState(() => _stainType = 'semi'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Deck Stain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Deck Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Deck Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Railing Length', unit: 'feet', controller: _railingLFController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Steps', unit: 'qty', controller: _stepsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STAIN NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deck Surface', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_deckSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total (w/ rails, steps)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deck Cleaner', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cleanerGal!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Clean deck 24-48 hrs before staining. Apply when temp 50-90F, no rain 24 hrs.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
    final options = ['transparent', 'semi', 'solid'];
    final labels = {'transparent': 'Transparent', 'semi': 'Semi-Trans', 'solid': 'Solid'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STAIN TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _stainType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _stainType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
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
        _buildTableRow(colors, 'Transparent', 'Shows grain, 1-2 yr'),
        _buildTableRow(colors, 'Semi-transparent', 'Some grain, 2-3 yr'),
        _buildTableRow(colors, 'Solid', 'No grain, 4-5 yr'),
        _buildTableRow(colors, 'Best for new wood', 'Semi or transparent'),
        _buildTableRow(colors, 'Best for old wood', 'Solid color'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
