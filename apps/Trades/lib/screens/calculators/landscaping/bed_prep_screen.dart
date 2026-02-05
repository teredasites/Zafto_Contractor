import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bed Prep Calculator - Amendments for new beds
class BedPrepScreen extends ConsumerStatefulWidget {
  const BedPrepScreen({super.key});
  @override
  ConsumerState<BedPrepScreen> createState() => _BedPrepScreenState();
}

class _BedPrepScreenState extends ConsumerState<BedPrepScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '5');

  String _soilType = 'clay';

  double? _areaSqFt;
  double? _compostCuYd;
  double? _peatCuYd;
  double? _sandCuYd;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final width = double.tryParse(_widthController.text) ?? 5;

    final area = length * width;

    // Amendments based on soil type (inches to add, then convert to cu yd)
    double compostInches;
    double peatInches;
    double sandInches;

    switch (_soilType) {
      case 'clay':
        compostInches = 4;
        peatInches = 2;
        sandInches = 2;
        break;
      case 'sandy':
        compostInches = 4;
        peatInches = 2;
        sandInches = 0;
        break;
      case 'loam':
        compostInches = 2;
        peatInches = 0;
        sandInches = 0;
        break;
      default:
        compostInches = 3;
        peatInches = 1;
        sandInches = 1;
    }

    final compostCuFt = area * (compostInches / 12);
    final peatCuFt = area * (peatInches / 12);
    final sandCuFt = area * (sandInches / 12);

    setState(() {
      _areaSqFt = area;
      _compostCuYd = compostCuFt / 27;
      _peatCuYd = peatCuFt / 27;
      _sandCuYd = sandCuFt / 27;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '5'; setState(() { _soilType = 'clay'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bed Prep', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EXISTING SOIL TYPE', ['clay', 'sandy', 'loam'], _soilType, {'clay': 'Clay', 'sandy': 'Sandy', 'loam': 'Loam'}, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bed Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_areaSqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BED AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text('AMENDMENTS NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_compostCuYd! > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Compost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_compostCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_compostCuYd! > 0) const SizedBox(height: 8),
                if (_peatCuYd! > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Peat moss', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_peatCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_peatCuYd! > 0) const SizedBox(height: 8),
                if (_sandCuYd! > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coarse sand', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSoilGuide(colors),
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

  Widget _buildSoilGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SOIL IMPROVEMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Clay soil', 'Add compost, sand, peat'),
        _buildTableRow(colors, 'Sandy soil', 'Add compost, peat'),
        _buildTableRow(colors, 'Loam soil', 'Light compost topdress'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'Till depth', '8-12" deep'),
        _buildTableRow(colors, 'Mix ratio', 'Equal parts amendments'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
