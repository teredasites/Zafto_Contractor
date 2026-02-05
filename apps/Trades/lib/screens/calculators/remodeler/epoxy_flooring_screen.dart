import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Epoxy Flooring Calculator - Epoxy floor coating material estimation
class EpoxyFlooringScreen extends ConsumerStatefulWidget {
  const EpoxyFlooringScreen({super.key});
  @override
  ConsumerState<EpoxyFlooringScreen> createState() => _EpoxyFlooringScreenState();
}

class _EpoxyFlooringScreenState extends ConsumerState<EpoxyFlooringScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '20');

  String _coatType = 'standard';
  String _finish = 'solid';

  double? _totalSqft;
  double? _primerGallons;
  double? _baseCoatGallons;
  double? _topCoatGallons;
  double? _totalGallons;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 20;
    final totalSqft = length * width;

    // Coverage rates vary by product (sq ft per gallon)
    double primerCoverage;
    double baseCoverage;
    double topCoverage;

    switch (_coatType) {
      case 'standard':
        primerCoverage = 300; // Standard primer
        baseCoverage = 200; // 100% solids base
        topCoverage = 300; // Clear top
        break;
      case 'commercial':
        primerCoverage = 250; // Thicker primer
        baseCoverage = 150; // Thicker base
        topCoverage = 250; // UV resistant top
        break;
      case 'industrial':
        primerCoverage = 200; // Heavy duty primer
        baseCoverage = 125; // High build base
        topCoverage = 200; // Chemical resistant top
        break;
      default:
        primerCoverage = 300;
        baseCoverage = 200;
        topCoverage = 300;
    }

    // Calculate gallons needed (add 10% waste)
    final primerGallons = (totalSqft / primerCoverage) * 1.1;
    final baseCoatGallons = (totalSqft / baseCoverage) * 1.1;

    // Metallic and flake finishes need extra topcoat
    double topCoatMultiplier = 1.0;
    if (_finish == 'metallic') topCoatMultiplier = 1.5;
    if (_finish == 'flake') topCoatMultiplier = 1.3;
    final topCoatGallons = (totalSqft / topCoverage) * 1.1 * topCoatMultiplier;

    final totalGallons = primerGallons + baseCoatGallons + topCoatGallons;

    setState(() {
      _totalSqft = totalSqft;
      _primerGallons = primerGallons;
      _baseCoatGallons = baseCoatGallons;
      _topCoatGallons = topCoatGallons;
      _totalGallons = totalGallons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '20'; setState(() { _coatType = 'standard'; _finish = 'solid'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Epoxy Flooring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'COATING TYPE', ['standard', 'commercial', 'industrial'], _coatType, {'standard': 'Standard', 'commercial': 'Commercial', 'industrial': 'Industrial'}, (v) { setState(() => _coatType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FINISH', ['solid', 'flake', 'metallic'], _finish, {'solid': 'Solid Color', 'flake': 'Flake/Chip', 'metallic': 'Metallic'}, (v) { setState(() => _finish = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalGallons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL EPOXY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Area', style: TextStyle(color: colors.textTertiary, fontSize: 12)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 12))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Primer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_primerGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Coat', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseCoatGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Top Coat / Clear', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_topCoatGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Surface must be clean, dry, and properly prepared. Temperature 50-90°F. Includes 10% waste factor.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCoverageTable(colors),
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

  Widget _buildCoverageTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL COVERAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Primer', '250-350 sf/gal'),
        _buildTableRow(colors, 'Base coat', '125-200 sf/gal'),
        _buildTableRow(colors, 'Top coat', '200-300 sf/gal'),
        _buildTableRow(colors, 'Cure time', '24-72 hrs'),
        _buildTableRow(colors, 'Full cure', '7 days'),
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
