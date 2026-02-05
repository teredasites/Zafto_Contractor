import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Metallic Epoxy Calculator - Metallic epoxy pigment and clear coat estimation
class MetallicEpoxyScreen extends ConsumerStatefulWidget {
  const MetallicEpoxyScreen({super.key});
  @override
  ConsumerState<MetallicEpoxyScreen> createState() => _MetallicEpoxyScreenState();
}

class _MetallicEpoxyScreenState extends ConsumerState<MetallicEpoxyScreen> {
  final _sqftController = TextEditingController(text: '400');

  String _technique = 'standard';
  int _colorCount = 1;

  double? _baseGallons;
  double? _pigmentOz;
  double? _clearGallons;
  double? _totalGallons;

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text) ?? 400;

    // Metallic epoxy coverage (typically 80-100 sf/gal for base)
    double baseCoverage = 90; // sq ft per gallon
    double clearCoverage = 200; // Clear coat covers more

    // Technique affects material usage
    double techniqueMultiplier = 1.0;
    switch (_technique) {
      case 'standard':
        techniqueMultiplier = 1.0;
        break;
      case 'manipulated':
        techniqueMultiplier = 1.2; // More product for effects
        break;
      case 'lava':
        techniqueMultiplier = 1.4; // Heavy manipulation
        break;
    }

    // Calculate materials
    final baseGallons = (sqft / baseCoverage) * techniqueMultiplier * 1.1; // +10% waste

    // Pigment: typically 4-8 oz per gallon of epoxy
    final ozPerGallon = 6.0; // Average
    final pigmentOz = baseGallons * ozPerGallon * _colorCount;

    // Clear coat: 2 coats recommended for metallic
    final clearGallons = (sqft / clearCoverage) * 2 * 1.1;

    final totalGallons = baseGallons + clearGallons;

    setState(() {
      _baseGallons = baseGallons;
      _pigmentOz = pigmentOz;
      _clearGallons = clearGallons;
      _totalGallons = totalGallons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '400'; setState(() { _technique = 'standard'; _colorCount = 1; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Metallic Epoxy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TECHNIQUE', ['standard', 'manipulated', 'lava'], _technique, {'standard': 'Standard', 'manipulated': 'Manipulated', 'lava': 'Lava Flow'}, (v) { setState(() => _technique = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COLORS', ['1', '2', '3'], _colorCount.toString(), {'1': '1 Color', '2': '2 Colors', '3': '3 Colors'}, (v) { setState(() => _colorCount = int.parse(v)); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Floor Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalGallons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL EPOXY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Metallic Base', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Metallic Pigment', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pigmentOz!.toStringAsFixed(0)} oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Clear Top Coat (2x)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_clearGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Metallic epoxy requires fast application. Practice technique first. Two clear coats protect the finish.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTechniqueTable(colors),
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

  Widget _buildTechniqueTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('METALLIC TECHNIQUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard', 'Pour and spread'),
        _buildTableRow(colors, 'Manipulated', 'Leaf blower effects'),
        _buildTableRow(colors, 'Lava flow', 'Heavy movement'),
        _buildTableRow(colors, 'Pigment ratio', '4-8 oz/gal'),
        _buildTableRow(colors, 'Pot life', '20-40 min'),
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
