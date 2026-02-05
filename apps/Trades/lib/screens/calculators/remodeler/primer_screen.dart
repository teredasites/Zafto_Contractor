import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Primer Calculator - Primer/sealer estimation
class PrimerScreen extends ConsumerStatefulWidget {
  const PrimerScreen({super.key});
  @override
  ConsumerState<PrimerScreen> createState() => _PrimerScreenState();
}

class _PrimerScreenState extends ConsumerState<PrimerScreen> {
  final _areaSqftController = TextEditingController(text: '400');

  String _type = 'pva';
  String _surface = 'drywall';

  double? _gallons;
  double? _coverage;

  @override
  void dispose() { _areaSqftController.dispose(); super.dispose(); }

  void _calculate() {
    final areaSqft = double.tryParse(_areaSqftController.text) ?? 0;

    // Coverage varies by primer type and surface
    double coveragePerGal;
    switch (_type) {
      case 'pva':
        coveragePerGal = _surface == 'drywall' ? 400 : 350;
        break;
      case 'shellac':
        coveragePerGal = 350;
        break;
      case 'oilbased':
        coveragePerGal = 375;
        break;
      case 'bonding':
        coveragePerGal = 300;
        break;
      default:
        coveragePerGal = 400;
    }

    // Porous surfaces need more primer
    if (_surface == 'bare' || _surface == 'masonry') {
      coveragePerGal *= 0.75;
    }

    final gallons = areaSqft / coveragePerGal;

    setState(() { _gallons = gallons; _coverage = coveragePerGal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaSqftController.text = '400'; setState(() { _type = 'pva'; _surface = 'drywall'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Primer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PRIMER TYPE', ['pva', 'shellac', 'oilbased', 'bonding'], _type, {'pva': 'PVA', 'shellac': 'Shellac', 'oilbased': 'Oil-Based', 'bonding': 'Bonding'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SURFACE', ['drywall', 'painted', 'bare', 'masonry'], _surface, {'drywall': 'New Drywall', 'painted': 'Painted', 'bare': 'Bare Wood', 'masonry': 'Masonry'}, (v) { setState(() => _surface = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Prime', unit: 'sq ft', controller: _areaSqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PRIMER NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverage!.toStringAsFixed(0)} sqft/gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getPrimerTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getPrimerTip() {
    switch (_type) {
      case 'shellac':
        return 'Shellac blocks stains, odors. Use for water damage, smoke damage, knots.';
      case 'oilbased':
        return 'Best for bare wood, tannin bleed. Long dry time, strong odor.';
      case 'bonding':
        return 'Adheres to slick surfaces: tile, laminate, glossy paint.';
      default:
        return 'PVA is ideal for new drywall. Seals paper and joint compound.';
    }
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

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRIMER SELECTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'New drywall', 'PVA or latex'),
        _buildTableRow(colors, 'Stain blocking', 'Shellac or oil'),
        _buildTableRow(colors, 'Slick surfaces', 'Bonding primer'),
        _buildTableRow(colors, 'Exterior wood', 'Oil-based'),
        _buildTableRow(colors, 'Color change', 'Tinted primer'),
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
