import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Outlet Relocation Calculator - Electrical outlet move estimation
class OutletRelocationScreen extends ConsumerStatefulWidget {
  const OutletRelocationScreen({super.key});
  @override
  ConsumerState<OutletRelocationScreen> createState() => _OutletRelocationScreenState();
}

class _OutletRelocationScreenState extends ConsumerState<OutletRelocationScreen> {
  final _outletsController = TextEditingController(text: '4');
  final _distanceController = TextEditingController(text: '6');

  String _type = 'standard';
  bool _newCircuit = false;

  double? _wireFeet;
  int? _boxes;
  int? _coverPlates;
  int? _wireNuts;

  @override
  void dispose() { _outletsController.dispose(); _distanceController.dispose(); super.dispose(); }

  void _calculate() {
    final outlets = int.tryParse(_outletsController.text) ?? 0;
    final distance = double.tryParse(_distanceController.text) ?? 6;

    // Wire per outlet: distance + 2' extra for box connections
    final wirePerOutlet = distance + 2;
    final wireFeet = wirePerOutlet * outlets;

    // Boxes: 1 per outlet (old-work boxes for remodel)
    final boxes = outlets;

    // Cover plates
    final coverPlates = outlets;

    // Wire nuts: ~4 per outlet connection
    final wireNuts = outlets * 4;

    setState(() { _wireFeet = wireFeet; _boxes = boxes; _coverPlates = coverPlates; _wireNuts = wireNuts; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _outletsController.text = '4'; _distanceController.text = '6'; setState(() { _type = 'standard'; _newCircuit = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Outlet Relocation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Outlets to Move', unit: 'qty', controller: _outletsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Avg Distance', unit: 'feet', controller: _distanceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            _buildToggle(colors, 'New Circuit Required', _newCircuit, (v) { setState(() => _newCircuit = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_wireFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WIRE NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wireFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Old-Work Boxes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boxes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cover Plates', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_coverPlates', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wire Nuts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_wireNuts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_newCircuit) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('New Breaker', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Always turn off breaker before work. Use 12/2 for 20A, 14/2 for 15A circuits.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWireTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['standard', 'gfci', 'usb', '240v'];
    final labels = {'standard': 'Standard', 'gfci': 'GFCI', 'usb': 'USB', '240v': '240V'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('OUTLET TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
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

  Widget _buildWireTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WIRE GAUGE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '14 AWG', '15A circuits'),
        _buildTableRow(colors, '12 AWG', '20A circuits'),
        _buildTableRow(colors, '10 AWG', '30A circuits'),
        _buildTableRow(colors, '8 AWG', '40A circuits'),
        _buildTableRow(colors, '6 AWG', '50A circuits'),
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
