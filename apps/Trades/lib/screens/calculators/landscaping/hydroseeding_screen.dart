import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hydroseeding Calculator - Material estimates
class HydroseedingScreen extends ConsumerStatefulWidget {
  const HydroseedingScreen({super.key});
  @override
  ConsumerState<HydroseedingScreen> createState() => _HydroseedingScreenState();
}

class _HydroseedingScreenState extends ConsumerState<HydroseedingScreen> {
  final _areaController = TextEditingController(text: '10000');

  String _application = 'lawn';

  double? _seedLbs;
  double? _mulchLbs;
  double? _fertilizerLbs;
  double? _tackifierGal;
  int? _tankLoads;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 10000;

    // Rates per 1000 sq ft
    double seedRate;
    double mulchRate;
    switch (_application) {
      case 'lawn':
        seedRate = 5; // lbs/1000
        mulchRate = 50; // lbs/1000 wood fiber
        break;
      case 'erosion':
        seedRate = 8;
        mulchRate = 75;
        break;
      case 'wildflower':
        seedRate = 2;
        mulchRate = 40;
        break;
      default:
        seedRate = 5;
        mulchRate = 50;
    }

    final areaK = area / 1000;
    final seed = areaK * seedRate;
    final mulch = areaK * mulchRate;
    final fertilizer = areaK * 10; // 10 lbs starter fert per K
    final tackifier = areaK * 0.5; // 0.5 gal per K

    // Tank loads (500 gal tank covers ~5000 sq ft typically)
    final tanks = (area / 5000).ceil();

    setState(() {
      _seedLbs = seed;
      _mulchLbs = mulch;
      _fertilizerLbs = fertilizer;
      _tackifierGal = tackifier;
      _tankLoads = tanks;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '10000'; setState(() { _application = 'lawn'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Hydroseeding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['lawn', 'erosion', 'wildflower'], _application, {'lawn': 'Lawn', 'erosion': 'Erosion', 'wildflower': 'Wildflower'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_seedLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TANK LOADS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tankLoads', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Text('(500 gal tank)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildMaterialRow(colors, 'Seed', '${_seedLbs!.toStringAsFixed(1)} lbs'),
                _buildMaterialRow(colors, 'Wood fiber mulch', '${_mulchLbs!.toStringAsFixed(0)} lbs'),
                _buildMaterialRow(colors, 'Starter fertilizer', '${_fertilizerLbs!.toStringAsFixed(0)} lbs'),
                _buildMaterialRow(colors, 'Tackifier', '${_tackifierGal!.toStringAsFixed(1)} gal'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildHydroGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
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

  Widget _buildHydroGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HYDROSEEDING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildMaterialRow(colors, 'Watering', '2-3× daily, 2 weeks'),
        _buildMaterialRow(colors, 'First mow', '3-4" height'),
        _buildMaterialRow(colors, 'Best temp', '50-80°F'),
        _buildMaterialRow(colors, 'Germination', '5-21 days'),
      ]),
    );
  }
}
