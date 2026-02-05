import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Screen Door Calculator - Screen door materials estimation
class ScreenDoorScreen extends ConsumerStatefulWidget {
  const ScreenDoorScreen({super.key});
  @override
  ConsumerState<ScreenDoorScreen> createState() => _ScreenDoorScreenState();
}

class _ScreenDoorScreenState extends ConsumerState<ScreenDoorScreen> {
  final _countController = TextEditingController(text: '2');
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '80');

  String _doorType = 'hinged';
  String _screenType = 'fiberglass';

  double? _screenSqft;
  double? _splineFeet;
  int? _hinges;
  int? _closers;

  @override
  void dispose() { _countController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final count = int.tryParse(_countController.text) ?? 2;
    final width = double.tryParse(_widthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 80;

    final widthFt = width / 12;
    final heightFt = height / 12;

    // Screen area per door (screen portion ~75% of door)
    final screenPerDoor = widthFt * heightFt * 0.75;
    final screenSqft = screenPerDoor * count * 1.15; // +15% waste

    // Spline per door
    final splinePerDoor = (widthFt + heightFt) * 2;
    final splineFeet = splinePerDoor * count * 1.10;

    // Hardware
    int hinges;
    int closers;
    switch (_doorType) {
      case 'hinged':
        hinges = count * 3; // 3 hinges per door
        closers = count; // 1 closer per door
        break;
      case 'sliding':
        hinges = 0;
        closers = 0;
        break;
      case 'retractable':
        hinges = 0;
        closers = 0;
        break;
      default:
        hinges = count * 3;
        closers = count;
    }

    setState(() { _screenSqft = screenSqft; _splineFeet = splineFeet; _hinges = hinges; _closers = closers; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _countController.text = '2'; _widthController.text = '36'; _heightController.text = '80'; setState(() { _doorType = 'hinged'; _screenType = 'fiberglass'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Screen Door', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'DOOR TYPE', ['hinged', 'sliding', 'retractable'], _doorType, {'hinged': 'Hinged', 'sliding': 'Sliding', 'retractable': 'Retractable'}, (v) { setState(() => _doorType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SCREEN', ['fiberglass', 'aluminum', 'pet'], _screenType, {'fiberglass': 'Fiberglass', 'aluminum': 'Aluminum', 'pet': 'Pet-Resist'}, (v) { setState(() => _screenType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Doors', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_screenSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SCREEN MATERIAL', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_screenSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spline', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_splineFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_doorType == 'hinged') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinges', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hinges', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Closers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_closers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getDoorTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  String _getDoorTip() {
    switch (_doorType) {
      case 'hinged':
        return 'Standard hinged: install closer on interior. Use 3 hinges for 80\"+ doors. Spring hinges optional.';
      case 'sliding':
        return 'Sliding: requires track top and bottom. Check roller condition. Clean tracks regularly.';
      case 'retractable':
        return 'Retractable: mounts in door frame. Disappears when not in use. More expensive but sleek.';
      default:
        return 'Measure opening carefully. Screen doors typically 1/8\" smaller than opening.';
    }
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '30\" x 80\"', 'Narrow'),
        _buildTableRow(colors, '32\" x 80\"', 'Standard'),
        _buildTableRow(colors, '36\" x 80\"', 'Common'),
        _buildTableRow(colors, '36\" x 84\"', 'Tall'),
        _buildTableRow(colors, 'Custom', 'Measure opening'),
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
