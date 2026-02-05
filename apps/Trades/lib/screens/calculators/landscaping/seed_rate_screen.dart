import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grass Seed Rate Calculator - Seeding rates by grass type
class SeedRateScreen extends ConsumerStatefulWidget {
  const SeedRateScreen({super.key});
  @override
  ConsumerState<SeedRateScreen> createState() => _SeedRateScreenState();
}

class _SeedRateScreenState extends ConsumerState<SeedRateScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _grassType = 'fescue';
  String _application = 'new';

  double? _seedLbs;
  double? _bagsNeeded;
  String? _bagSize;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    // Seeding rates (lbs per 1000 sq ft)
    double ratePerK;
    String bagSize;
    switch (_grassType) {
      case 'fescue':
        ratePerK = _application == 'new' ? 8 : 4;
        bagSize = '50 lb';
        break;
      case 'bluegrass':
        ratePerK = _application == 'new' ? 3 : 1.5;
        bagSize = '25 lb';
        break;
      case 'rye':
        ratePerK = _application == 'new' ? 8 : 4;
        bagSize = '50 lb';
        break;
      case 'bermuda':
        ratePerK = _application == 'new' ? 2 : 1;
        bagSize = '25 lb';
        break;
      default:
        ratePerK = 6;
        bagSize = '50 lb';
    }

    final totalLbs = (area / 1000) * ratePerK;
    final bagSizeLbs = bagSize == '50 lb' ? 50.0 : 25.0;
    final bags = totalLbs / bagSizeLbs;

    setState(() {
      _seedLbs = totalLbs;
      _bagsNeeded = bags;
      _bagSize = bagSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _grassType = 'fescue'; _application = 'new'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grass Seed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GRASS TYPE', ['fescue', 'bluegrass', 'rye', 'bermuda'], _grassType, {'fescue': 'Fescue', 'bluegrass': 'Bluegrass', 'rye': 'Ryegrass', 'bermuda': 'Bermuda'}, (v) { setState(() => _grassType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'APPLICATION', ['new', 'overseed'], _application, {'new': 'New Lawn', 'overseed': 'Overseed'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_seedLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SEED NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_seedLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$_bagSize bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bagsNeeded!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSeedGuide(colors),
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

  Widget _buildSeedGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SEEDING RATES (per 1000 sq ft)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Tall Fescue', '6-8 lbs new'),
        _buildTableRow(colors, 'Kentucky Bluegrass', '2-3 lbs new'),
        _buildTableRow(colors, 'Perennial Rye', '8-10 lbs new'),
        _buildTableRow(colors, 'Bermuda', '1-2 lbs new'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
