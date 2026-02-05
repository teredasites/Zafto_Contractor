import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Egress Path Calculator - Exit path requirements
class EgressPathScreen extends ConsumerStatefulWidget {
  const EgressPathScreen({super.key});
  @override
  ConsumerState<EgressPathScreen> createState() => _EgressPathScreenState();
}

class _EgressPathScreenState extends ConsumerState<EgressPathScreen> {
  final _occupantLoadController = TextEditingController(text: '50');
  final _corridorWidthController = TextEditingController(text: '44');
  final _travelDistController = TextEditingController(text: '150');

  bool _sprinklered = true;

  bool? _corridorOk;
  bool? _exitWidthOk;
  bool? _travelDistOk;
  int? _exitsRequired;

  @override
  void dispose() { _occupantLoadController.dispose(); _corridorWidthController.dispose(); _travelDistController.dispose(); super.dispose(); }

  void _calculate() {
    final occupantLoad = int.tryParse(_occupantLoadController.text) ?? 0;
    final corridorWidth = double.tryParse(_corridorWidthController.text) ?? 0;
    final travelDist = double.tryParse(_travelDistController.text) ?? 0;

    // IBC requirements

    // Corridor width: 44" min (36" for <50 occupants)
    final minCorridorWidth = occupantLoad < 50 ? 36.0 : 44.0;
    final corridorOk = corridorWidth >= minCorridorWidth;

    // Required exit width: 0.2" per occupant (stair), 0.15" per occupant (other)
    final requiredWidth = occupantLoad * 0.2;
    final exitWidthOk = corridorWidth >= requiredWidth;

    // Travel distance limits
    double maxTravel;
    if (_sprinklered) {
      maxTravel = 250; // With sprinklers
    } else {
      maxTravel = 200; // Without sprinklers
    }
    final travelDistOk = travelDist <= maxTravel;

    // Number of exits required
    int exitsRequired;
    if (occupantLoad <= 49) {
      exitsRequired = 1;
    } else if (occupantLoad <= 500) {
      exitsRequired = 2;
    } else if (occupantLoad <= 1000) {
      exitsRequired = 3;
    } else {
      exitsRequired = 4;
    }

    setState(() { _corridorOk = corridorOk; _exitWidthOk = exitWidthOk; _travelDistOk = travelDistOk; _exitsRequired = exitsRequired; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _occupantLoadController.text = '50'; _corridorWidthController.text = '44'; _travelDistController.text = '150'; setState(() => _sprinklered = true); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final allPass = (_corridorOk ?? false) && (_exitWidthOk ?? false) && (_travelDistOk ?? false);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Egress Path', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Occupant Load', unit: 'persons', controller: _occupantLoadController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Sprinklered', _sprinklered, (v) { setState(() => _sprinklered = v); _calculate(); })),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Corridor Width', unit: 'inches', controller: _corridorWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Travel Distance', unit: 'feet', controller: _travelDistController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_exitsRequired != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('EGRESS CHECK', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Text(allPass ? 'COMPLIANT' : 'CHECK ITEMS', style: TextStyle(color: allPass ? colors.accentSuccess : colors.accentWarning, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildCheckRow(colors, 'Exits Required', '$_exitsRequired', true),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Corridor Width', _corridorOk! ? 'OK' : 'Too Narrow', _corridorOk!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Exit Capacity', _exitWidthOk! ? 'OK' : 'Insufficient', _exitWidthOk!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Travel Distance', _travelDistOk! ? 'OK' : 'Exceeds Limit', _travelDistOk!),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Max travel: ${_sprinklered ? '250ft' : '200ft'}. Exits must be separated by 1/2 diagonal distance.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildExitTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCheckRow(ZaftoColors colors, String label, String value, bool passes) {
    return Row(children: [
      Icon(passes ? LucideIcons.checkCircle : LucideIcons.xCircle, color: passes ? colors.accentSuccess : colors.accentError, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      Text(value, style: TextStyle(color: passes ? colors.textPrimary : colors.accentError, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
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

  Widget _buildExitTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IBC EXIT REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1-49 occupants', '1 exit'),
        _buildTableRow(colors, '50-500 occupants', '2 exits'),
        _buildTableRow(colors, '501-1000 occupants', '3 exits'),
        _buildTableRow(colors, '1000+ occupants', '4 exits'),
        _buildTableRow(colors, 'Door width min', '32" clear'),
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
