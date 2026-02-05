import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Kitchen Island Calculator - Island sizing and clearances
class KitchenIslandScreen extends ConsumerStatefulWidget {
  const KitchenIslandScreen({super.key});
  @override
  ConsumerState<KitchenIslandScreen> createState() => _KitchenIslandScreenState();
}

class _KitchenIslandScreenState extends ConsumerState<KitchenIslandScreen> {
  final _kitchenLengthController = TextEditingController(text: '15');
  final _kitchenWidthController = TextEditingController(text: '12');
  final _clearanceController = TextEditingController(text: '42');

  bool _hasSeating = true;
  bool _hasSink = false;

  double? _maxIslandLength;
  double? _maxIslandWidth;
  int? _seatCapacity;
  bool? _fitsIsland;

  @override
  void dispose() { _kitchenLengthController.dispose(); _kitchenWidthController.dispose(); _clearanceController.dispose(); super.dispose(); }

  void _calculate() {
    final kitchenLength = double.tryParse(_kitchenLengthController.text) ?? 0;
    final kitchenWidth = double.tryParse(_kitchenWidthController.text) ?? 0;
    final clearance = double.tryParse(_clearanceController.text) ?? 42;

    // Minimum clearance each side (in feet)
    final clearanceFt = clearance / 12;

    // Max island dimensions with clearance
    final maxIslandLength = kitchenLength - (clearanceFt * 2);
    final maxIslandWidth = kitchenWidth - (clearanceFt * 2);

    // Practical max (islands rarely exceed 10' x 4')
    final practicalLength = maxIslandLength > 10 ? 10.0 : (maxIslandLength > 4 ? maxIslandLength : 4.0);
    final practicalWidth = maxIslandWidth > 4 ? 4.0 : (maxIslandWidth > 2 ? maxIslandWidth : 2.0);

    // Seating: 24" per seat
    int seatCapacity = 0;
    if (_hasSeating) {
      seatCapacity = (practicalLength * 12 / 24).floor();
    }

    // Check if island fits
    final fitsIsland = maxIslandLength >= 4 && maxIslandWidth >= 2;

    setState(() { _maxIslandLength = practicalLength; _maxIslandWidth = practicalWidth; _seatCapacity = seatCapacity; _fitsIsland = fitsIsland; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _kitchenLengthController.text = '15'; _kitchenWidthController.text = '12'; _clearanceController.text = '42'; setState(() { _hasSeating = true; _hasSink = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Kitchen Island', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Kitchen Length', unit: 'feet', controller: _kitchenLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Kitchen Width', unit: 'feet', controller: _kitchenWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Aisle Clearance', unit: 'inches', controller: _clearanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Seating', _hasSeating, (v) { setState(() => _hasSeating = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Sink/Cooktop', _hasSink, (v) { setState(() => _hasSink = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_fitsIsland != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('ISLAND SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Text(_fitsIsland! ? '${_maxIslandLength!.toStringAsFixed(1)}\' x ${_maxIslandWidth!.toStringAsFixed(1)}\'' : 'NO FIT', style: TextStyle(color: _fitsIsland! ? colors.accentPrimary : colors.accentError, fontSize: 22, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_fitsIsland!) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Seat Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_seatCapacity seats', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Counter Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_maxIslandLength! * _maxIslandWidth!).toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _fitsIsland! ? colors.accentInfo.withValues(alpha: 0.1) : colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_fitsIsland! ? 'Min 42\" clearance for work aisles, 36\" for walkways. Add electrical for appliances.' : 'Kitchen too small for island. Need min 12\' x 10\' with 42\" clearance.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildClearanceTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
          child: Center(child: Text(value ? 'Yes' : 'No', style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    ]);
  }

  Widget _buildClearanceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLEARANCE GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Work aisle (1 cook)', '42\" min'),
        _buildTableRow(colors, 'Work aisle (2 cooks)', '48\" recommended'),
        _buildTableRow(colors, 'Walk-through only', '36\" min'),
        _buildTableRow(colors, 'Seating depth', '12-15\" overhang'),
        _buildTableRow(colors, 'Per seat width', '24\" min'),
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
