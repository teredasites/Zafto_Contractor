import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Boulder Weight Calculator - Estimate stone weight
class BoulderWeightScreen extends ConsumerStatefulWidget {
  const BoulderWeightScreen({super.key});
  @override
  ConsumerState<BoulderWeightScreen> createState() => _BoulderWeightScreenState();
}

class _BoulderWeightScreenState extends ConsumerState<BoulderWeightScreen> {
  final _lengthController = TextEditingController(text: '36');
  final _widthController = TextEditingController(text: '24');
  final _heightController = TextEditingController(text: '18');

  String _stoneType = 'granite';

  double? _weightLbs;
  double? _weightTons;
  double? _cubicFeet;
  String? _equipmentNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final lengthIn = double.tryParse(_lengthController.text) ?? 36;
    final widthIn = double.tryParse(_widthController.text) ?? 24;
    final heightIn = double.tryParse(_heightController.text) ?? 18;

    // Volume in cubic feet (adjust for irregular shape ~70%)
    final cubicInches = lengthIn * widthIn * heightIn;
    final cubicFeet = (cubicInches / 1728) * 0.7; // Irregular shape factor

    // Density by stone type (lbs per cubic foot)
    double lbsPerCuFt;
    switch (_stoneType) {
      case 'granite': lbsPerCuFt = 165; break;
      case 'limestone': lbsPerCuFt = 150; break;
      case 'sandstone': lbsPerCuFt = 140; break;
      case 'basalt': lbsPerCuFt = 175; break;
      case 'fieldstone': lbsPerCuFt = 155; break;
      default: lbsPerCuFt = 160;
    }

    final weightLbs = cubicFeet * lbsPerCuFt;
    final weightTons = weightLbs / 2000;

    // Equipment recommendation
    String equipment;
    if (weightLbs < 100) {
      equipment = '2 people can lift';
    } else if (weightLbs < 300) {
      equipment = 'Hand truck or dolly';
    } else if (weightLbs < 1000) {
      equipment = 'Skid steer or mini excavator';
    } else if (weightLbs < 3000) {
      equipment = 'Excavator with thumb';
    } else {
      equipment = 'Large excavator or crane';
    }

    setState(() {
      _weightLbs = weightLbs;
      _weightTons = weightTons;
      _cubicFeet = cubicFeet;
      _equipmentNeeded = equipment;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '36'; _widthController.text = '24'; _heightController.text = '18'; setState(() { _stoneType = 'granite'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Boulder Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STONE TYPE', ['granite', 'limestone', 'sandstone', 'basalt', 'fieldstone'], _stoneType, {'granite': 'Granite', 'limestone': 'Limestone', 'sandstone': 'Sandstone', 'basalt': 'Basalt', 'fieldstone': 'Field'}, (v) { setState(() => _stoneType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'in', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'in', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_weightLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. WEIGHT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weightLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weight in tons', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weightTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume (approx)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicFeet!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(LucideIcons.truck, color: colors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_equipmentNeeded!, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDensityChart(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDensityChart(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STONE DENSITIES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Granite', '~165 lbs/cu ft'),
        _buildTableRow(colors, 'Basalt', '~175 lbs/cu ft'),
        _buildTableRow(colors, 'Limestone', '~150 lbs/cu ft'),
        _buildTableRow(colors, 'Sandstone', '~140 lbs/cu ft'),
        _buildTableRow(colors, 'Fieldstone', '~155 lbs/cu ft'),
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
