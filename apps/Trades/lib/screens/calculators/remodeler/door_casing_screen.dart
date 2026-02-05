import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Door Casing Calculator - Door trim estimation
class DoorCasingScreen extends ConsumerStatefulWidget {
  const DoorCasingScreen({super.key});
  @override
  ConsumerState<DoorCasingScreen> createState() => _DoorCasingScreenState();
}

class _DoorCasingScreenState extends ConsumerState<DoorCasingScreen> {
  final _doorsController = TextEditingController(text: '8');
  final _heightController = TextEditingController(text: '80');
  final _widthController = TextEditingController(text: '32');

  bool _bothSides = true;

  double? _linearFeetPerDoor;
  double? _totalLinearFeet;
  int? _pieces7ft;

  @override
  void dispose() { _doorsController.dispose(); _heightController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 80;
    final width = double.tryParse(_widthController.text) ?? 32;

    // Linear feet per door side: 2 legs + 1 head
    // Convert inches to feet
    final heightFt = height / 12;
    final widthFt = width / 12;
    final lfPerSide = (heightFt * 2) + widthFt + 0.5; // Add for corners

    final sidesPerDoor = _bothSides ? 2 : 1;
    final linearFeetPerDoor = lfPerSide * sidesPerDoor;

    // Total with 10% waste
    final totalLinearFeet = (linearFeetPerDoor * doors) * 1.10;

    // 7' pieces (standard casing length)
    final pieces7ft = (totalLinearFeet / 7).ceil();

    setState(() { _linearFeetPerDoor = linearFeetPerDoor; _totalLinearFeet = totalLinearFeet; _pieces7ft = pieces7ft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _doorsController.text = '8'; _heightController.text = '80'; _widthController.text = '32'; setState(() => _bothSides = true); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Door Casing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Number of Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Door Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Trim Both Sides', _bothSides, (v) { setState(() => _bothSides = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_totalLinearFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL CASING', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLinearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per Door', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeetPerDoor!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('7\' Pieces (+10%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces7ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Match baseboard profile. Use 45° miters at corners. Reveal 1/4\" on jamb.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, size: 20, color: value ? colors.accentPrimary : colors.textTertiary),
        ]),
      ),
    );
  }

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CASING WIDTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Modern/minimal', '2.25-2.5\"'),
        _buildTableRow(colors, 'Colonial/standard', '2.5-3.5\"'),
        _buildTableRow(colors, 'Craftsman', '3.5-4.5\"'),
        _buildTableRow(colors, 'Traditional', '4-5\"'),
        _buildTableRow(colors, 'Victorian', '5-6\"+'),
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
