import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Vapor Barrier Calculator - Under-slab moisture protection
class VaporBarrierScreen extends ConsumerStatefulWidget {
  const VaporBarrierScreen({super.key});
  @override
  ConsumerState<VaporBarrierScreen> createState() => _VaporBarrierScreenState();
}

class _VaporBarrierScreenState extends ConsumerState<VaporBarrierScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');

  String _thickness = '10';
  String _overlap = '6';

  double? _slabArea;
  double? _materialNeeded;
  int? _rollsNeeded;
  int? _tapeRolls;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final overlapInches = int.tryParse(_overlap) ?? 6;

    if (length == null || width == null) {
      setState(() { _slabArea = null; _materialNeeded = null; _rollsNeeded = null; _tapeRolls = null; });
      return;
    }

    final slabArea = length * width;

    // Standard roll sizes vary by thickness
    // 10 mil: 10' x 100' = 1000 sq ft
    // 15 mil: 12' x 100' = 1200 sq ft
    // 20 mil: 12' x 60' = 720 sq ft
    double rollCoverage;
    double rollWidth;
    switch (_thickness) {
      case '6': rollCoverage = 1000; rollWidth = 10; break;
      case '10': rollCoverage = 1000; rollWidth = 10; break;
      case '15': rollCoverage = 1200; rollWidth = 12; break;
      case '20': rollCoverage = 720; rollWidth = 12; break;
      default: rollCoverage = 1000; rollWidth = 10;
    }

    // Calculate overlap waste
    final overlapFeet = overlapInches / 12;
    final stripsNeeded = (width / (rollWidth - overlapFeet)).ceil();
    final overlapWaste = stripsNeeded * length * overlapFeet;

    // Add turnup at walls (12" typical)
    final perimeter = (length + width) * 2;
    final turnupArea = perimeter * 1; // 1 foot turnup

    final materialNeeded = slabArea + overlapWaste + turnupArea;
    final rollsNeeded = (materialNeeded / rollCoverage).ceil();

    // Tape: seams every roll width, plus perimeter
    final seamLength = stripsNeeded * length + perimeter;
    final tapeRolls = (seamLength / 180).ceil(); // 180 LF per tape roll typical

    setState(() { _slabArea = slabArea; _materialNeeded = materialNeeded; _rollsNeeded = rollsNeeded; _tapeRolls = tapeRolls; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; setState(() { _thickness = '10'; _overlap = '6'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Vapor Barrier', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'THICKNESS (MIL)', ['6', '10', '15', '20'], _thickness, (v) { setState(() => _thickness = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'OVERLAP', ['6', '12', '18', '24'], _overlap, (v) { setState(() => _overlap = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rollsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROLLS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rollsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slab Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_slabArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_materialNeeded!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Seam Tape Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tapeRolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('ASTM E1745 Class A/B/C. Min 10 mil for residential, 15 mil for commercial. Tape all seams and penetrations.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
