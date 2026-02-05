import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gravel Base Calculator - Sub-base material for slabs
class GravelBaseScreen extends ConsumerStatefulWidget {
  const GravelBaseScreen({super.key});
  @override
  ConsumerState<GravelBaseScreen> createState() => _GravelBaseScreenState();
}

class _GravelBaseScreenState extends ConsumerState<GravelBaseScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _depthController = TextEditingController(text: '4');

  String _material = 'crushed';

  double? _area;
  double? _cubicYards;
  double? _tons;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depthInches = double.tryParse(_depthController.text);

    if (length == null || width == null || depthInches == null) {
      setState(() { _area = null; _cubicYards = null; _tons = null; });
      return;
    }

    final area = length * width;
    final depthFeet = depthInches / 12;
    final cubicFeet = area * depthFeet;
    final cubicYards = cubicFeet / 27;

    // Tons per cubic yard varies by material
    double tonsPerYard;
    switch (_material) {
      case 'crushed': tonsPerYard = 1.4; break;  // Crushed stone
      case 'pea': tonsPerYard = 1.35; break;     // Pea gravel
      case 'road': tonsPerYard = 1.5; break;     // Road base (crusher run)
      case 'sand': tonsPerYard = 1.3; break;     // Sand
      default: tonsPerYard = 1.4;
    }

    // Add 10% for compaction loss
    final tons = cubicYards * tonsPerYard * 1.1;

    setState(() { _area = area; _cubicYards = cubicYards; _tons = tons; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; _depthController.text = '4'; setState(() => _material = 'crushed'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gravel Base', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL TYPE', ['crushed', 'pea', 'road', 'sand'], _material, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MATERIAL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_area!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cubicYards!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getMaterialNote() {
    switch (_material) {
      case 'crushed': return 'Crushed stone (3/4" minus) compacts well. Ideal for slab sub-base.';
      case 'pea': return 'Pea gravel drains well but doesn\'t compact. Use with geotextile fabric.';
      case 'road': return 'Crusher run (road base) has fines that lock together when compacted.';
      case 'sand': return 'Sand for bedding pavers or leveling. Compact in 2" lifts.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'crushed': 'Crushed', 'pea': 'Pea', 'road': 'Road Base', 'sand': 'Sand'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
