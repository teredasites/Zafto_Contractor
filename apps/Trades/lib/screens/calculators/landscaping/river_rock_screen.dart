import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// River Rock Calculator - Decorative rock coverage
class RiverRockScreen extends ConsumerStatefulWidget {
  const RiverRockScreen({super.key});
  @override
  ConsumerState<RiverRockScreen> createState() => _RiverRockScreenState();
}

class _RiverRockScreenState extends ConsumerState<RiverRockScreen> {
  final _areaController = TextEditingController(text: '100');

  String _rockSize = 'medium';
  String _depthIn = '3';

  double? _tonsNeeded;
  double? _bagCount;
  double? _fabricSqFt;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 100;
    final depth = double.tryParse(_depthIn) ?? 3;

    final depthFt = depth / 12;
    final volumeCuFt = area * depthFt;
    final volumeCuYd = volumeCuFt / 27;

    // River rock weight varies by size
    double tonsPerCuYd;
    switch (_rockSize) {
      case 'small': // Pea gravel, 3/8"
        tonsPerCuYd = 1.4;
        break;
      case 'medium': // 1-2"
        tonsPerCuYd = 1.35;
        break;
      case 'large': // 3-5"
        tonsPerCuYd = 1.3;
        break;
      default:
        tonsPerCuYd = 1.35;
    }

    final tons = volumeCuYd * tonsPerCuYd;

    // 50 lb bags cover ~2 sq ft at 2" depth
    final sqFtPerBag = 2 * (2 / depth);
    final bags = area / sqFtPerBag;

    // Landscape fabric
    final fabric = area * 1.1;

    setState(() {
      _tonsNeeded = tons;
      _bagCount = bags;
      _fabricSqFt = fabric;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '100'; setState(() { _rockSize = 'medium'; _depthIn = '3'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('River Rock', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROCK SIZE', ['small', 'medium', 'large'], _rockSize, {'small': 'Pea 3/8\"', 'medium': '1-2\"', 'large': '3-5\"'}, (v) { setState(() => _rockSize = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'DEPTH', ['2', '3', '4'], _depthIn, {'2': '2\"', '3': '3\"', '4': '4\"'}, (v) { setState(() => _depthIn = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tonsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RIVER ROCK', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tonsNeeded!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('50 lb bags (alt)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_bagCount!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landscape fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRockGuide(colors),
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

  Widget _buildRockGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COVERAGE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1 ton covers', '~80-100 sq ft @ 2\"'),
        _buildTableRow(colors, 'Pea gravel', 'Patios, paths'),
        _buildTableRow(colors, 'Medium rock', 'Beds, borders'),
        _buildTableRow(colors, 'Large rock', 'Accent, drainage'),
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
