import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trim Paint Calculator - Trim/molding paint estimation
class TrimPaintScreen extends ConsumerStatefulWidget {
  const TrimPaintScreen({super.key});
  @override
  ConsumerState<TrimPaintScreen> createState() => _TrimPaintScreenState();
}

class _TrimPaintScreenState extends ConsumerState<TrimPaintScreen> {
  final _baseboardLFController = TextEditingController(text: '100');
  final _casingLFController = TextEditingController(text: '80');
  final _crownLFController = TextEditingController(text: '50');

  String _finish = 'semigloss';
  String _coats = '2';

  double? _totalSqft;
  double? _quarts;
  double? _gallons;

  @override
  void dispose() { _baseboardLFController.dispose(); _casingLFController.dispose(); _crownLFController.dispose(); super.dispose(); }

  void _calculate() {
    final baseboardLF = double.tryParse(_baseboardLFController.text) ?? 0;
    final casingLF = double.tryParse(_casingLFController.text) ?? 0;
    final crownLF = double.tryParse(_crownLFController.text) ?? 0;
    final coats = int.tryParse(_coats) ?? 2;

    // Convert linear feet to square feet
    // Baseboard: ~4" = 0.33 sqft/lf
    // Casing: ~3" = 0.25 sqft/lf
    // Crown: ~4.5" = 0.375 sqft/lf
    final baseboardSqft = baseboardLF * 0.33;
    final casingSqft = casingLF * 0.25;
    final crownSqft = crownLF * 0.375;

    final totalSqft = baseboardSqft + casingSqft + crownSqft;

    // Coverage: trim paint ~100 sqft per quart (thicker, slower application)
    final sqftPerCoat = totalSqft;
    final totalSqftAllCoats = sqftPerCoat * coats;

    final quarts = totalSqftAllCoats / 100;
    final gallons = quarts / 4;

    setState(() { _totalSqft = totalSqft; _quarts = quarts; _gallons = gallons; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _baseboardLFController.text = '100'; _casingLFController.text = '80'; _crownLFController.text = '50'; setState(() { _finish = 'semigloss'; _coats = '2'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trim Paint', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FINISH', ['satin', 'semigloss', 'gloss'], _finish, {'satin': 'Satin', 'semigloss': 'Semi-Gloss', 'gloss': 'High Gloss'}, (v) { setState(() => _finish = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COATS', ['1', '2', '3'], _coats, {'1': '1 Coat', '2': '2 Coats', '3': '3 Coats'}, (v) { setState(() => _coats = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Baseboard', unit: 'linear ft', controller: _baseboardLFController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Door/Window Casing', unit: 'linear ft', controller: _casingLFController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Crown Molding', unit: 'linear ft', controller: _crownLFController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PAINT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_quarts!.toStringAsFixed(1)} qts', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Surface Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gallons', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(2)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Semi-gloss is standard for trim. Sand between coats with 220 grit. Use angled brush for detail.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFinishTable(colors),
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

  Widget _buildFinishTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRIM FINISH GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Satin', 'Low sheen, hides flaws'),
        _buildTableRow(colors, 'Semi-gloss', 'Standard, washable'),
        _buildTableRow(colors, 'High gloss', 'Most durable, shows all'),
        _buildTableRow(colors, 'Alkyd/oil', 'Smoothest, slow dry'),
        _buildTableRow(colors, 'Latex/acrylic', 'Easy cleanup, fast dry'),
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
