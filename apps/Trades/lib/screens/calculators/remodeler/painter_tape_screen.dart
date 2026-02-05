import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Painter's Tape Calculator - Masking tape estimation
class PainterTapeScreen extends ConsumerStatefulWidget {
  const PainterTapeScreen({super.key});
  @override
  ConsumerState<PainterTapeScreen> createState() => _PainterTapeScreenState();
}

class _PainterTapeScreenState extends ConsumerState<PainterTapeScreen> {
  final _perimeterController = TextEditingController(text: '50');
  final _doorsController = TextEditingController(text: '2');
  final _windowsController = TextEditingController(text: '3');

  String _type = 'blue';
  bool _ceilingLine = true;
  bool _baseboardLine = true;

  double? _totalFeet;
  int? _rolls60yd;
  int? _rolls180ft;

  @override
  void dispose() { _perimeterController.dispose(); _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;

    double totalFeet = 0;

    // Ceiling line
    if (_ceilingLine) {
      totalFeet += perimeter;
    }

    // Baseboard line
    if (_baseboardLine) {
      totalFeet += perimeter;
    }

    // Door frames: ~17 lf per door (2 sides + top, both sides)
    totalFeet += doors * 17;

    // Window frames: ~12 lf per window (all sides)
    totalFeet += windows * 12;

    // Add 10% for waste and corners
    totalFeet *= 1.10;

    // Rolls: 60 yd = 180 ft
    final rolls60yd = (totalFeet / 180).ceil();
    final rolls180ft = rolls60yd;

    setState(() { _totalFeet = totalFeet; _rolls60yd = rolls60yd; _rolls180ft = rolls180ft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '50'; _doorsController.text = '2'; _windowsController.text = '3'; setState(() { _type = 'blue'; _ceilingLine = true; _baseboardLine = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Painter\'s Tape', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Ceiling', _ceilingLine, (v) { setState(() => _ceilingLine = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Baseboard', _baseboardLine, (v) { setState(() => _baseboardLine = v); _calculate(); })),
            ]),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TAPE NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('60 yd Rolls (180\')', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rolls60yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTapeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTapeTip() {
    switch (_type) {
      case 'blue':
        return 'Blue tape: 14-day clean removal. Best for walls, trim. Press edges firmly.';
      case 'green':
        return 'Green tape: 8-day removal, higher adhesion. Better for textured surfaces.';
      case 'delicate':
        return 'Delicate surface tape: Won\'t damage fresh paint, wallpaper. Remove within 24 hrs.';
      case 'yellow':
        return 'Yellow tape: 60-day removal. Best for long projects, outdoor. UV resistant.';
      default:
        return 'Remove tape at 45 angle while paint is still slightly tacky for cleanest edge.';
    }
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['blue', 'green', 'delicate', 'yellow'];
    final labels = {'blue': 'Blue (14 day)', 'green': 'Green (8 day)', 'delicate': 'Delicate', 'yellow': 'Yellow (60 day)'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
        final isSelected = _type == o;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Center(child: Text(label, style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TAPE WIDTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '0.94\" (1\")', 'Standard, trim'),
        _buildTableRow(colors, '1.41\" (1.5\")', 'Wide trim, glass'),
        _buildTableRow(colors, '1.88\" (2\")', 'Baseboards, wide trim'),
        _buildTableRow(colors, '2.83\" (3\")', 'Plastic sheeting'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
