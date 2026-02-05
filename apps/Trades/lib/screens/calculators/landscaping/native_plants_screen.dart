import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Native Plants Calculator - Planting density for restoration
class NativePlantsScreen extends ConsumerStatefulWidget {
  const NativePlantsScreen({super.key});
  @override
  ConsumerState<NativePlantsScreen> createState() => _NativePlantsScreenState();
}

class _NativePlantsScreenState extends ConsumerState<NativePlantsScreen> {
  final _areaController = TextEditingController(text: '500');

  String _habitatType = 'meadow';

  int? _plugsNeeded;
  double? _seedLbs;
  double? _plugsPerSqFt;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 500;

    // Native planting densities vary by habitat type
    double plugsPerSqFt;
    double seedPerAcre;
    switch (_habitatType) {
      case 'meadow':
        plugsPerSqFt = 0.25; // 1 plug per 4 sq ft
        seedPerAcre = 10; // lbs
        break;
      case 'prairie':
        plugsPerSqFt = 0.2; // 1 plug per 5 sq ft
        seedPerAcre = 8;
        break;
      case 'woodland':
        plugsPerSqFt = 0.15; // 1 plug per ~7 sq ft
        seedPerAcre = 5;
        break;
      case 'rain_garden':
        plugsPerSqFt = 0.5; // 1 plug per 2 sq ft (denser)
        seedPerAcre = 15;
        break;
      default:
        plugsPerSqFt = 0.25;
        seedPerAcre = 10;
    }

    final plugs = (area * plugsPerSqFt).ceil();
    final acres = area / 43560;
    final seedLbs = acres * seedPerAcre;

    setState(() {
      _plugsNeeded = plugs;
      _seedLbs = seedLbs;
      _plugsPerSqFt = plugsPerSqFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '500'; setState(() { _habitatType = 'meadow'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Native Plants', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HABITAT TYPE', ['meadow', 'prairie', 'woodland', 'rain_garden'], _habitatType, {'meadow': 'Meadow', 'prairie': 'Prairie', 'woodland': 'Woodland', 'rain_garden': 'Rain Garden'}, (v) { setState(() => _habitatType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Planting Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_plugsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PLUGS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plugsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Density', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_plugsPerSqFt!.toStringAsFixed(2)} per sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Alt: seed mix', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_seedLbs!.toStringAsFixed(3)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildNativeGuide(colors),
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

  Widget _buildNativeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLANTING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Species mix', '5-15 species'),
        _buildTableRow(colors, 'Forbs:Grasses', '70:30 ratio'),
        _buildTableRow(colors, 'Best time', 'Fall or early spring'),
        _buildTableRow(colors, 'Establishment', '2-3 years'),
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
