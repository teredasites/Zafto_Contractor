import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Demo Waste Calculator - Demolition debris estimation
class DemoWasteScreen extends ConsumerStatefulWidget {
  const DemoWasteScreen({super.key});
  @override
  ConsumerState<DemoWasteScreen> createState() => _DemoWasteScreenState();
}

class _DemoWasteScreenState extends ConsumerState<DemoWasteScreen> {
  final _sqftController = TextEditingController(text: '1500');

  String _demoType = 'interior';
  String _building = 'residential';

  double? _cubicYards;
  double? _tons;
  int? _truckLoads;

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text);

    if (sqft == null) {
      setState(() { _cubicYards = null; _tons = null; _truckLoads = null; });
      return;
    }

    // Debris factors (cubic yards per sqft)
    double cyPerSqft;

    switch (_demoType) {
      case 'interior':
        // Gut interior only
        cyPerSqft = _building == 'residential' ? 0.02 : 0.025;
        break;
      case 'full':
        // Complete demolition
        cyPerSqft = _building == 'residential' ? 0.15 : 0.20;
        break;
      case 'selective':
        // Kitchen/bath demo
        cyPerSqft = 0.03;
        break;
      default:
        cyPerSqft = 0.02;
    }

    final cubicYards = sqft * cyPerSqft;

    // Weight: ~300-500 lbs per cubic yard for mixed demo
    final tons = (cubicYards * 400) / 2000;

    // Truck loads (10-15 CY per load typical)
    final truckLoads = (cubicYards / 12).ceil();

    setState(() { _cubicYards = cubicYards; _tons = tons; _truckLoads = truckLoads < 1 ? 1 : truckLoads; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '1500'; setState(() { _demoType = 'interior'; _building = 'residential'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Demo Waste', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BUILDING TYPE', ['residential', 'commercial'], _building, {'residential': 'Residential', 'commercial': 'Commercial'}, (v) { setState(() => _building = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'DEMO SCOPE', ['selective', 'interior', 'full'], _demoType, {'selective': 'Selective', 'interior': 'Interior Gut', 'full': 'Full Demo'}, (v) { setState(() => _demoType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Demo Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cubicYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DEBRIS VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(1)} CY', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Estimated Weight', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Truck Loads (12 CY)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_truckLoads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check for asbestos, lead, and hazmat before demo. Additional disposal fees apply.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDebrisTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDebrisTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DEBRIS WEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mixed debris', '300-500 lbs/CY'),
        _buildTableRow(colors, 'Concrete', '3,000 lbs/CY'),
        _buildTableRow(colors, 'Brick/block', '2,400 lbs/CY'),
        _buildTableRow(colors, 'Drywall', '500 lbs/CY'),
        _buildTableRow(colors, 'Wood/lumber', '300 lbs/CY'),
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
