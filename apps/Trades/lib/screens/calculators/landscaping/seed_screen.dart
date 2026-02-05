import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Seed Calculator - Lbs per 1000 sq ft
class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});
  @override
  ConsumerState<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _grassType = 'fescue';
  String _application = 'new';

  double? _seedLbs;
  int? _bags5lb;
  int? _bags25lb;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    // Seeding rates (lbs per 1000 sq ft)
    double newRate;
    double overseedRate;
    switch (_grassType) {
      case 'fescue':
        newRate = 8;
        overseedRate = 4;
        break;
      case 'bluegrass':
        newRate = 3;
        overseedRate = 1.5;
        break;
      case 'rye':
        newRate = 10;
        overseedRate = 5;
        break;
      case 'bermuda':
        newRate = 2;
        overseedRate = 1;
        break;
      case 'zoysia':
        newRate = 2;
        overseedRate = 1;
        break;
      default:
        newRate = 8;
        overseedRate = 4;
    }

    final rate = _application == 'new' ? newRate : overseedRate;
    final seedLbs = (area / 1000) * rate;

    setState(() {
      _seedLbs = seedLbs;
      _bags5lb = (seedLbs / 5).ceil();
      _bags25lb = (seedLbs / 25).ceil();
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
        title: Text('Seed Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GRASS TYPE', ['fescue', 'bluegrass', 'rye', 'bermuda', 'zoysia'], _grassType, {'fescue': 'Fescue', 'bluegrass': 'Bluegrass', 'rye': 'Ryegrass', 'bermuda': 'Bermuda', 'zoysia': 'Zoysia'}, (v) { setState(() => _grassType = v); _calculate(); }),
            const SizedBox(height: 16),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('5 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags5lb bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('25 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags25lb bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_application == 'new' ? 'New lawn: Full coverage rate. Rake into top 1/4" of soil.' : 'Overseed: Half rate for existing lawns. Dethatch or aerate first.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRatesTable(colors),
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
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildRatesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SEEDING RATES (per 1000 sq ft)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Tall Fescue', '8 lbs new / 4 lbs over'),
        _buildTableRow(colors, 'Kentucky Blue', '3 lbs new / 1.5 lbs over'),
        _buildTableRow(colors, 'Perennial Rye', '10 lbs new / 5 lbs over'),
        _buildTableRow(colors, 'Bermuda', '2 lbs new / 1 lb over'),
        _buildTableRow(colors, 'Zoysia', '2 lbs new / 1 lb over'),
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
