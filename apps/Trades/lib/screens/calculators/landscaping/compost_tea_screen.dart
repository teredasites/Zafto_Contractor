import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compost Tea Calculator - Brewing ratios
class CompostTeaScreen extends ConsumerStatefulWidget {
  const CompostTeaScreen({super.key});
  @override
  ConsumerState<CompostTeaScreen> createState() => _CompostTeaScreenState();
}

class _CompostTeaScreenState extends ConsumerState<CompostTeaScreen> {
  final _gallonsController = TextEditingController(text: '5');

  String _brewMethod = 'aerated';

  double? _compostLbs;
  double? _molassesOz;
  int? _brewHours;
  double? _coverageSqFt;

  @override
  void dispose() { _gallonsController.dispose(); super.dispose(); }

  void _calculate() {
    final gallons = double.tryParse(_gallonsController.text) ?? 5;

    // Ratios: 1 lb compost per gallon, 1 oz molasses per gallon
    final compost = gallons * 1;
    final molasses = gallons * 1;

    int brewTime;
    switch (_brewMethod) {
      case 'aerated':
        brewTime = 24; // 24-36 hours with aeration
        break;
      case 'passive':
        brewTime = 72; // 3-7 days without aeration
        break;
      default:
        brewTime = 24;
    }

    // Coverage: 1 gallon covers ~1000 sq ft diluted
    final coverage = gallons * 1000;

    setState(() {
      _compostLbs = compost;
      _molassesOz = molasses;
      _brewHours = brewTime;
      _coverageSqFt = coverage;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _gallonsController.text = '5'; setState(() { _brewMethod = 'aerated'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compost Tea', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BREW METHOD', ['aerated', 'passive'], _brewMethod, {'aerated': 'Aerated (AACT)', 'passive': 'Passive'}, (v) { setState(() => _brewMethod = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Batch Size', unit: 'gal', controller: _gallonsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_compostLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COMPOST NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_compostLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Molasses', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_molassesOz!.toStringAsFixed(1)} oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Brew time', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_brewHours hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage (diluted)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverageSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTeaGuide(colors),
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

  Widget _buildTeaGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BREWING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Water', 'Dechlorinated'),
        _buildTableRow(colors, 'Temperature', '65-75°F ideal'),
        _buildTableRow(colors, 'Dilution', '1:10 for soil drench'),
        _buildTableRow(colors, 'Use within', '4-6 hours'),
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
