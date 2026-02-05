import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Raised Bed Calculator - Soil volume and lumber
class RaisedBedScreen extends ConsumerStatefulWidget {
  const RaisedBedScreen({super.key});
  @override
  ConsumerState<RaisedBedScreen> createState() => _RaisedBedScreenState();
}

class _RaisedBedScreenState extends ConsumerState<RaisedBedScreen> {
  final _lengthController = TextEditingController(text: '8');
  final _widthController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '12');

  String _material = '2x12';

  double? _soilCuYd;
  double? _soilCuFt;
  int? _boards;
  int? _screws;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 8;
    final width = double.tryParse(_widthController.text) ?? 4;
    final heightIn = double.tryParse(_heightController.text) ?? 12;

    // Soil volume
    final heightFt = heightIn / 12;
    final soilCuFt = length * width * heightFt;
    final soilCuYd = soilCuFt / 27;

    // Lumber calculation
    double boardHeightIn;
    switch (_material) {
      case '2x6': boardHeightIn = 5.5; break;
      case '2x8': boardHeightIn = 7.25; break;
      case '2x10': boardHeightIn = 9.25; break;
      case '2x12': boardHeightIn = 11.25; break;
      default: boardHeightIn = 11.25;
    }

    // Rows of boards needed
    final rowsNeeded = (heightIn / boardHeightIn).ceil();

    // Boards: 2 long sides + 2 short sides per row
    // Assuming 8' boards, calculate how many needed
    final longSideBoards = (length / 8).ceil() * 2 * rowsNeeded;
    final shortSideBoards = 2 * rowsNeeded; // Usually fits in one board
    final totalBoards = longSideBoards + shortSideBoards;

    // Corner screws: 4 corners × 3 screws per corner × rows
    final screws = 4 * 3 * rowsNeeded;

    setState(() {
      _soilCuYd = soilCuYd;
      _soilCuFt = soilCuFt;
      _boards = totalBoards;
      _screws = screws;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '8'; _widthController.text = '4'; _heightController.text = '12'; setState(() { _material = '2x12'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Raised Bed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BOARD SIZE', ['2x6', '2x8', '2x10', '2x12'], _material, {'2x6': '2×6', '2x8': '2×8', '2x10': '2×10', '2x12': '2×12'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'in', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_soilCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SOIL NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cubic feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuFt!.toStringAsFixed(1)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bags (2 cu ft)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_soilCuFt! / 2).ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("$_material × 8' boards", style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boards', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('3" deck screws', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_screws', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSoilMix(colors),
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

  Widget _buildSoilMix(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SOIL MIX RECIPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Topsoil', '40%'),
        _buildTableRow(colors, 'Compost', '40%'),
        _buildTableRow(colors, 'Perlite/vermiculite', '20%'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'Ideal depth', '10-12"'),
        _buildTableRow(colors, 'Cedar/redwood', 'Rot resistant'),
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
