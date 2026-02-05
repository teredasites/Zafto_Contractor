import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cabinet Hardware Calculator - Knobs and pulls estimation
class CabinetHardwareScreen extends ConsumerStatefulWidget {
  const CabinetHardwareScreen({super.key});
  @override
  ConsumerState<CabinetHardwareScreen> createState() => _CabinetHardwareScreenState();
}

class _CabinetHardwareScreenState extends ConsumerState<CabinetHardwareScreen> {
  final _doorsController = TextEditingController(text: '20');
  final _drawersController = TextEditingController(text: '12');

  String _doorStyle = 'single';
  String _drawerStyle = 'single';

  int? _doorHardware;
  int? _drawerHardware;
  int? _totalPieces;
  int? _hinges;

  @override
  void dispose() { _doorsController.dispose(); _drawersController.dispose(); super.dispose(); }

  void _calculate() {
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final drawers = int.tryParse(_drawersController.text) ?? 0;

    // Door hardware: 1 knob/pull per door, or 2 for double
    int doorMultiplier;
    switch (_doorStyle) {
      case 'single':
        doorMultiplier = 1;
        break;
      case 'double':
        doorMultiplier = 2;
        break;
      case 'none':
        doorMultiplier = 0;
        break;
      default:
        doorMultiplier = 1;
    }

    // Drawer hardware: 1 or 2 pulls
    int drawerMultiplier;
    switch (_drawerStyle) {
      case 'single':
        drawerMultiplier = 1;
        break;
      case 'double':
        drawerMultiplier = 2;
        break;
      default:
        drawerMultiplier = 1;
    }

    final doorHardware = doors * doorMultiplier;
    final drawerHardware = drawers * drawerMultiplier;
    final totalPieces = doorHardware + drawerHardware;

    // Hinges: 2 per door (soft-close)
    final hinges = doors * 2;

    setState(() { _doorHardware = doorHardware; _drawerHardware = drawerHardware; _totalPieces = totalPieces; _hinges = hinges; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _doorsController.text = '20'; _drawersController.text = '12'; setState(() { _doorStyle = 'single'; _drawerStyle = 'single'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Cabinet Hardware', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'DOOR STYLE', ['single', 'double', 'none'], _doorStyle, {'single': '1 Per Door', 'double': '2 Per Door', 'none': 'Push Open'}, (v) { setState(() => _doorStyle = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'DRAWER STYLE', ['single', 'double'], _drawerStyle, {'single': '1 Per Drawer', 'double': '2 Per Drawer'}, (v) { setState(() => _drawerStyle = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Cabinet Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Drawers', unit: 'qty', controller: _drawersController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalPieces != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL HARDWARE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalPieces pcs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Door Knobs/Pulls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_doorHardware', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drawer Pulls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_drawerHardware', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinges (if replacing)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hinges', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard pull centers: 3\", 3-3/4\", 4\", 5\", 6\". Knobs use single screw.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlacementTable(colors),
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

  Widget _buildPlacementTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLACEMENT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Upper door knob', '2-3\" from bottom'),
        _buildTableRow(colors, 'Lower door knob', '2-3\" from top'),
        _buildTableRow(colors, 'Drawer pull', 'Centered, 1/3 up'),
        _buildTableRow(colors, 'Wide drawer', '2 pulls, 1/4 from edge'),
        _buildTableRow(colors, 'From edge', '2-3\" typically'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
