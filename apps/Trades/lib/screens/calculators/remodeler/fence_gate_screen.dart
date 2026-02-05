import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fence Gate Calculator - Gate materials estimation
class FenceGateScreen extends ConsumerStatefulWidget {
  const FenceGateScreen({super.key});
  @override
  ConsumerState<FenceGateScreen> createState() => _FenceGateScreenState();
}

class _FenceGateScreenState extends ConsumerState<FenceGateScreen> {
  final _widthController = TextEditingController(text: '42');
  final _heightController = TextEditingController(text: '72');
  final _countController = TextEditingController(text: '1');

  String _style = 'single';
  String _material = 'wood';

  int? _hinges;
  int? _latches;
  double? _frameFeet;
  int? _pickets;
  int? _wheelKits;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 42;
    final height = double.tryParse(_heightController.text) ?? 72;
    final count = int.tryParse(_countController.text) ?? 1;

    final widthFt = width / 12;
    final heightFt = height / 12;

    // Hinges: 2 for gates up to 4', 3 for taller/wider
    int hingesPerGate;
    if (height > 72 || width > 48) {
      hingesPerGate = 3;
    } else {
      hingesPerGate = 2;
    }

    // Double gates count as 2
    int gateCount;
    int latches;
    int wheelKits;
    switch (_style) {
      case 'single':
        gateCount = count;
        latches = count;
        wheelKits = 0;
        break;
      case 'double':
        gateCount = count * 2;
        latches = count * 2; // latch + drop rod
        wheelKits = count; // for large gates
        break;
      case 'sliding':
        gateCount = count;
        latches = count;
        wheelKits = count;
        break;
      default:
        gateCount = count;
        latches = count;
        wheelKits = 0;
    }

    final hinges = gateCount * hingesPerGate;

    // Frame: perimeter + diagonal brace
    final perimeterPerGate = (widthFt + heightFt) * 2;
    final diagonal = (widthFt * widthFt + heightFt * heightFt);
    final diagonalLength = diagonal > 0 ? (diagonal * 0.5) + 1 : 0; // approximate
    final frameFeet = (perimeterPerGate + diagonalLength.toDouble()) * gateCount;

    // Pickets for infill
    final picketWidth = 3.5;
    final picketsPerGate = (width / picketWidth).ceil();
    final pickets = picketsPerGate * gateCount;

    setState(() { _hinges = hinges; _latches = latches; _frameFeet = frameFeet; _pickets = pickets; _wheelKits = wheelKits; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '42'; _heightController.text = '72'; _countController.text = '1'; setState(() { _style = 'single'; _material = 'wood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fence Gate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'GATE STYLE', ['single', 'double', 'sliding'], _style, {'single': 'Single Swing', 'double': 'Double', 'sliding': 'Sliding'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['wood', 'vinyl', 'metal', 'chain_link'], _material, {'wood': 'Wood', 'vinyl': 'Vinyl', 'metal': 'Metal', 'chain_link': 'Chain Link'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Gates', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_hinges != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('HINGES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hinges', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Latches', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_latches', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Frame (2x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_frameFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pickets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pickets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_wheelKits! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wheel Kits', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_wheelKits', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use diagonal brace from bottom hinge corner to top latch corner. Gate post should be 4x4 minimum, 6x6 for large gates.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD GATE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Walk gate', '36-42\" wide'),
        _buildTableRow(colors, 'Garden gate', '48\" wide'),
        _buildTableRow(colors, 'Double drive', '10-12\' wide'),
        _buildTableRow(colors, 'RV gate', '14-16\' wide'),
        _buildTableRow(colors, 'Clearance', '1/2\" each side'),
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
