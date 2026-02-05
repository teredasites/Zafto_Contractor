import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Texture Match Calculator - Wall texture estimation
class TextureMatchScreen extends ConsumerStatefulWidget {
  const TextureMatchScreen({super.key});
  @override
  ConsumerState<TextureMatchScreen> createState() => _TextureMatchScreenState();
}

class _TextureMatchScreenState extends ConsumerState<TextureMatchScreen> {
  final _areaController = TextEditingController(text: '20');

  String _texture = 'orange';
  String _method = 'spray';

  double? _compoundQts;
  double? _primerOz;
  String? _tool;
  String? _technique;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 0;

    // Joint compound needed varies by texture
    double compoundPerSqFt;
    String tool;
    String technique;

    switch (_texture) {
      case 'orange':
        compoundPerSqFt = 0.08; // quarts per sqft
        tool = 'Hopper gun or aerosol';
        technique = 'Light, even passes';
        break;
      case 'knockdown':
        compoundPerSqFt = 0.10;
        tool = 'Hopper gun + knife';
        technique = 'Spray, wait, knock';
        break;
      case 'skip':
        compoundPerSqFt = 0.06;
        tool = 'Curved knife';
        technique = 'Random arcs';
        break;
      case 'smooth':
        compoundPerSqFt = 0.12;
        tool = 'Taping knife 12\"';
        technique = 'Skim coat 2-3x';
        break;
      case 'popcorn':
        compoundPerSqFt = 0.15;
        tool = 'Hopper gun';
        technique = 'Heavy coat';
        break;
      default:
        compoundPerSqFt = 0.08;
        tool = 'Hopper gun';
        technique = 'Light passes';
    }

    final compoundQts = area * compoundPerSqFt;
    final primerOz = area * 0.8; // oz per sqft for primer

    setState(() { _compoundQts = compoundQts; _primerOz = primerOz; _tool = tool; _technique = technique; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '20'; setState(() { _texture = 'orange'; _method = 'spray'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Texture Match', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TEXTURE TYPE', ['orange', 'knockdown', 'skip', 'smooth', 'popcorn'], _texture, {'orange': 'Orange Peel', 'knockdown': 'Knockdown', 'skip': 'Skip Trowel', 'smooth': 'Smooth', 'popcorn': 'Popcorn'}, (v) { setState(() => _texture = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'METHOD', ['spray', 'hand', 'roller'], _method, {'spray': 'Spray', 'hand': 'Hand Apply', 'roller': 'Roller'}, (v) { setState(() => _method = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Texture', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_compoundQts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOOL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_tool!, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joint Compound', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_compoundQts!.toStringAsFixed(1)} qts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Primer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_primerOz!.toStringAsFixed(0)} oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Technique', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_technique!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Practice on cardboard first! Thin compound to pancake batter consistency for spray.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTextureTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildTextureTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TEXTURE DIFFICULTY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Orange peel', 'Easy - aerosol can'),
        _buildTableRow(colors, 'Knockdown', 'Medium - timing key'),
        _buildTableRow(colors, 'Skip trowel', 'Medium - hand skill'),
        _buildTableRow(colors, 'Smooth', 'Hard - multiple coats'),
        _buildTableRow(colors, 'Popcorn', 'Easy - heavy spray'),
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
