import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Storm Door Calculator - Storm door installation estimation
class StormDoorScreen extends ConsumerStatefulWidget {
  const StormDoorScreen({super.key});
  @override
  ConsumerState<StormDoorScreen> createState() => _StormDoorScreenState();
}

class _StormDoorScreenState extends ConsumerState<StormDoorScreen> {
  final _countController = TextEditingController(text: '1');
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '80');

  String _style = 'fullview';
  String _frame = 'aluminum';

  int? _hinges;
  int? _closers;
  double? _weatherstrip;
  double? _caulk;

  @override
  void dispose() { _countController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final count = int.tryParse(_countController.text) ?? 1;
    final width = double.tryParse(_widthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 80;

    // Hardware per door
    final hinges = count * 3; // 3 hinges per door

    // Closers: fullview typically has 2 (top and bottom)
    int closersPerDoor;
    switch (_style) {
      case 'fullview':
        closersPerDoor = 2;
        break;
      case 'midview':
        closersPerDoor = 1;
        break;
      case 'ventilating':
        closersPerDoor = 2;
        break;
      default:
        closersPerDoor = 1;
    }
    final closers = count * closersPerDoor;

    // Weatherstrip: perimeter of door
    final perimeterInches = (width + height) * 2;
    final weatherstrip = (perimeterInches / 12) * count;

    // Caulk: around frame exterior
    final caulk = ((width + height) * 2 / 12) * count * 0.5; // half tube per door

    setState(() { _hinges = hinges; _closers = closers; _weatherstrip = weatherstrip; _caulk = caulk; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _countController.text = '1'; _widthController.text = '36'; _heightController.text = '80'; setState(() { _style = 'fullview'; _frame = 'aluminum'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Storm Door', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['fullview', 'midview', 'ventilating'], _style, {'fullview': 'Full View', 'midview': 'Mid View', 'ventilating': 'Ventilating'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FRAME', ['aluminum', 'wood', 'vinyl'], _frame, {'aluminum': 'Aluminum', 'wood': 'Wood Core', 'vinyl': 'Vinyl'}, (v) { setState(() => _frame = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Doors', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('HARDWARE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hinges hinges', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Door Closers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_closers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weatherstrip', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weatherstrip!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Caulk', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_caulk!.toStringAsFixed(1)} tubes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getStyleTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  String _getStyleTip() {
    switch (_style) {
      case 'fullview':
        return 'Full view: maximum light, interchangeable glass/screen panels. Ideal for entries.';
      case 'midview':
        return 'Mid view: glass top, solid bottom. Better privacy and pet-friendly.';
      case 'ventilating':
        return 'Ventilating: screen rolls up/down. Best of both worlds. Self-storing glass.';
      default:
        return 'Measure brick-to-brick width and height. Most storm doors adjustable 1-2\".';
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
        _buildTableRow(colors, '32\" x 80\"', 'Standard'),
        _buildTableRow(colors, '36\" x 80\"', 'Common entry'),
        _buildTableRow(colors, '32\" x 81\"', 'Tall standard'),
        _buildTableRow(colors, '36\" x 84\"', 'Extra tall'),
        _buildTableRow(colors, 'Hinge side', 'Match entry door'),
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
