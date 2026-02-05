import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rain Garden Calculator - Size for runoff infiltration
class RainGardenScreen extends ConsumerStatefulWidget {
  const RainGardenScreen({super.key});
  @override
  ConsumerState<RainGardenScreen> createState() => _RainGardenScreenState();
}

class _RainGardenScreenState extends ConsumerState<RainGardenScreen> {
  final _roofAreaController = TextEditingController(text: '1500');
  final _pavedAreaController = TextEditingController(text: '500');

  String _soilType = 'clay';

  double? _gardenSqFt;
  double? _depth;
  double? _soilCuYd;
  int? _plants;

  @override
  void dispose() { _roofAreaController.dispose(); _pavedAreaController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 1500;
    final pavedArea = double.tryParse(_pavedAreaController.text) ?? 500;

    // Total impervious area
    final totalImpervious = roofArea + pavedArea;

    // Garden size based on soil drainage
    // Sandy: 20% of drainage area
    // Loam: 30% of drainage area
    // Clay: 40% of drainage area
    double sizeFactor;
    double depth;
    switch (_soilType) {
      case 'sandy':
        sizeFactor = 0.20;
        depth = 4; // inches
        break;
      case 'loam':
        sizeFactor = 0.30;
        depth = 6;
        break;
      case 'clay':
        sizeFactor = 0.40;
        depth = 8;
        break;
      default:
        sizeFactor = 0.30;
        depth = 6;
    }

    final gardenSqFt = totalImpervious * sizeFactor;

    // Soil amendment: rain garden mix fills the basin
    final soilCuFt = gardenSqFt * (depth / 12);
    final soilCuYd = soilCuFt / 27;

    // Plants: 1 per sq ft on average
    final plants = gardenSqFt.ceil();

    setState(() {
      _gardenSqFt = gardenSqFt;
      _depth = depth;
      _soilCuYd = soilCuYd;
      _plants = plants;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '1500'; _pavedAreaController.text = '500'; setState(() { _soilType = 'clay'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rain Garden', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'NATIVE SOIL TYPE', ['sandy', 'loam', 'clay'], _soilType, {'sandy': 'Sandy', 'loam': 'Loam', 'clay': 'Clay'}, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Drainage Area', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Paved Area Draining', unit: 'sq ft', controller: _pavedAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Locate 10\' from foundation, in full/part sun, on a natural slope.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_gardenSqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GARDEN SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gardenSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Basin depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_depth!.toStringAsFixed(0)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rain garden mix', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plants (native)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_plants', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlantList(colors),
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

  Widget _buildPlantList(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NATIVE PLANTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Sedges', 'Basin bottom'),
        _buildTableRow(colors, 'Joe Pye Weed', 'Middle zone'),
        _buildTableRow(colors, 'Black-eyed Susan', 'Edge/middle'),
        _buildTableRow(colors, 'Switchgrass', 'Edge'),
        _buildTableRow(colors, 'Native asters', 'Edge'),
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
