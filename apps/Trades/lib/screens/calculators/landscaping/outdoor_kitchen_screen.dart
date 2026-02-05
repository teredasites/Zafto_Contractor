import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Outdoor Kitchen Calculator - Block count for island
class OutdoorKitchenScreen extends ConsumerStatefulWidget {
  const OutdoorKitchenScreen({super.key});
  @override
  ConsumerState<OutdoorKitchenScreen> createState() => _OutdoorKitchenScreenState();
}

class _OutdoorKitchenScreenState extends ConsumerState<OutdoorKitchenScreen> {
  final _lengthController = TextEditingController(text: '8');
  final _widthController = TextEditingController(text: '3');
  final _heightController = TextEditingController(text: '36');

  String _blockType = 'standard';

  int? _blocksNeeded;
  int? _capsNeeded;
  double? _countertopSqFt;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 8;
    final width = double.tryParse(_widthController.text) ?? 3;
    final heightIn = double.tryParse(_heightController.text) ?? 36;

    // Perimeter
    final perimeter = (length + width) * 2;
    final perimeterIn = perimeter * 12;

    // Block dimensions
    double blockWidthIn;
    double blockHeightIn;
    switch (_blockType) {
      case 'standard': // 12" × 4"
        blockWidthIn = 12;
        blockHeightIn = 4;
        break;
      case 'large': // 18" × 6"
        blockWidthIn = 18;
        blockHeightIn = 6;
        break;
      default:
        blockWidthIn = 12;
        blockHeightIn = 4;
    }

    final blocksPerRow = (perimeterIn / blockWidthIn).ceil();
    final rows = (heightIn / blockHeightIn).ceil();
    final totalBlocks = blocksPerRow * rows;

    // Caps for top
    final caps = blocksPerRow;

    // Countertop area
    final countertopSqFt = length * width;

    setState(() {
      _blocksNeeded = totalBlocks;
      _capsNeeded = caps;
      _countertopSqFt = countertopSqFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '8'; _widthController.text = '3'; _heightController.text = '36'; setState(() { _blockType = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Outdoor Kitchen', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BLOCK TYPE', ['standard', 'large'], _blockType, {'standard': '12×4" Standard', 'large': '18×6" Large'}, (v) { setState(() => _blockType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Counter Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_blocksNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BLOCKS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_blocksNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap blocks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Countertop area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_countertopSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildKitchenGuide(colors),
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

  Widget _buildKitchenGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Counter height', '36" standard'),
        _buildTableRow(colors, 'Bar height', '42"'),
        _buildTableRow(colors, 'Counter depth', "24-30\""),
        _buildTableRow(colors, 'Grill cutout', "varies by model"),
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
