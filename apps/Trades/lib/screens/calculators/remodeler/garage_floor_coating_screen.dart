import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Garage Floor Coating Calculator - Garage floor coating material estimation
class GarageFloorCoatingScreen extends ConsumerStatefulWidget {
  const GarageFloorCoatingScreen({super.key});
  @override
  ConsumerState<GarageFloorCoatingScreen> createState() => _GarageFloorCoatingScreenState();
}

class _GarageFloorCoatingScreenState extends ConsumerState<GarageFloorCoatingScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '20');

  String _garageSize = '2car';
  String _coatingType = 'epoxy';

  double? _totalSqft;
  double? _coatingGallons;
  double? _etcherGallons;
  double? _flakeLbs;
  int? _kitCount;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 20;
    final totalSqft = length * width;

    // Coverage rates
    double coatingCoverage;
    bool needsFlake;
    switch (_coatingType) {
      case 'epoxy':
        coatingCoverage = 250; // DIY epoxy kits
        needsFlake = true;
        break;
      case 'polyurea':
        coatingCoverage = 200; // Polyurea/polyaspartic
        needsFlake = true;
        break;
      case 'paint':
        coatingCoverage = 400; // Garage floor paint
        needsFlake = false;
        break;
      case 'sealer':
        coatingCoverage = 300; // Concrete sealer
        needsFlake = false;
        break;
      default:
        coatingCoverage = 250;
        needsFlake = true;
    }

    // Calculate materials
    final coatingGallons = (totalSqft / coatingCoverage) * 1.1; // +10% waste
    final etcherGallons = totalSqft / 250; // Acid etcher coverage
    final flakeLbs = needsFlake ? totalSqft * 0.25 : 0.0; // Medium flake coverage

    // DIY kits typically cover 250-500 sq ft
    final kitCoverage = _coatingType == 'paint' ? 500.0 : 250.0;
    final kitCount = (totalSqft / kitCoverage).ceil();

    setState(() {
      _totalSqft = totalSqft;
      _coatingGallons = coatingGallons;
      _etcherGallons = etcherGallons;
      _flakeLbs = flakeLbs;
      _kitCount = kitCount;
    });
  }

  void _updateFromPreset(String preset) {
    switch (preset) {
      case '1car':
        _lengthController.text = '12';
        _widthController.text = '20';
        break;
      case '2car':
        _lengthController.text = '20';
        _widthController.text = '20';
        break;
      case '3car':
        _lengthController.text = '30';
        _widthController.text = '20';
        break;
    }
    setState(() => _garageSize = preset);
    _calculate();
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '20'; setState(() { _garageSize = '2car'; _coatingType = 'epoxy'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Garage Floor Coating', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GARAGE SIZE', ['1car', '2car', '3car'], _garageSize, {'1car': '1-Car', '2car': '2-Car', '3car': '3-Car'}, _updateFromPreset),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COATING TYPE', ['epoxy', 'polyurea', 'paint', 'sealer'], _coatingType, {'epoxy': 'Epoxy', 'polyurea': 'Polyurea', 'paint': 'Paint', 'sealer': 'Sealer'}, (v) { setState(() => _coatingType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('KITS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_kitCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Area', style: TextStyle(color: colors.textTertiary, fontSize: 12)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 12))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coating', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coatingGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete Etcher', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_etcherGallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_flakeLbs! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Decorative Flake', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_flakeLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Prep is critical: clean oil stains, etch or grind concrete, ensure dry surface. Temp 50-90°F.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildComparisonTable(colors),
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

  Widget _buildComparisonTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COATING COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Epoxy', '5-10 yr, moderate cost'),
        _buildTableRow(colors, 'Polyurea', '15+ yr, premium cost'),
        _buildTableRow(colors, 'Paint', '2-3 yr, low cost'),
        _buildTableRow(colors, 'Sealer', '1-3 yr, lowest cost'),
        _buildTableRow(colors, 'Cure time', '24-72 hrs walk'),
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
